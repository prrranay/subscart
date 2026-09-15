import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/core/theme/app_colors.dart';
import 'package:suscart_app/core/theme/app_typography.dart';
import 'package:suscart_app/core/utils/date_formatter.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';

class DateSelectorStrip extends ConsumerWidget {
  const DateSelectorStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableDates = ref.watch(scheduleDatesProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    if (availableDates.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: availableDates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final dateStr = availableDates[index];
          final isSelected = dateStr == selectedDate;
          final weekday = DateFormatter.formatWeekday(dateStr);
          final dayNum = DateFormatter.formatDayNum(dateStr);

          return GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = dateStr;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSelected ? 58 : 52,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.outlineVariant.withOpacity(0.35),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekday,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? AppColors.primaryFixed
                          : AppColors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.surfaceContainerLowest
                          : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayNum,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurface,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Matcha allocation dot
                  Container(
                    width: isSelected ? 7 : 5,
                    height: isSelected ? 7 : 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.secondaryFixed
                          : AppColors.secondaryLight.withOpacity(0.7),
                      border: isSelected
                          ? Border.all(color: AppColors.primaryContainer, width: 1.5)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
