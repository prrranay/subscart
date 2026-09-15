import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/models/schedule_response_model.dart';
import '../../data/models/scheduled_order_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/meal_model.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../domain/enums/meal_slot.dart';
import '../../domain/enums/order_status.dart';

/// Repository Provider
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

/// Selected Date State Provider (YYYY-MM-DD)
final selectedDateProvider = StateProvider<String?>((ref) => null);

/// Mutation Action Feedback Record for UI Snackbars
class MutationFeedback {
  final String message;
  final String orderId;
  final bool isSuccess;
  final bool canUndo;

  const MutationFeedback({
    required this.message,
    required this.orderId,
    required this.isSuccess,
    this.canUndo = true,
  });
}

/// Last Mutation Feedback State Provider
final mutationFeedbackProvider = StateProvider<MutationFeedback?>((ref) => null);

/// Schedule State
class ScheduleState {
  final bool isLoading;
  final bool isMutating;
  final String? mutatingOrderId;
  final ScheduleResponseModel? data;
  final String? errorMessage;

  const ScheduleState({
    this.isLoading = false,
    this.isMutating = false,
    this.mutatingOrderId,
    this.data,
    this.errorMessage,
  });

  ScheduleState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? mutatingOrderId,
    ScheduleResponseModel? data,
    String? errorMessage,
  }) {
    return ScheduleState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      mutatingOrderId: mutatingOrderId ?? this.mutatingOrderId,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

/// Schedule State Notifier
class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleRepository _repository;
  final Ref _ref;

  ScheduleNotifier(this._repository, this._ref) : super(const ScheduleState(isLoading: true)) {
    loadSchedule();
  }

  /// Initial & Refresh Load
  Future<void> loadSchedule() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final scheduleData = await _repository.getSchedule();

      // If no date selected yet, pick the first available date or today
      if (_ref.read(selectedDateProvider) == null && scheduleData.orders.isNotEmpty) {
        _ref.read(selectedDateProvider.notifier).state = scheduleData.orders.first.deliveryDate;
      }

      state = state.copyWith(isLoading: false, data: scheduleData, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AppException ? e.message : e.toString(),
      );
    }
  }

  /// Optimistic Skip Order
  Future<bool> skipOrder(String orderId) async {
    final currentData = state.data;
    if (currentData == null) return false;

    final targetIndex = currentData.orders.indexWhere((o) => o.id == orderId);
    if (targetIndex == -1) return false;

    final originalOrder = currentData.orders[targetIndex];

    // Optimistic Update: Immediately mark order as skipped in local state
    final updatedOrder = originalOrder.copyWith(
      status: OrderStatus.skipped,
      previousStatus: originalOrder.status,
    );
    final updatedOrders = List<ScheduledOrderModel>.from(currentData.orders);
    updatedOrders[targetIndex] = updatedOrder;

    state = state.copyWith(
      isMutating: true,
      mutatingOrderId: orderId,
      data: ScheduleResponseModel(
        user: currentData.user,
        subscription: currentData.subscription,
        cutoffConfig: currentData.cutoffConfig,
        orders: updatedOrders,
      ),
    );

    try {
      // Backend authoritative mutation
      final backendOrder = await _repository.skipOrder(orderId);

      // Apply backend confirmed response
      final confirmedOrders = List<ScheduledOrderModel>.from(state.data!.orders);
      final idx = confirmedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        confirmedOrders[idx] = backendOrder;
      }

      state = state.copyWith(
        isMutating: false,
        mutatingOrderId: null,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: currentData.subscription,
          cutoffConfig: currentData.cutoffConfig,
          orders: confirmedOrders,
        ),
      );

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: 'Meal skipped successfully.',
        orderId: orderId,
        isSuccess: true,
        canUndo: true,
      );
      return true;
    } catch (e) {
      // Rollback on failure
      final rollbackOrders = List<ScheduledOrderModel>.from(state.data!.orders);
      final idx = rollbackOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        rollbackOrders[idx] = originalOrder;
      }

      final errorMsg = e is AppException ? e.message : 'Failed to skip meal.';
      state = state.copyWith(
        isMutating: false,
        mutatingOrderId: null,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: currentData.subscription,
          cutoffConfig: currentData.cutoffConfig,
          orders: rollbackOrders,
        ),
      );

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: errorMsg,
        orderId: orderId,
        isSuccess: false,
      );
      return false;
    }
  }

  /// Optimistic Swap Meal
  Future<bool> swapMeal(String orderId, MealModel newMeal) async {
    final currentData = state.data;
    if (currentData == null) return false;

    final targetIndex = currentData.orders.indexWhere((o) => o.id == orderId);
    if (targetIndex == -1) return false;

    final originalOrder = currentData.orders[targetIndex];

    // Optimistic Update
    final updatedOrder = originalOrder.copyWith(
      meal: newMeal,
      status: OrderStatus.swapped,
      previousMealId: originalOrder.meal?.id,
      previousStatus: originalOrder.status,
    );
    final updatedOrders = List<ScheduledOrderModel>.from(currentData.orders);
    updatedOrders[targetIndex] = updatedOrder;

    state = state.copyWith(
      isMutating: true,
      mutatingOrderId: orderId,
      data: ScheduleResponseModel(
        user: currentData.user,
        subscription: currentData.subscription,
        cutoffConfig: currentData.cutoffConfig,
        orders: updatedOrders,
      ),
    );

    try {
      final backendOrder = await _repository.swapMeal(orderId, newMeal.id);
      final confirmedOrders = List<ScheduledOrderModel>.from(state.data!.orders);
      final idx = confirmedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        confirmedOrders[idx] = backendOrder;
      }

      state = state.copyWith(
        isMutating: false,
        mutatingOrderId: null,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: currentData.subscription,
          cutoffConfig: currentData.cutoffConfig,
          orders: confirmedOrders,
        ),
      );

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: 'Swapped to ${newMeal.name}.',
        orderId: orderId,
        isSuccess: true,
        canUndo: true,
      );
      return true;
    } catch (e) {
      // Rollback
      final rollbackOrders = List<ScheduledOrderModel>.from(state.data!.orders);
      final idx = rollbackOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        rollbackOrders[idx] = originalOrder;
      }

      final errorMsg = e is AppException ? e.message : 'Failed to swap meal.';
      state = state.copyWith(
        isMutating: false,
        mutatingOrderId: null,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: currentData.subscription,
          cutoffConfig: currentData.cutoffConfig,
          orders: rollbackOrders,
        ),
      );

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: errorMsg,
        orderId: orderId,
        isSuccess: false,
      );
      return false;
    }
  }

  /// Optimistic Move Order
  Future<bool> moveOrder(String orderId, String targetDate, MealSlot targetSlot) async {
    final currentData = state.data;
    if (currentData == null) return false;

    final targetIndex = currentData.orders.indexWhere((o) => o.id == orderId);
    if (targetIndex == -1) return false;

    final originalOrder = currentData.orders[targetIndex];

    // Optimistic Update
    final updatedOrder = originalOrder.copyWith(
      deliveryDate: targetDate,
      slot: targetSlot,
      status: OrderStatus.moved,
      previousDate: originalOrder.deliveryDate,
      previousSlot: originalOrder.slot,
      previousStatus: originalOrder.status,
    );
    final updatedOrders = List<ScheduledOrderModel>.from(currentData.orders);
    updatedOrders[targetIndex] = updatedOrder;

    state = state.copyWith(
      isMutating: true,
      mutatingOrderId: orderId,
      data: ScheduleResponseModel(
        user: currentData.user,
        subscription: currentData.subscription,
        cutoffConfig: currentData.cutoffConfig,
        orders: updatedOrders,
      ),
    );

    try {
      final backendOrder = await _repository.moveOrder(orderId, targetDate, targetSlot);
      final confirmedOrders = List<ScheduledOrderModel>.from(state.data!.orders);
      final idx = confirmedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        confirmedOrders[idx] = backendOrder;
      }

      state = state.copyWith(
        isMutating: false,
        mutatingOrderId: null,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: currentData.subscription,
          cutoffConfig: currentData.cutoffConfig,
          orders: confirmedOrders,
        ),
      );

      // Shift selected date to the new destination date
      _ref.read(selectedDateProvider.notifier).state = targetDate;

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: 'Moved to $targetDate (${targetSlot.name}).',
        orderId: orderId,
        isSuccess: true,
        canUndo: true,
      );
      return true;
    } catch (e) {
      // Rollback
      final rollbackOrders = List<ScheduledOrderModel>.from(state.data!.orders);
      final idx = rollbackOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        rollbackOrders[idx] = originalOrder;
      }

      final errorMsg = e is AppException ? e.message : 'Failed to move meal.';
      state = state.copyWith(
        isMutating: false,
        mutatingOrderId: null,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: currentData.subscription,
          cutoffConfig: currentData.cutoffConfig,
          orders: rollbackOrders,
        ),
      );

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: errorMsg,
        orderId: orderId,
        isSuccess: false,
      );
      return false;
    }
  }

  /// Optimistic Reschedule Order
  Future<bool> rescheduleOrder(String orderId, String targetDate) async {
    final currentData = state.data;
    if (currentData == null) return false;

    final targetIndex = currentData.orders.indexWhere((o) => o.id == orderId);
    if (targetIndex == -1) return false;

    final originalOrder = currentData.orders[targetIndex];

    // Optimistic Update
    final updatedOrder = originalOrder.copyWith(
      deliveryDate: targetDate,
      status: OrderStatus.rescheduled,
      previousDate: originalOrder.deliveryDate,
      previousStatus: originalOrder.status,
    );
    final updatedOrders = List<ScheduledOrderModel>.from(currentData.orders);
    updatedOrders[targetIndex] = updatedOrder;

    state = state.copyWith(
      isMutating: true,
      mutatingOrderId: orderId,
      data: ScheduleResponseModel(
        user: currentData.user,
        subscription: currentData.subscription,
        cutoffConfig: currentData.cutoffConfig,
        orders: updatedOrders,
      ),
    );

    try {
      final backendOrder = await _repository.rescheduleOrder(orderId, targetDate);
      final confirmedOrders = List<ScheduledOrderModel>.from(state.data!.orders);
      final idx = confirmedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        confirmedOrders[idx] = backendOrder;
      }

      state = state.copyWith(
        isMutating: false,
        mutatingOrderId: null,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: currentData.subscription,
          cutoffConfig: currentData.cutoffConfig,
          orders: confirmedOrders,
        ),
      );

      _ref.read(selectedDateProvider.notifier).state = targetDate;

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: 'Rescheduled to $targetDate.',
        orderId: orderId,
        isSuccess: true,
        canUndo: true,
      );
      return true;
    } catch (e) {
      // Rollback
      final rollbackOrders = List<ScheduledOrderModel>.from(state.data!.orders);
      final idx = rollbackOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        rollbackOrders[idx] = originalOrder;
      }

      final errorMsg = e is AppException ? e.message : 'Failed to reschedule.';
      state = state.copyWith(
        isMutating: false,
        mutatingOrderId: null,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: currentData.subscription,
          cutoffConfig: currentData.cutoffConfig,
          orders: rollbackOrders,
        ),
      );

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: errorMsg,
        orderId: orderId,
        isSuccess: false,
      );
      return false;
    }
  }

  /// Perform Functional Backend Undo
  Future<void> undoOrder(String orderId) async {
    state = state.copyWith(isMutating: true, mutatingOrderId: orderId);
    try {
      final restoredOrder = await _repository.undoOrder(orderId);
      final currentData = state.data!;
      final updatedOrders = List<ScheduledOrderModel>.from(currentData.orders);
      final idx = updatedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        updatedOrders[idx] = restoredOrder;
      }

      state = state.copyWith(
        isMutating: false,
        mutatingOrderId: null,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: currentData.subscription,
          cutoffConfig: currentData.cutoffConfig,
          orders: updatedOrders,
        ),
      );

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: 'Action undone successfully.',
        orderId: orderId,
        isSuccess: true,
        canUndo: false,
      );
    } catch (e) {
      final errorMsg = e is AppException ? e.message : 'Failed to undo action.';
      state = state.copyWith(isMutating: false, mutatingOrderId: null);
      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: errorMsg,
        orderId: orderId,
        isSuccess: false,
      );
    }
  }

  /// Toggle Subscription Pause/Resume
  Future<void> togglePauseSubscription() async {
    final currentData = state.data;
    if (currentData == null) return;

    final isCurrentlyPaused = currentData.subscription.isPaused;
    final newPausedState = !isCurrentlyPaused;

    state = state.copyWith(isMutating: true);
    try {
      final updatedSub = await _repository.setSubscriptionPauseStatus(newPausedState);
      state = state.copyWith(
        isMutating: false,
        data: ScheduleResponseModel(
          user: currentData.user,
          subscription: updatedSub,
          cutoffConfig: currentData.cutoffConfig,
          orders: currentData.orders,
        ),
      );

      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: newPausedState
            ? 'Subscription paused. Meal edits are locked.'
            : 'Subscription resumed. Meal edits are unlocked.',
        orderId: '',
        isSuccess: true,
        canUndo: false,
      );
    } catch (e) {
      final errorMsg = e is AppException ? e.message : 'Failed to update subscription.';
      state = state.copyWith(isMutating: false);
      _ref.read(mutationFeedbackProvider.notifier).state = MutationFeedback(
        message: errorMsg,
        orderId: '',
        isSuccess: false,
      );
    }
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return ScheduleNotifier(repository, ref);
});

/// Provider for orders of the currently selected date
final selectedDateOrdersProvider = Provider<List<ScheduledOrderModel>>((ref) {
  final scheduleState = ref.watch(scheduleNotifierProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  if (scheduleState.data == null || selectedDate == null) {
    return [];
  }

  return scheduleState.data!.orders
      .where((order) => order.deliveryDate == selectedDate)
      .toList();
});

/// Provider for distinct schedule dates (contiguous sequence across the cycle)
final scheduleDatesProvider = Provider<List<String>>((ref) {
  final scheduleState = ref.watch(scheduleNotifierProvider);
  if (scheduleState.data == null || scheduleState.data!.orders.isEmpty) return [];

  final rawDates = scheduleState.data!.orders.map((o) => o.deliveryDate).toList()..sort();
  if (rawDates.isEmpty) return [];

  final minDate = DateTime.tryParse(rawDates.first) ?? DateTime.now();
  final maxDate = DateTime.tryParse(rawDates.last) ?? minDate.add(const Duration(days: 13));

  // Generate contiguous sequence of every single date between minDate and maxDate
  final List<String> contiguousDates = [];
  var current = DateTime(minDate.year, minDate.month, minDate.day);
  final end = DateTime(maxDate.year, maxDate.month, maxDate.day);

  while (!current.isAfter(end)) {
    final yyyy = current.year.toString().padLeft(4, '0');
    final mm = current.month.toString().padLeft(2, '0');
    final dd = current.day.toString().padLeft(2, '0');
    contiguousDates.add('$yyyy-$mm-$dd');
    current = current.add(const Duration(days: 1));
  }

  return contiguousDates;
});
