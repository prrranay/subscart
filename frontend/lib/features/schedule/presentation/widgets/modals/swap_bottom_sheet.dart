import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:suscart_app/core/theme/app_colors.dart';
import 'package:suscart_app/core/theme/app_typography.dart';
import 'package:suscart_app/features/schedule/data/models/scheduled_order_model.dart';
import 'package:suscart_app/features/schedule/data/models/meal_model.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:suscart_app/features/schedule/presentation/providers/meal_catalog_provider.dart';

class SwapBottomSheet extends ConsumerStatefulWidget {
  final ScheduledOrderModel order;

  const SwapBottomSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, ScheduledOrderModel order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SwapBottomSheet(order: order),
    );
  }

  @override
  ConsumerState<SwapBottomSheet> createState() => _SwapBottomSheetState();
}

class _SwapBottomSheetState extends ConsumerState<SwapBottomSheet> {
  String _searchQuery = '';
  String _selectedTag = 'All';

  @override
  Widget build(BuildContext context) {
    final currentMeal = widget.order.meal;
    final mealsAsync = ref.watch(availableMealsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
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
                      'CUSTOMIZE MENU',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Replace ${currentMeal?.name ?? "Meal"}',
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

          const SizedBox(height: 12),

          // Search Bar
          TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search healthy bowls, keto, protein...',
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant.withOpacity(0.7),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.secondary,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Dietary Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('High Protein'),
                const SizedBox(width: 8),
                _buildFilterChip('Vegan'),
                const SizedBox(width: 8),
                _buildFilterChip('Keto'),
                const SizedBox(width: 8),
                _buildFilterChip('Gluten-Free'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Meal list
          Expanded(
            child: mealsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Failed to load meals: $err',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
              data: (meals) {
                final filtered = meals.where((meal) {
                  if (meal.id == currentMeal?.id) return false;

                  final matchesSearch = _searchQuery.isEmpty ||
                      meal.name.toLowerCase().contains(_searchQuery) ||
                      meal.description.toLowerCase().contains(_searchQuery);

                  final matchesTag = _selectedTag == 'All' ||
                      meal.dietaryTags.any(
                        (tag) => tag.toLowerCase().contains(_selectedTag.toLowerCase()),
                      );

                  return matchesSearch && matchesTag;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No meals found matching your filters.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final meal = filtered[index];
                    final isChefSpecial = meal.isChefSpecial;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isChefSpecial
                            ? AppColors.secondaryFixed.withOpacity(0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isChefSpecial
                              ? AppColors.secondary
                              : AppColors.outlineVariant.withOpacity(0.3),
                          width: isChefSpecial ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: Hero(
                                tag: 'meal_img_${widget.order.id}_${meal.id}',
                                child: CachedNetworkImage(
                                  imageUrl: meal.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.surfaceContainerHigh,
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
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isChefSpecial)
                                  Text(
                                    'Recommended Match',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                Text(
                                  meal.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${meal.calories} kcal • ${meal.protein}g Prot • ${meal.carbs}g Carbs',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isChefSpecial
                                  ? AppColors.primary
                                  : AppColors.surfaceContainerLow,
                              foregroundColor: isChefSpecial
                                  ? AppColors.onPrimary
                                  : AppColors.onSurface,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isChefSpecial
                                      ? AppColors.primary
                                      : AppColors.outlineVariant.withOpacity(0.4),
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              ref
                                  .read(scheduleNotifierProvider.notifier)
                                  .swapMeal(widget.order.id, meal);
                            },
                            child: Text(
                              'Select',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isChefSpecial
                                    ? AppColors.onPrimary
                                    : AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'All swaps include dressing & allergy tags',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedTag == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTag = label;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : AppColors.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
