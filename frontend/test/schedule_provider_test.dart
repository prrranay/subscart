import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/features/schedule/data/models/schedule_response_model.dart';
import 'package:suscart_app/features/schedule/data/models/scheduled_order_model.dart';
import 'package:suscart_app/features/schedule/data/models/subscription_model.dart';
import 'package:suscart_app/features/schedule/data/models/user_model.dart';
import 'package:suscart_app/features/schedule/data/models/meal_model.dart';
import 'package:suscart_app/features/schedule/data/repositories/schedule_repository.dart';
import 'package:suscart_app/features/schedule/domain/enums/meal_slot.dart';
import 'package:suscart_app/features/schedule/domain/enums/order_status.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:suscart_app/core/errors/app_exception.dart';

class FakeScheduleRepository extends ScheduleRepository {
  bool shouldFail = false;

  final sampleMeal = const MealModel(
    id: 'meal_1',
    name: 'Moroccan Dream Salad',
    imageUrl: 'https://example.com/meal.jpg',
    calories: 384,
    protein: 13,
    carbs: 50,
    fat: 14,
    category: 'Bowls',
    available: true,
  );

  @override
  Future<ScheduleResponseModel> getSchedule({String? startDate, String? endDate}) async {
    return ScheduleResponseModel(
      user: const UserModel(id: 'user_1', name: 'Pranay Kumar', timezone: 'Asia/Kolkata'),
      subscription: const SubscriptionModel(
        id: 'sub_1',
        name: 'Healthy Plan • 6 Days',
        status: 'active',
        cutoffTime: CutoffTimeModel(hour: 20, minute: 30),
      ),
      cutoffConfig: const CutoffConfigModel(hour: 20, minute: 30, timezone: 'Asia/Kolkata'),
      orders: [
        ScheduledOrderModel(
          id: 'order_1',
          userId: 'user_1',
          subscriptionId: 'sub_1',
          deliveryDate: '2026-09-16',
          meal: sampleMeal,
          slot: MealSlot.lunch,
          status: OrderStatus.scheduled,
          cutoffAtUtc: '2026-09-15T15:00:00.000Z',
        ),
      ],
    );
  }

  @override
  Future<ScheduledOrderModel> skipOrder(String orderId) async {
    if (shouldFail) {
      throw AppException(
        code: 'EDIT_CUTOFF_PASSED',
        message: 'Edits are no longer allowed for this order.',
      );
    }
    return ScheduledOrderModel(
      id: orderId,
      userId: 'user_1',
      subscriptionId: 'sub_1',
      deliveryDate: '2026-09-16',
      meal: sampleMeal,
      slot: MealSlot.lunch,
      status: OrderStatus.skipped,
      cutoffAtUtc: '2026-09-15T15:00:00.000Z',
    );
  }
}

void main() {
  group('ScheduleNotifier & Optimistic Updates', () {
    late FakeScheduleRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = FakeScheduleRepository();
      container = ProviderContainer(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Loads initial schedule data correctly', () async {
      final notifier = container.read(scheduleNotifierProvider.notifier);
      await notifier.loadSchedule();

      final state = container.read(scheduleNotifierProvider);
      expect(state.isLoading, false);
      expect(state.data, isNotNull);
      expect(state.data!.orders.length, 1);
      expect(state.data!.orders.first.meal?.name, 'Moroccan Dream Salad');
    });

    test('Optimistically skips meal and commits on success', () async {
      final notifier = container.read(scheduleNotifierProvider.notifier);
      await notifier.loadSchedule();

      final success = await notifier.skipOrder('order_1');
      expect(success, true);

      final state = container.read(scheduleNotifierProvider);
      expect(state.data!.orders.first.status, OrderStatus.skipped);

      final feedback = container.read(mutationFeedbackProvider);
      expect(feedback?.isSuccess, true);
      expect(feedback?.canUndo, true);
    });

    test('Rolls back optimistic skip if backend rejects with cutoff passed', () async {
      fakeRepository.shouldFail = true;
      final notifier = container.read(scheduleNotifierProvider.notifier);
      await notifier.loadSchedule();

      final success = await notifier.skipOrder('order_1');
      expect(success, false);

      // Verify state was rolled back to scheduled
      final state = container.read(scheduleNotifierProvider);
      expect(state.data!.orders.first.status, OrderStatus.scheduled);

      final feedback = container.read(mutationFeedbackProvider);
      expect(feedback?.isSuccess, false);
      expect(feedback?.message, contains('Edits are no longer allowed'));
    });
  });
}
