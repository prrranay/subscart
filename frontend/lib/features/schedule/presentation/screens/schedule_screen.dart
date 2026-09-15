import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suscart_app/core/theme/app_colors.dart';
import 'package:suscart_app/core/theme/app_typography.dart';
import 'package:suscart_app/features/schedule/domain/enums/meal_slot.dart';
import 'package:suscart_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/subscription_header.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/date_selector_strip.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/slot_section.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/bottom_nav_bar.dart';
import 'package:suscart_app/features/schedule/presentation/widgets/custom_snackbar.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Listen to mutation feedback for floating Snackbars with Undo
    ref.listen<MutationFeedback?>(mutationFeedbackProvider, (previous, next) {
      if (next != null) {
        CustomSnackBar.show(
          context,
          message: next.message,
          isSuccess: next.isSuccess,
          onUndo: (next.isSuccess && next.canUndo && next.orderId.isNotEmpty)
              ? () {
                  ref
                      .read(scheduleNotifierProvider.notifier)
                      .undoOrder(next.orderId);
                }
              : null,
        );
      }
    });

    final scheduleState = ref.watch(scheduleNotifierProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedOrders = ref.watch(selectedDateOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Navigation back pressed.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.inverseOnSurface),
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Healthy Lab',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Row(
              children: [
                Text(
                  'Active Plan',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppColors.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    scheduleState.data?.subscription.name ?? 'Healthy Plan • 6 Days',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () {
              ref.read(scheduleNotifierProvider.notifier).loadSchedule();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _navIndex,
        onTabSelected: (idx) {
          setState(() {
            _navIndex = idx;
          });
        },
      ),
      body: Builder(
        builder: (context) {
          if (scheduleState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryContainer,
              ),
            );
          }

          if (scheduleState.errorMessage != null && scheduleState.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load meal schedule',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scheduleState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        ref.read(scheduleNotifierProvider.notifier).loadSchedule();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.secondary,
            onRefresh: () async {
              await ref.read(scheduleNotifierProvider.notifier).loadSchedule();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Subscription & Cycle Header
                const SubscriptionHeader(),

                const SizedBox(height: 14),

                // 2. Horizontal Date Selector Strip
                const DateSelectorStrip(),

                const SizedBox(height: 16),

                // 3. Slot Sections for the selected date
                if (selectedDate != null) ...[
                  // Breakfast Slot
                  _buildSlotView(MealSlot.breakfast, selectedOrders, selectedDate),

                  // Lunch Slot
                  _buildSlotView(MealSlot.lunch, selectedOrders, selectedDate),

                  // Dinner Slot
                  _buildSlotView(MealSlot.dinner, selectedOrders, selectedDate),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Please select a date from the calendar.'),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotView(
    MealSlot slot,
    List<dynamic> orders,
    String dateStr,
  ) {
    final matchingOrder = orders.cast<dynamic>().firstWhere(
          (o) => o.slot == slot,
          orElse: () => null,
        );

    return SlotSection(
      slot: slot,
      order: matchingOrder,
      dateStr: dateStr,
    );
  }
}
