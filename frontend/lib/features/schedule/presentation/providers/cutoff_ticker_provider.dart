import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/scheduled_order_model.dart';
import '../../../../core/utils/date_formatter.dart';

/// Periodic stream provider emitting a tick every second for live countdown
final tickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (count) => count);
});

/// Cutoff Status Record
class CutoffStatus {
  final bool isPassed;
  final Duration remaining;
  final String formattedRemaining;
  final String? cutoffAtUtc;

  const CutoffStatus({
    required this.isPassed,
    required this.remaining,
    required this.formattedRemaining,
    this.cutoffAtUtc,
  });
}

/// Provider that calculates remaining time to cutoff for a given order
final orderCutoffProvider =
    Provider.family.autoDispose<CutoffStatus, ScheduledOrderModel>((ref, order) {
  // Listen to ticker to refresh every second
  ref.watch(tickerProvider);

  if (order.cutoffAtUtc == null || order.cutoffAtUtc!.isEmpty) {
    return const CutoffStatus(
      isPassed: false,
      remaining: Duration.zero,
      formattedRemaining: '',
    );
  }

  try {
    final cutoffUtc = DateTime.parse(order.cutoffAtUtc!).toUtc();
    final nowUtc = DateTime.now().toUtc();
    final difference = cutoffUtc.difference(nowUtc);

    final isPassed = difference.isNegative || difference.inSeconds <= 0;
    final formatted = DateFormatter.formatRemaining(difference);

    return CutoffStatus(
      isPassed: isPassed,
      remaining: difference.isNegative ? Duration.zero : difference,
      formattedRemaining: formatted,
      cutoffAtUtc: order.cutoffAtUtc,
    );
  } catch (e) {
    return const CutoffStatus(
      isPassed: false,
      remaining: Duration.zero,
      formattedRemaining: '',
    );
  }
});

/// Validates whether the cutoff deadline for a target delivery date has passed
bool isTargetDateCutoffPassed(String targetDeliveryDate, {int hour = 20, int minute = 30}) {
  try {
    final deliveryDate = DateTime.parse(targetDeliveryDate);
    final dayBefore = deliveryDate.subtract(const Duration(days: 1));

    // Cutoff is 8:30 PM (20:30) IST = 15:00 UTC on the day before delivery
    final cutoffUtc = DateTime.utc(
      dayBefore.year,
      dayBefore.month,
      dayBefore.day,
      hour,
      minute,
    ).subtract(const Duration(hours: 5, minutes: 30));

    return DateTime.now().toUtc().isAfter(cutoffUtc);
  } catch (_) {
    return false;
  }
}

