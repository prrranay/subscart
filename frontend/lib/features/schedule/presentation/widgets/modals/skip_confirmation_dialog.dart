import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/core/theme/app_colors.dart';
import 'package:suscart_app/core/theme/app_typography.dart';
import 'package:suscart_app/features/schedule/data/models/scheduled_order_model.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';

class SkipConfirmationDialog extends ConsumerStatefulWidget {
  final ScheduledOrderModel order;

  const SkipConfirmationDialog({super.key, required this.order});

  static Future<void> show(BuildContext context, ScheduledOrderModel order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SkipConfirmationDialog(order: order),
    );
  }

  @override
  ConsumerState<SkipConfirmationDialog> createState() => _SkipConfirmationDialogState();
}

class _SkipConfirmationDialogState extends ConsumerState<SkipConfirmationDialog> {
  int _selectedReasonIndex = 0;

  final List<String> _reasons = [
    'Traveling or out of town',
    'Eating out with friends / team lunch',
    'Prefer to cook at home today',
    'Other dietary plan change',
  ];

  @override
  Widget build(BuildContext context) {
    final mealName = widget.order.meal?.name ?? 'Scheduled Meal';
    final slotName = widget.order.slot.name.toUpperCase();

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

          // Title and Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAUSE ITEM',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Skip $slotName Meal?',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: AppColors.onSurfaceVariant,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'You will not receive $mealName on ${widget.order.deliveryDate}. Help us improve your experience by sharing why:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // Reason radio options
          ...List.generate(_reasons.length, (index) {
            final isSelected = _selectedReasonIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedReasonIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondaryFixed.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.outlineVariant.withOpacity(0.4),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _selectedReasonIndex,
                        activeColor: AppColors.secondary,
                        onChanged: (val) {
                          setState(() {
                            _selectedReasonIndex = val ?? 0;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _reasons[index],
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Suggestion Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.secondaryLight.withOpacity(0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Need more time away? You can pause your entire subscription with zero fees from the top overview.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

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
                    side: BorderSide(
                      color: AppColors.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Keep Meal',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.onError,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref
                        .read(scheduleNotifierProvider.notifier)
                        .skipOrder(widget.order.id);
                  },
                  child: Text(
                    'Confirm Skip',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onError,
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
