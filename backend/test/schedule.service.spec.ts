import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { Types } from 'mongoose';
import { ScheduleService } from '../src/schedule/schedule.service';
import { CutoffService } from '../src/cutoff/cutoff.service';
import { SubscriptionService } from '../src/subscription/subscription.service';
import { MealCatalogService } from '../src/meal-catalog/meal-catalog.service';
import { ScheduledOrder } from '../src/schemas/scheduled-order.schema';
import { User } from '../src/schemas/user.schema';
import { Subscription } from '../src/schemas/subscription.schema';
import { OrderStatus } from '../src/common/enums/order-status.enum';
import { MealSlot } from '../src/common/enums/meal-slot.enum';
import { SubscriptionStatus } from '../src/common/enums/subscription-status.enum';
import { ApiException } from '../src/common/exceptions/api.exception';
import { ErrorCode } from '../src/common/enums/error-code.enum';

describe('ScheduleService', () => {
  let service: ScheduleService;
  let mockOrderModel: any;
  let mockUserModel: any;
  let mockSubscriptionModel: any;
  let mockCutoffService: any;
  let mockSubscriptionService: any;
  let mockMealCatalogService: any;

  const mockUserId = new Types.ObjectId('6640c1a2f1839a5840d8a101');
  const mockSubId = new Types.ObjectId('6640c1a2f1839a5840d8a102');
  const mockMeal1Id = new Types.ObjectId('6640c1a2f1839a5840d8a201');
  const mockMeal2Id = new Types.ObjectId('6640c1a2f1839a5840d8a202');
  const mockOrderId = new Types.ObjectId('6640c1a2f1839a5840d8a301');

  const mockUser = {
    _id: mockUserId,
    name: 'Pranay Kumar',
    timezone: 'Asia/Kolkata',
  };

  const mockSubscription = {
    _id: mockSubId,
    userId: mockUserId,
    name: 'Healthy Plan • 6 Days',
    status: SubscriptionStatus.ACTIVE,
    cutoffTime: { hour: 20, minute: 30 },
  };

  beforeEach(async () => {
    mockUserModel = {
      findById: jest.fn().mockReturnValue({
        exec: jest.fn().mockResolvedValue(mockUser),
      }),
    };

    mockSubscriptionModel = {
      findOne: jest.fn().mockReturnValue({
        exec: jest.fn().mockResolvedValue(mockSubscription),
      }),
    };

    mockCutoffService = {
      getCutoffDetails: jest.fn().mockReturnValue({
        cutoffAtUtc: '2026-09-15T15:00:00.000Z',
        isPassed: false,
        remainingMs: 3600000,
      }),
      validateCutoffOrThrow: jest.fn().mockReturnValue('2026-09-15T15:00:00.000Z'),
    };

    mockSubscriptionService = {
      getSubscriptionForUser: jest.fn().mockResolvedValue(mockSubscription),
      validateSubscriptionActive: jest.fn().mockResolvedValue(mockSubscription),
    };

    mockMealCatalogService = {
      validateMealAvailable: jest.fn().mockResolvedValue({
        _id: mockMeal2Id,
        name: 'Teriyaki Salmon Bowl',
        available: true,
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ScheduleService,
        { provide: getModelToken(ScheduledOrder.name), useValue: {} },
        { provide: getModelToken(User.name), useValue: mockUserModel },
        { provide: getModelToken(Subscription.name), useValue: mockSubscriptionModel },
        { provide: CutoffService, useValue: mockCutoffService },
        { provide: SubscriptionService, useValue: mockSubscriptionService },
        { provide: MealCatalogService, useValue: mockMealCatalogService },
      ],
    }).compile();

    service = module.get<ScheduleService>(ScheduleService);
  });

  describe('Skip Mutation & Undo', () => {
    it('successfully skips a scheduled order and allows undo', async () => {
      const mockOrderInstance: any = {
        _id: mockOrderId,
        userId: mockUserId,
        subscriptionId: mockSubId,
        deliveryDate: '2026-09-16',
        slot: MealSlot.LUNCH,
        mealId: mockMeal1Id,
        status: OrderStatus.SCHEDULED,
        previousStatus: null,
        version: 1,
        save: jest.fn().mockResolvedValue(true),
        populate: jest.fn().mockResolvedValue(true),
        toObject: () => ({
          _id: mockOrderId,
          userId: mockUserId,
          deliveryDate: '2026-09-16',
          slot: MealSlot.LUNCH,
          status: mockOrderInstance.status,
          mealId: { _id: mockMeal1Id, name: 'Moroccan Dream Salad' },
        }),
      };

      jest.spyOn(service as any, 'getOrderAndValidateOwnership').mockResolvedValue(mockOrderInstance);

      // 1. Perform Skip
      const skippedResult = await service.skipOrder(mockUserId.toString(), mockOrderId.toString());
      expect(mockOrderInstance.status).toBe(OrderStatus.SKIPPED);
      expect(mockOrderInstance.previousStatus).toBe(OrderStatus.SCHEDULED);
      expect(mockOrderInstance.save).toHaveBeenCalled();

      // 2. Perform Undo
      const undoneResult = await service.undoOrder(mockUserId.toString(), mockOrderId.toString());
      expect(mockOrderInstance.status).toBe(OrderStatus.SCHEDULED);
      expect(mockOrderInstance.previousStatus).toBeNull();
    });

    it('rejects skip if order is already skipped', async () => {
      const mockOrderInstance: any = {
        _id: mockOrderId,
        userId: mockUserId,
        status: OrderStatus.SKIPPED,
        populate: jest.fn().mockResolvedValue(true),
      };

      jest.spyOn(service as any, 'getOrderAndValidateOwnership').mockResolvedValue(mockOrderInstance);

      await expect(
        service.skipOrder(mockUserId.toString(), mockOrderId.toString()),
      ).rejects.toThrow(ApiException);
    });
  });

  describe('Swap Mutation & Undo', () => {
    it('successfully swaps a meal and allows undoing back to previous meal', async () => {
      const mockOrderInstance: any = {
        _id: mockOrderId,
        userId: mockUserId,
        subscriptionId: mockSubId,
        deliveryDate: '2026-09-16',
        slot: MealSlot.LUNCH,
        mealId: mockMeal1Id,
        status: OrderStatus.SCHEDULED,
        previousMealId: null,
        previousStatus: null,
        version: 1,
        save: jest.fn().mockResolvedValue(true),
        populate: jest.fn().mockResolvedValue(true),
        toObject: () => ({
          _id: mockOrderId,
          userId: mockUserId,
          mealId: { _id: mockOrderInstance.mealId },
          status: mockOrderInstance.status,
        }),
      };

      jest.spyOn(service as any, 'getOrderAndValidateOwnership').mockResolvedValue(mockOrderInstance);

      // Swap to Meal 2
      await service.swapMeal(
        mockUserId.toString(),
        mockOrderId.toString(),
        mockMeal2Id.toString(),
      );

      expect(mockOrderInstance.status).toBe(OrderStatus.SWAPPED);
      expect(mockOrderInstance.mealId.toString()).toBe(mockMeal2Id.toString());
      expect(mockOrderInstance.previousMealId.toString()).toBe(mockMeal1Id.toString());

      // Undo Swap
      await service.undoOrder(mockUserId.toString(), mockOrderId.toString());
      expect(mockOrderInstance.status).toBe(OrderStatus.SCHEDULED);
      expect(mockOrderInstance.mealId.toString()).toBe(mockMeal1Id.toString());
      expect(mockOrderInstance.previousMealId).toBeNull();
    });
  });

  describe('Paused Subscription Gating', () => {
    it('blocks mutations when subscription is paused', async () => {
      mockSubscriptionService.validateSubscriptionActive.mockRejectedValue(
        new ApiException(
          ErrorCode.SUBSCRIPTION_PAUSED,
          'Your meal subscription is currently paused.',
        ),
      );

      await expect(
        service.skipOrder(mockUserId.toString(), mockOrderId.toString()),
      ).rejects.toThrow(ApiException);
    });
  });
});
