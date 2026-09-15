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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPassed
            ? AppColors.surfaceContainerHigh
            : AppColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPassed
              ? AppColors.outlineVariant.withOpacity(0.5)
              : AppColors.tertiaryAccent.withOpacity(0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPassed ? Icons.lock_clock_outlined : Icons.bolt_rounded,
            size: 13,
            color: isPassed
                ? AppColors.onSurfaceVariant
                : AppColors.onTertiaryFixedVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isPassed
                  ? 'Editing closed for this order'
                  : 'Edits allowed until 8:30 PM • ${cutoffStatus.formattedRemaining}',
              style: AppTypography.labelSmall.copyWith(
                color: isPassed
                    ? AppColors.onSurfaceVariant
                    : AppColors.onTertiaryFixedVariant,
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
