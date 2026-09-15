import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/core/theme/app_colors.dart';
import 'package:suscart_app/core/theme/app_typography.dart';
import 'package:suscart_app/core/utils/date_formatter.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';

import 'package:suscart_app/features/schedule/presentation/providers/cutoff_ticker_provider.dart';

class DateSelectorStrip extends ConsumerStatefulWidget {
  const DateSelectorStrip({super.key});

  @override
  ConsumerState<DateSelectorStrip> createState() => _DateSelectorStripState();
}

class _DateSelectorStripState extends ConsumerState<DateSelectorStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final availableDates = ref.read(scheduleDatesProvider);
    final selectedDate = ref.read(selectedDateProvider);
    if (selectedDate == null) return;

    final idx = availableDates.indexOf(selectedDate);
    if (idx != -1) {
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = (idx * 66.0) - (screenWidth / 2) + 33.0;
      final clampedOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      if (animate) {
        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(clampedOffset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableDates = ref.watch(scheduleDatesProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final scheduleData = ref.watch(scheduleNotifierProvider).data;

    // Listen to selectedDate changes to smoothly auto-scroll
    ref.listen<String?>(selectedDateProvider, (prev, next) {
      if (next != null && next != prev) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelectedDate(animate: true);
        });
      }
    });

    if (availableDates.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        controller: _scrollController,
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

          // Check if date is completed / past / cutoff passed
          final ordersForDate = scheduleData?.orders.where((o) => o.deliveryDate == dateStr).toList() ?? [];
          final isAllOrdersPassed = ordersForDate.isNotEmpty && ordersForDate.every((o) => o.isCutoffPassed);
          final isCutoffPassed = isTargetDateCutoffPassed(dateStr) || isAllOrdersPassed;

          final Color dotColor;
          if (isCutoffPassed) {
            dotColor = isSelected ? AppColors.tertiaryAccent : const Color(0xFFE57373);
          } else {
            dotColor = isSelected ? AppColors.secondaryFixed : AppColors.secondaryLight.withOpacity(0.85);
          }

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
                          : (isCutoffPassed
                              ? AppColors.onSurfaceVariant.withOpacity(0.65)
                              : AppColors.onSurfaceVariant),
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
                            : (isCutoffPassed
                                ? AppColors.onSurface.withOpacity(0.65)
                                : AppColors.onSurface),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Status Dot: Red for locked/completed dates, Green for active
                  Container(
                    width: isSelected ? 7 : 5,
                    height: isSelected ? 7 : 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
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
