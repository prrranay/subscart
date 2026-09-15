import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/main.dart';
import 'package:suscart_app/features/schedule/presentation/providers/cutoff_ticker_provider.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'meal_card_widget_test.dart';

void main() {
  testWidgets('App smoke test loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository()),
          tickerProvider.overrideWith((ref) => Stream.value(0)),
        ],
        child: const SusCartApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(SusCartApp), findsOneWidget);
  });
}
