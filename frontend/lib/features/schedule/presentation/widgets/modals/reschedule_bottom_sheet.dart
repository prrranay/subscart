import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/scheduled_order_model.dart';
import '../providers/schedule_provider.dart';
import '../providers/cutoff_ticker_provider.dart';

class RescheduleBottomSheet extends ConsumerStatefulWidget {
  final ScheduledOrderModel order;

  const RescheduleBottomSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, ScheduledOrderModel order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RescheduleBottomSheet(order: order),
    );
  }

  @override
  ConsumerState<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends ConsumerState<RescheduleBottomSheet> {
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.order.deliveryDate;
  }

  @override
  Widget build(BuildContext context) {
    final availableDates = ref.watch(scheduleDatesProvider);
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final allOrders = scheduleState.data?.orders ?? [];

    final hasConflict = allOrders.any((o) =>
        o.id != widget.order.id &&
        o.deliveryDate == _selectedDate &&
        o.slot == widget.order.slot &&
        !o.isSkipped);

    final isSameDate = _selectedDate == widget.order.deliveryDate;

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RESCHEDULE DATE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Reschedule ${widget.order.slot.displayName}',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Current delivery overview card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current: ${DateFormatter.formatFullDate(widget.order.deliveryDate)}',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Slot: ${widget.order.slot.displayName} (${widget.order.slot.timeWindow})',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'CHOOSE NEW DELIVERY DATE',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

          // Grid of selectable dates
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableDates.map((dateStr) {
              final isSelected = dateStr == _selectedDate;
              final isCurrent = dateStr == widget.order.deliveryDate;
              final isCutoffPassed = isTargetDateCutoffPassed(dateStr);
              final formatted = DateFormatter.formatShortDay(dateStr);

              return InkWell(
                onTap: isCutoffPassed
                    ? null
                    : () {
                        setState(() {
                          _selectedDate = dateStr;
                        });
                      },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCutoffPassed
                        ? AppColors.surfaceContainerHigh.withOpacity(0.5)
                        : (isSelected
                            ? AppColors.primaryContainer
                            : AppColors.surface),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCutoffPassed
                          ? AppColors.outlineVariant.withOpacity(0.2)
                          : (isSelected
                              ? AppColors.primaryContainer
                              : AppColors.outlineVariant.withOpacity(0.3)),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatted,
                            style: AppTypography.labelMedium.copyWith(
                              color: isCutoffPassed
                                  ? AppColors.onSurfaceVariant.withOpacity(0.4)
                                  : (isSelected
                                      ? AppColors.onPrimary
                                      : AppColors.onSurface),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              decoration: isCutoffPassed
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          if (isCutoffPassed) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 12,
                              color: AppColors.onSurfaceVariant.withOpacity(0.4),
                            ),
                          ],
                        ],
                      ),
                      if (isCurrent)
                        Text(
                          'Current',
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.primaryFixed
                                : AppColors.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (hasConflict)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'You already have an active meal on $_selectedDate for this slot.',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: (hasConflict || isSameDate || isTargetDateCutoffPassed(_selectedDate))
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          ref.read(scheduleNotifierProvider.notifier).rescheduleOrder(
                                widget.order.id,
                                _selectedDate,
                              );
                        },
                  child: Text(
                    'Confirm Reschedule',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
