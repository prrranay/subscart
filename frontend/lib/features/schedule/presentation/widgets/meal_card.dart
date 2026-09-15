import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:suscart_app/core/theme/app_colors.dart';
import 'package:suscart_app/core/theme/app_typography.dart';
import 'package:suscart_app/features/schedule/data/models/scheduled_order_model.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:suscart_app/features/schedule/presentation/providers/cutoff_ticker_provider.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/modals/skip_confirmation_dialog.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/modals/swap_bottom_sheet.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/modals/move_bottom_sheet.dart';

class MealCard extends ConsumerWidget {
  final ScheduledOrderModel order;

  const MealCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final cutoffStatus = ref.watch(orderCutoffProvider(order));

    final isSubscriptionPaused =
        scheduleState.data?.subscription.isPaused ?? false;
    final isCutoffPassed = cutoffStatus.isPassed || order.isCutoffPassed;
    final isActionsDisabled =
        isCutoffPassed || isSubscriptionPaused || scheduleState.isMutating;

    final meal = order.meal;
    final isSkipped = order.isSkipped;
    final isSwapped = order.isSwapped;
    final isMoved = order.isMoved || order.isRescheduled;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isSkipped ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSkipped
                ? AppColors.outlineVariant.withOpacity(0.4)
                : AppColors.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image & Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal Thumbnail with Hero Tag
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: Hero(
                          tag: 'meal_img_${order.id}_${meal?.id}',
                          child: CachedNetworkImage(
                            imageUrl: meal?.imageUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceContainerHigh,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceContainerHigh,
                              child: const Icon(
                                Icons.restaurant_rounded,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (meal?.isChefSpecial == true)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            'Chef Special',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // Meal Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              meal?.name ?? 'Assigned Meal',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: isSkipped
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSkipped)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Skipped',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onErrorContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          else if (isSwapped)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Swapped',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSecondaryFixed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          else if (isMoved)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryFixed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Moved',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onPrimaryFixed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Included',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSecondaryFixed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meal?.description.isNotEmpty == true
                            ? meal!.description
                            : 'Freshly prepared nutrient-dense ingredients.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Macro Pills
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildMacroPill('${meal?.calories ?? 0} kcal', isHighlight: true),
                          _buildMacroPill('Prot: ${meal?.protein ?? 0}g'),
                          _buildMacroPill('Carbs: ${meal?.carbs ?? 0}g'),
                          _buildMacroPill('Fat: ${meal?.fat ?? 0}g'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Eco packaging label
            Row(
              children: [
                const Icon(
                  Icons.eco_rounded,
                  size: 14,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Packed in 100% compostable sugarcane bowl',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant.withOpacity(0.8),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Secondary Quick Action Trio: Skip, Swap, Move (or Undo if Skipped)
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.outlineVariant.withOpacity(0.2),
                  ),
                ),
              ),
              child: isSkipped
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Meal paused for this slot',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: isActionsDisabled
                              ? null
                              : () {
                                  ref
                                      .read(scheduleNotifierProvider.notifier)
                                      .undoOrder(order.id);
                                },
                          icon: const Icon(Icons.undo_rounded, size: 16),
                          label: const Text('Undo Skip'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            textStyle: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // 1. Skip Button
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.skip_next_rounded,
                            label: 'Skip',
                            isDisabled: isActionsDisabled,
                            onTap: () => SkipConfirmationDialog.show(context, order),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 2. Swap Button
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.swap_horiz_rounded,
                            label: 'Swap',
                            isPrimaryTone: true,
                            isDisabled: isActionsDisabled,
                            onTap: () => SwapBottomSheet.show(context, order),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 3. Move Button
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: Icons.schedule_rounded,
                            label: 'Move',
                            isDisabled: isActionsDisabled,
                            onTap: () => MoveBottomSheet.show(context, order),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPill(String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.primaryContainer.withOpacity(0.08)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlight
              ? AppColors.primaryContainer.withOpacity(0.2)
              : AppColors.outlineVariant.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: isHighlight ? AppColors.primary : AppColors.onSurfaceVariant,
          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          fontSize: 10.5,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimaryTone = false,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isPrimaryTone
              ? (isDisabled
                  ? AppColors.surfaceContainerLow
                  : AppColors.primaryContainer.withOpacity(0.08))
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimaryTone
                ? AppColors.primaryContainer.withOpacity(0.2)
                : AppColors.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDisabled
                  ? AppColors.outlineVariant
                  : (isPrimaryTone ? AppColors.primary : AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isDisabled
                    ? AppColors.outlineVariant
                    : (isPrimaryTone ? AppColors.primary : AppColors.onSurface),
                fontWeight: isPrimaryTone ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
