import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/core/theme/app_colors.dart';
import 'package:suscart_app/core/theme/app_typography.dart';
import 'package:suscart_app/core/utils/date_formatter.dart';
import 'package:suscart_app/features/schedule/data/models/scheduled_order_model.dart';
import 'package:suscart_app/features/schedule/domain/enums/meal_slot.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:suscart_app/features/schedule/presentation/providers/cutoff_ticker_provider.dart';

class MoveBottomSheet extends ConsumerStatefulWidget {
  final ScheduledOrderModel order;

  const MoveBottomSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, ScheduledOrderModel order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoveBottomSheet(order: order),
    );
  }

  @override
  ConsumerState<MoveBottomSheet> createState() => _MoveBottomSheetState();
}

class _MoveBottomSheetState extends ConsumerState<MoveBottomSheet> {
  late String _selectedDate;
  late MealSlot _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.order.deliveryDate;
    _selectedSlot = widget.order.slot;
  }

  @override
  Widget build(BuildContext context) {
    final availableDates = ref.watch(scheduleDatesProvider);
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final allOrders = scheduleState.data?.orders ?? [];

    final isConflict = allOrders.any((o) =>
        o.id != widget.order.id &&
        o.deliveryDate == _selectedDate &&
        o.slot == _selectedSlot &&
        !o.isSkipped);

    final isSameDestination = _selectedDate == widget.order.deliveryDate &&
        _selectedSlot == widget.order.slot;

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
                          'DELIVERY TIMING',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Move Meal Slot',
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

              // 1. Target Delivery Day
              Text(
                'TARGET DELIVERY DAY',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: availableDates.map((dateStr) {
                    final isSelected = dateStr == _selectedDate;
                    final isCutoffPassed = isTargetDateCutoffPassed(dateStr);
                    final formatted = DateFormatter.formatShortDay(dateStr);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: isCutoffPassed
                            ? null
                            : () {
                                setState(() {
                                  _selectedDate = dateStr;
                                });
                              },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isCutoffPassed
                                ? AppColors.surfaceContainerHigh.withOpacity(0.5)
                                : (isSelected
                                    ? AppColors.primaryContainer
                                    : AppColors.surfaceContainerLow),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCutoffPassed
                                  ? AppColors.outlineVariant.withOpacity(0.2)
                                  : (isSelected
                                      ? AppColors.primaryContainer
                                      : AppColors.outlineVariant.withOpacity(0.3)),
                            ),
                          ),
                          child: Row(
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
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 2. Time Window / Slot
              Text(
                'TIME WINDOW',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              ...MealSlot.values.map((slot) {
                final isSelected = _selectedSlot == slot;
                final isCurrent = widget.order.slot == slot &&
                    widget.order.deliveryDate == _selectedDate;

                final slotOccupied = allOrders.any((o) =>
                    o.id != widget.order.id &&
                    o.deliveryDate == _selectedDate &&
                    o.slot == slot &&
                    !o.isSkipped);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSlot = slot;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondaryFixed.withOpacity(0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.outlineVariant.withOpacity(0.35),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Radio<MealSlot>(
                                  value: slot,
                                  groupValue: _selectedSlot,
                                  activeColor: AppColors.secondary,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedSlot = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot.displayName,
                                        style: AppTypography.titleMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        slot.timeWindow,
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
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Current',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSecondaryFixed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (slotOccupied)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Occupied',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (isConflict)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Destination slot is occupied. Choose an open slot or swap instead.',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

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
                  onPressed: (isConflict || isSameDestination || isTargetDateCutoffPassed(_selectedDate))
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          ref.read(scheduleNotifierProvider.notifier).moveOrder(
                                widget.order.id,
                                _selectedDate,
                                _selectedSlot,
                              );
                        },
                  child: Text(
                    'Save Changes',
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
    ),
  ),
);
  }
}
