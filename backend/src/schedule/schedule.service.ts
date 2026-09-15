import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { DateTime } from 'luxon';
import { ScheduledOrder, ScheduledOrderDocument } from '../schemas/scheduled-order.schema';
import { User, UserDocument } from '../schemas/user.schema';
import { Subscription, SubscriptionDocument } from '../schemas/subscription.schema';
import { MealCatalog, MealCatalogDocument } from '../schemas/meal-catalog.schema';
import { CutoffService } from '../cutoff/cutoff.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { MealCatalogService } from '../meal-catalog/meal-catalog.service';
import { OrderStatus } from '../common/enums/order-status.enum';
import { MealSlot } from '../common/enums/meal-slot.enum';
import { ApiException } from '../common/exceptions/api.exception';
import { ErrorCode } from '../common/enums/error-code.enum';

export interface ScheduleResponse {
  user: {
    id: string;
    name: string;
    timezone: string;
  };
  subscription: {
    id: string;
    name: string;
    status: string;
    cutoffTime: {
      hour: number;
      minute: number;
    };
  };
  cutoffConfig: {
    hour: number;
    minute: number;
    timezone: string;
  };
  orders: any[];
}

@Injectable()
export class ScheduleService {
  private readonly logger = new Logger(ScheduleService.name);

  constructor(
    @InjectModel(ScheduledOrder.name)
    private readonly orderModel: Model<ScheduledOrderDocument>,
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
    @InjectModel(Subscription.name)
    private readonly subscriptionModel: Model<SubscriptionDocument>,
    private readonly cutoffService: CutoffService,
    private readonly subscriptionService: SubscriptionService,
    private readonly mealCatalogService: MealCatalogService,
  ) {}

  /**
   * Loads the user or throws 404
   */
  private async getUserOrThrow(userId: string | Types.ObjectId): Promise<UserDocument> {
    if (!Types.ObjectId.isValid(userId)) {
      throw new ApiException(ErrorCode.UNAUTHORIZED_ORDER, 'Invalid user identifier.');
    }
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new ApiException(ErrorCode.UNAUTHORIZED_ORDER, 'User not found.');
    }
    return user;
  }

  /**
   * Helper to fetch an order, verifying ownership
   */
  private async getOrderAndValidateOwnership(
    orderId: string,
    userId: string,
  ): Promise<ScheduledOrderDocument> {
    if (!Types.ObjectId.isValid(orderId)) {
      throw new ApiException(ErrorCode.ORDER_NOT_FOUND, 'Invalid order ID format.');
    }
    const order = await this.orderModel.findById(orderId).populate('mealId').exec();
    if (!order) {
      throw new ApiException(ErrorCode.ORDER_NOT_FOUND, `Order ${orderId} not found.`);
    }
    if (order.userId.toString() !== userId.toString()) {
      throw new ApiException(
        ErrorCode.UNAUTHORIZED_ORDER,
        'You do not have permission to modify this order.',
        403,
      );
    }
    return order;
  }

  /**
   * Get Schedule for user between startDate and endDate
   */
  async getSchedule(
    userId: string,
    startDate?: string,
    endDate?: string,
  ): Promise<ScheduleResponse> {
    const user = await this.getUserOrThrow(userId);
    const subscription = await this.subscriptionService.getSubscriptionForUser(userId);

    const userTz = user.timezone || 'Asia/Kolkata';
    const nowLocal = DateTime.now().setZone(userTz);

    // Default window: from today - 2 days to today + 14 days
    const defaultStart = startDate || nowLocal.minus({ days: 2 }).toISODate()!;
    const defaultEnd = endDate || nowLocal.plus({ days: 14 }).toISODate()!;

    const query: any = {
      userId: new Types.ObjectId(userId),
      deliveryDate: { $gte: defaultStart, $lte: defaultEnd },
    };

    const orders = await this.orderModel
      .find(query)
      .populate('mealId')
      .sort({ deliveryDate: 1, slot: 1 })
      .exec();

    // Attach computed cutoff details dynamically
    const enrichedOrders = orders.map((order) => {
      const cutoffInfo = this.cutoffService.getCutoffDetails(
        order.deliveryDate,
        user.timezone,
        subscription.cutoffTime.hour,
        subscription.cutoffTime.minute,
      );

      const orderObj = order.toObject();
      return {
        ...orderObj,
        id: order._id.toString(),
        cutoffAtUtc: cutoffInfo.cutoffAtUtc,
        isCutoffPassed: cutoffInfo.isPassed,
        remainingCutoffMs: cutoffInfo.remainingMs,
      };
    });

    return {
      user: {
        id: user._id.toString(),
        name: user.name,
        timezone: user.timezone,
      },
      subscription: {
        id: subscription._id.toString(),
        name: subscription.name,
        status: subscription.status,
        cutoffTime: {
          hour: subscription.cutoffTime.hour,
          minute: subscription.cutoffTime.minute,
        },
      },
      cutoffConfig: {
        hour: subscription.cutoffTime.hour,
        minute: subscription.cutoffTime.minute,
        timezone: user.timezone,
      },
      orders: enrichedOrders,
    };
  }

  /**
   * Skip Order Mutation
   */
  async skipOrder(userId: string, orderId: string): Promise<any> {
    const user = await this.getUserOrThrow(userId);
    const sub = await this.subscriptionService.validateSubscriptionActive(userId);
    const order = await this.getOrderAndValidateOwnership(orderId, userId);

    if (order.status === OrderStatus.SKIPPED) {
      throw new ApiException(
        ErrorCode.ALREADY_SKIPPED,
        'This meal order is already skipped.',
      );
    }

    // Cutoff validation
    const cutoffAtUtc = this.cutoffService.validateCutoffOrThrow(
      order.deliveryDate,
      user.timezone,
      sub.cutoffTime.hour,
      sub.cutoffTime.minute,
    );

    // Save previous status for Undo
    order.previousStatus = order.status;
    order.status = OrderStatus.SKIPPED;
    order.cutoffAtUtc = cutoffAtUtc;
    order.version = (order.version || 1) + 1;

    await order.save();
    return this.getEnrichedOrder(order, user, sub);
  }

  /**
   * Swap Meal Mutation
   */
  async swapMeal(userId: string, orderId: string, newMealId: string): Promise<any> {
    const user = await this.getUserOrThrow(userId);
    const sub = await this.subscriptionService.validateSubscriptionActive(userId);
    const order = await this.getOrderAndValidateOwnership(orderId, userId);

    // Validate cutoff
    const cutoffAtUtc = this.cutoffService.validateCutoffOrThrow(
      order.deliveryDate,
      user.timezone,
      sub.cutoffTime.hour,
      sub.cutoffTime.minute,
    );

    // Validate target meal exists and is available
    const newMeal = await this.mealCatalogService.validateMealAvailable(newMealId);

    const currentMealIdStr = (order.mealId as any)?._id?.toString() || order.mealId?.toString();
    if (currentMealIdStr === newMealId.toString()) {
      throw new ApiException(
        ErrorCode.SAME_MEAL_SELECTED,
        'The selected meal is already assigned to this slot.',
      );
    }

    // Preserve previous state for Undo
    order.previousMealId = new Types.ObjectId(currentMealIdStr);
    order.previousStatus = order.status;

    order.mealId = newMeal._id;
    order.status = OrderStatus.SWAPPED;
    order.cutoffAtUtc = cutoffAtUtc;
    order.version = (order.version || 1) + 1;

    await order.save();
    return this.getEnrichedOrder(order, user, sub);
  }

  /**
   * Move Order to targetDate and targetSlot
   */
  async moveOrder(
    userId: string,
    orderId: string,
    targetDate: string,
    targetSlot: MealSlot,
  ): Promise<any> {
    const user = await this.getUserOrThrow(userId);
    const sub = await this.subscriptionService.validateSubscriptionActive(userId);
    const order = await this.getOrderAndValidateOwnership(orderId, userId);

    // Validate source cutoff
    this.cutoffService.validateCutoffOrThrow(
      order.deliveryDate,
      user.timezone,
      sub.cutoffTime.hour,
      sub.cutoffTime.minute,
    );

    // Validate destination cutoff (cannot move into a slot whose cutoff already passed)
    const destinationCutoffUtc = this.cutoffService.validateCutoffOrThrow(
      targetDate,
      user.timezone,
      sub.cutoffTime.hour,
      sub.cutoffTime.minute,
    );

    if (order.deliveryDate === targetDate && order.slot === targetSlot) {
      throw new ApiException(
        ErrorCode.SAME_DESTINATION_SELECTED,
        'The meal is already scheduled for this date and time slot.',
      );
    }

    // Check conflict at destination: another order should not exist for same user + date + slot
    const existingConflict = await this.orderModel.findOne({
      _id: { $ne: order._id },
      userId: new Types.ObjectId(userId),
      deliveryDate: targetDate,
      slot: targetSlot,
      status: { $ne: OrderStatus.SKIPPED },
    }).exec();

    if (existingConflict) {
      throw new ApiException(
        ErrorCode.DESTINATION_CONFLICT,
        `There is already an active meal scheduled for ${targetDate} during the ${targetSlot} slot. Please choose an open slot or swap instead.`,
      );
    }

    // Save previous state for Undo
    order.previousDate = order.deliveryDate;
    order.previousSlot = order.slot;
    order.previousStatus = order.status;

    order.deliveryDate = targetDate;
    order.slot = targetSlot;
    order.status = OrderStatus.MOVED;
    order.cutoffAtUtc = destinationCutoffUtc;
    order.version = (order.version || 1) + 1;

    await order.save();
    return this.getEnrichedOrder(order, user, sub);
  }

  /**
   * Reschedule Order (preserves current slot, changes deliveryDate)
   */
  async rescheduleOrder(userId: string, orderId: string, targetDate: string): Promise<any> {
    const user = await this.getUserOrThrow(userId);
    const sub = await this.subscriptionService.validateSubscriptionActive(userId);
    const order = await this.getOrderAndValidateOwnership(orderId, userId);

    // Move to targetDate keeping current slot
    const result = await this.moveOrder(userId, orderId, targetDate, order.slot);
    // Mark status as RESCHEDULED explicitly
    await this.orderModel.updateOne(
      { _id: order._id },
      { $set: { status: OrderStatus.RESCHEDULED } },
    );
    result.status = OrderStatus.RESCHEDULED;
    return result;
  }

  /**
   * Undo the last mutation on the order
   */
  async undoOrder(userId: string, orderId: string): Promise<any> {
    const user = await this.getUserOrThrow(userId);
    const sub = await this.subscriptionService.validateSubscriptionActive(userId);
    const order = await this.getOrderAndValidateOwnership(orderId, userId);

    const hasPreviousState =
      order.previousMealId !== null ||
      order.previousDate !== null ||
      order.previousSlot !== null ||
      order.previousStatus !== null;

    if (!hasPreviousState && order.status === OrderStatus.SCHEDULED) {
      throw new ApiException(
        ErrorCode.NOTHING_TO_UNDO,
        'There is no previous action to undo for this order.',
      );
    }

    // Check cutoff for current deliveryDate
    const currentCutoffUtc = this.cutoffService.validateCutoffOrThrow(
      order.deliveryDate,
      user.timezone,
      sub.cutoffTime.hour,
      sub.cutoffTime.minute,
    );

    // Revert state according to status
    if (order.status === OrderStatus.SKIPPED) {
      order.status = order.previousStatus || OrderStatus.SCHEDULED;
      order.previousStatus = null;
    } else if (order.status === OrderStatus.SWAPPED) {
      if (order.previousMealId) {
        order.mealId = order.previousMealId;
      }
      order.status = order.previousStatus || OrderStatus.SCHEDULED;
      order.previousMealId = null;
      order.previousStatus = null;
    } else if (
      order.status === OrderStatus.MOVED ||
      order.status === OrderStatus.RESCHEDULED
    ) {
      const restoreDate = order.previousDate || order.deliveryDate;
      const restoreSlot = order.previousSlot || order.slot;

      // Validate that original destination cutoff has not passed
      this.cutoffService.validateCutoffOrThrow(
        restoreDate,
        user.timezone,
        sub.cutoffTime.hour,
        sub.cutoffTime.minute,
      );

      // Check conflict at restored destination
      const existingConflict = await this.orderModel.findOne({
        _id: { $ne: order._id },
        userId: new Types.ObjectId(userId),
        deliveryDate: restoreDate,
        slot: restoreSlot,
        status: { $ne: OrderStatus.SKIPPED },
      }).exec();

      if (existingConflict) {
        throw new ApiException(
          ErrorCode.DESTINATION_CONFLICT,
          `Cannot undo move: the original slot on ${restoreDate} (${restoreSlot}) is now occupied.`,
        );
      }

      order.deliveryDate = restoreDate;
      order.slot = restoreSlot;
      order.status = order.previousStatus || OrderStatus.SCHEDULED;
      order.previousDate = null;
      order.previousSlot = null;
      order.previousStatus = null;
    }

    order.cutoffAtUtc = currentCutoffUtc;
    order.version = (order.version || 1) + 1;
    await order.save();

    return this.getEnrichedOrder(order, user, sub);
  }

  /**
   * Helper to format an enriched populated order
   */
  private async getEnrichedOrder(
    order: ScheduledOrderDocument,
    user: UserDocument,
    sub: SubscriptionDocument,
  ) {
    await order.populate('mealId');
    const cutoffInfo = this.cutoffService.getCutoffDetails(
      order.deliveryDate,
      user.timezone,
      sub.cutoffTime.hour,
      sub.cutoffTime.minute,
    );

    const orderObj = order.toObject();
    return {
      ...orderObj,
      id: order._id.toString(),
      cutoffAtUtc: cutoffInfo.cutoffAtUtc,
      isCutoffPassed: cutoffInfo.isPassed,
      remainingCutoffMs: cutoffInfo.remainingMs,
    };
  }
}
