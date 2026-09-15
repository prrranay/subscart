import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/core/theme/app_colors.dart';
import 'package:suscart_app/core/theme/app_typography.dart';
import 'package:suscart_app/features/schedule/data/models/scheduled_order_model.dart';
import 'package:suscart_app/features/schedule/presentation/providers/cutoff_ticker_provider.dart';

class CutoffBanner extends ConsumerWidget {
  final ScheduledOrderModel order;

  const CutoffBanner({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cutoffStatus = ref.watch(orderCutoffProvider(order));

    final isPassed = cutoffStatus.isPassed || order.isCutoffPassed;
    final remainingHours = cutoffStatus.remaining.inHours;

    // Color tier configuration
    final Color backgroundColor;
    final Color borderColor;
    final Color contentColor;
    final IconData iconData;

    if (isPassed) {
      backgroundColor = AppColors.surfaceContainerHigh;
      borderColor = AppColors.outlineVariant.withOpacity(0.5);
      contentColor = AppColors.onSurfaceVariant;
      iconData = Icons.lock_clock_outlined;
    } else if (remainingHours >= 24) {
      // Far (> 24 hours): calm, confident botanical green
      backgroundColor = const Color(0xFFEBF7EE);
      borderColor = const Color(0xFFA5D6A7).withOpacity(0.8);
      contentColor = const Color(0xFF1B5E20);
      iconData = Icons.schedule_rounded;
    } else if (remainingHours >= 6) {
      // Approaching (6h - 24h): warm attention amber
      backgroundColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFE082);
      contentColor = const Color(0xFF92400E);
      iconData = Icons.access_time_filled_rounded;
    } else {
      // Urgent (< 6h): high-priority terracotta alert
      backgroundColor = AppColors.tertiaryFixed;
      borderColor = AppColors.tertiaryAccent.withOpacity(0.4);
      contentColor = AppColors.onTertiaryFixedVariant;
      iconData = Icons.bolt_rounded;
    }

    final displayText = isPassed
        ? 'Editing closed for this order'
        : 'Edits allowed until ${cutoffStatus.formattedDeadline} • ${cutoffStatus.formattedRemaining}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 13,
            color: contentColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              displayText,
              style: AppTypography.labelSmall.copyWith(
                color: contentColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
