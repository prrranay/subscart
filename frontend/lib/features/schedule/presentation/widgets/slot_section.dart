import 'package:flutter/material.dart';
import 'package:suscart_app/core/theme/app_colors.dart';
import 'package:suscart_app/core/theme/app_typography.dart';
import 'package:suscart_app/features/schedule/data/models/scheduled_order_model.dart';
import 'package:suscart_app/features/schedule/domain/enums/meal_slot.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/meal_card.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/cutoff_banner.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/extra_products_button.dart';

class SlotSection extends StatelessWidget {
  final MealSlot slot;
  final ScheduledOrderModel? order;
  final String dateStr;

  const SlotSection({
    super.key,
    required this.slot,
    this.order,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    final hasOrder = order != null;

    if (!hasOrder) {
      // Empty Unscheduled Slot placeholder
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getSlotIcon(slot),
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.displayName} (${slot.timeWindow})',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'No meal scheduled for this slot',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.4),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Select an available bowl or warm plate to add to ${slot.displayName}.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.inverseOnSurface),
                    ),
                  ),
                );
              },
              child: Text(
                '+ Add Meal',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Active Slot Container
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot Meta Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${slot.displayName} (${slot.timeWindow})',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Cutoff Banner with live ticker
          CutoffBanner(order: order!),

          // Meal Card
          MealCard(order: order!),

          // Add Extra Products Button
          const SizedBox(height: 12),
          const ExtraProductsButton(),
        ],
      ),
    );
  }

  IconData _getSlotIcon(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return Icons.wb_sunny_rounded;
      case MealSlot.lunch:
        return Icons.restaurant_rounded;
      case MealSlot.dinner:
        return Icons.nights_stay_rounded;
    }
  }
}
