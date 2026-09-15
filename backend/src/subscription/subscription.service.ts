import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Subscription, SubscriptionDocument } from '../schemas/subscription.schema';
import { User, UserDocument } from '../schemas/user.schema';
import { SubscriptionStatus } from '../common/enums/subscription-status.enum';
import { ApiException } from '../common/exceptions/api.exception';
import { ErrorCode } from '../common/enums/error-code.enum';

@Injectable()
export class SubscriptionService {
  private readonly logger = new Logger(SubscriptionService.name);

  constructor(
    @InjectModel(Subscription.name)
    private readonly subscriptionModel: Model<SubscriptionDocument>,
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
  ) {}

  async findByUserId(userId: string | Types.ObjectId): Promise<SubscriptionDocument | null> {
    return this.subscriptionModel.findOne({ userId: new Types.ObjectId(userId) }).exec();
  }

  async getSubscriptionForUser(userId: string | Types.ObjectId): Promise<SubscriptionDocument> {
    const sub = await this.findByUserId(userId);
    if (!sub) {
      throw new ApiException(
        ErrorCode.ORDER_NOT_FOUND,
        `No subscription found for user ${userId}.`,
      );
    }
    return sub;
  }

  /**
   * Toggles subscription between active and paused.
   * Documented Rule:
   * When paused, future scheduled orders remain in place, but all edit mutations
   * (Skip, Swap, Move, Reschedule) are strictly blocked with SUBSCRIPTION_PAUSED.
   * Resuming reactivates editing permissions (subject to regular order cutoff checks).
   */
  async setPauseStatus(
    userId: string | Types.ObjectId,
    paused: boolean,
  ): Promise<SubscriptionDocument> {
    const sub = await this.getSubscriptionForUser(userId);
    sub.status = paused ? SubscriptionStatus.PAUSED : SubscriptionStatus.ACTIVE;
    await sub.save();
    return sub;
  }

  /**
   * Validates that the subscription is active before allowing meal mutations.
   */
  async validateSubscriptionActive(userId: string | Types.ObjectId): Promise<SubscriptionDocument> {
    const sub = await this.getSubscriptionForUser(userId);
    if (sub.status === SubscriptionStatus.PAUSED) {
      throw new ApiException(
        ErrorCode.SUBSCRIPTION_PAUSED,
        'Your meal subscription is currently paused. Please resume your subscription before modifying scheduled meals.',
      );
    }
    return sub;
  }
}
