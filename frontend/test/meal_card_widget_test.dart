import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/features/schedule/data/models/meal_model.dart';
import 'package:suscart_app/features/schedule/data/models/scheduled_order_model.dart';
import 'package:suscart_app/features/schedule/data/models/schedule_response_model.dart';
import 'package:suscart_app/features/schedule/data/models/subscription_model.dart';
import 'package:suscart_app/features/schedule/data/models/user_model.dart';
import 'package:suscart_app/features/schedule/data/repositories/schedule_repository.dart';
import 'package:suscart_app/features/schedule/domain/enums/meal_slot.dart';
import 'package:suscart_app/features/schedule/domain/enums/order_status.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/meal_card.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:suscart_app/features/schedule/presentation/providers/cutoff_ticker_provider.dart';

class FakeScheduleRepository extends ScheduleRepository {
  @override
  Future<ScheduleResponseModel> getSchedule({String? startDate, String? endDate}) async {
    return const ScheduleResponseModel(
      user: UserModel(id: 'user_1', name: 'Pranay Kumar', timezone: 'Asia/Kolkata'),
      subscription: SubscriptionModel(
        id: 'sub_1',
        name: 'Healthy Plan',
        status: 'active',
        cutoffTime: CutoffTimeModel(hour: 20, minute: 30),
      ),
      cutoffConfig: CutoffConfigModel(hour: 20, minute: 30, timezone: 'Asia/Kolkata'),
      orders: [],
    );
  }
}

void main() {
  const sampleMeal = MealModel(
    id: 'meal_1',
    name: 'Moroccan Dream Salad',
    imageUrl: '',
    calories: 384,
    protein: 13,
    carbs: 50,
    fat: 14,
    category: 'Bowls & Salads',
    available: true,
    isChefSpecial: true,
    description: 'Spiced chickpeas, roasted cumin carrots & quinoa.',
  );

  const sampleOrder = ScheduledOrderModel(
    id: 'order_1',
    userId: 'user_1',
    subscriptionId: 'sub_1',
    deliveryDate: '2026-09-16',
    meal: sampleMeal,
    slot: MealSlot.lunch,
    status: OrderStatus.scheduled,
    cutoffAtUtc: '2026-09-15T15:00:00.000Z',
    isCutoffPassed: false,
  );

  testWidgets('MealCard renders meal details, macros, and action buttons', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()),
          tickerProvider.overrideWith((ref) => Stream.value(0)),
          orderCutoffProvider(sampleOrder).overrideWithValue(
            const CutoffStatus(
              isPassed: false,
              remaining: Duration(hours: 2),
              formattedRemaining: '02h 00m remaining',
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MealCard(order: sampleOrder),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Title & Macros
    expect(find.text('Moroccan Dream Salad'), findsOneWidget);
    expect(find.text('384 kcal'), findsOneWidget);
    expect(find.text('Prot: 13g'), findsOneWidget);
    expect(find.text('Carbs: 50g'), findsOneWidget);
    expect(find.text('Fat: 14g'), findsOneWidget);

    // Verify Quick Action Trio
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Swap'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
  });
}
