import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/main.dart';
import 'package:suscart_app/features/schedule/data/models/meal_model.dart';
import 'package:suscart_app/features/schedule/data/models/scheduled_order_model.dart';
import 'package:suscart_app/features/schedule/data/models/schedule_response_model.dart';
import 'package:suscart_app/features/schedule/data/models/subscription_model.dart';
import 'package:suscart_app/features/schedule/data/models/user_model.dart';
import 'package:suscart_app/features/schedule/data/repositories/schedule_repository.dart';
import 'package:suscart_app/features/schedule/domain/enums/meal_slot.dart';
import 'package:suscart_app/features/schedule/domain/enums/order_status.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:suscart_app/features/schedule/presentation/providers/cutoff_ticker_provider.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/meal_card.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/modals/swap_bottom_sheet.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/modals/move_bottom_sheet.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/modals/skip_confirmation_dialog.dart';

class ResponsiveFakeScheduleRepository extends ScheduleRepository {
  final sampleMeal = const MealModel(
    id: 'meal_1',
    name: 'Grilled Herb Chicken & Sweet Potato Roasted Bowl Extra Special',
    imageUrl: '',
    calories: 450,
    protein: 38,
    carbs: 42,
    fat: 16,
    category: 'Warm Bowls',
    available: true,
    isChefSpecial: true,
    description: 'Fresh grilled chicken breast served with roasted rosemary sweet potato cubes and crisp broccoli florets in compostable sugarcane.',
    dietaryTags: ['High Protein', 'Gluten-Free'],
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
          deliveryDate: '2026-09-18',
          meal: sampleMeal,
          slot: MealSlot.lunch,
          status: OrderStatus.scheduled,
          cutoffAtUtc: '2026-09-17T15:00:00.000Z',
          isCutoffPassed: false,
        ),
      ],
    );
  }

  @override
  Future<List<MealModel>> getAvailableMeals({String? category, String? dietaryTag}) async {
    return [sampleMeal];
  }
}

void main() {
  const viewports = [
    Size(360, 800), // Compact Phone
    Size(390, 844), // Standard Phone
    Size(412, 915), // Large Phone
  ];

  for (final size in viewports) {
    group('Viewport ${size.width.toInt()}x${size.height.toInt()} responsiveness', () {
      testWidgets('ScheduleScreen renders cleanly without overflow', (tester) async {
        tester.view.physicalSize = Size(size.width * 3, size.height * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final repo = ResponsiveFakeScheduleRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              scheduleRepositoryProvider.overrideWithValue(repo),
              tickerProvider.overrideWith((ref) => Stream.value(0)),
            ],
            child: const SusCartApp(),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify No RenderFlex errors occurred
        expect(tester.takeException(), isNull);
        expect(find.byType(MealCard), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
        expect(find.text('Swap'), findsOneWidget);
        expect(find.text('Move'), findsOneWidget);
      });

      testWidgets('Modals render cleanly without overflow', (tester) async {
        tester.view.physicalSize = Size(size.width * 3, size.height * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final repo = ResponsiveFakeScheduleRepository();
        final order = (await repo.getSchedule()).orders.first;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              scheduleRepositoryProvider.overrideWithValue(repo),
              tickerProvider.overrideWith((ref) => Stream.value(0)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => SwapBottomSheet.show(context, order),
                    child: const Text('Open Modal'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.tap(find.text('Open Modal'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify Modal loaded without any RenderFlex overflow
        expect(tester.takeException(), isNull);
        expect(find.text('CUSTOMIZE MENU'), findsOneWidget);
      });
    });
  }
}
