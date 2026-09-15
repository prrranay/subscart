import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/schedule_response_model.dart';
import '../models/scheduled_order_model.dart';
import '../models/meal_model.dart';
import '../models/subscription_model.dart';
import '../../domain/enums/meal_slot.dart';

class ScheduleRepository {
  final ApiClient _apiClient;

  ScheduleRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches schedule for the given date range
  Future<ScheduleResponseModel> getSchedule({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.client.get(
        ApiConstants.schedule,
        queryParameters: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );
      return ScheduleResponseModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException(message: e.message ?? 'Failed to load schedule.');
    }
  }

  /// Skip a meal order
  Future<ScheduledOrderModel> skipOrder(String orderId) async {
    try {
      final response = await _apiClient.client.patch(
        ApiConstants.skipOrder(orderId),
      );
      return ScheduledOrderModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException(message: e.message ?? 'Failed to skip meal.');
    }
  }

  /// Swap a meal order with an alternative meal
  Future<ScheduledOrderModel> swapMeal(String orderId, String newMealId) async {
    try {
      final response = await _apiClient.client.patch(
        ApiConstants.swapMeal(orderId),
        data: {'mealId': newMealId},
      );
      return ScheduledOrderModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException(message: e.message ?? 'Failed to swap meal.');
    }
  }

  /// Move a meal order to a new date and slot
  Future<ScheduledOrderModel> moveOrder(
    String orderId,
    String targetDate,
    MealSlot targetSlot,
  ) async {
    try {
      final response = await _apiClient.client.patch(
        ApiConstants.moveOrder(orderId),
        data: {
          'date': targetDate,
          'slot': targetSlot.name,
        },
      );
      return ScheduledOrderModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException(message: e.message ?? 'Failed to move meal.');
    }
  }

  /// Reschedule a meal order to a new date (preserving slot)
  Future<ScheduledOrderModel> rescheduleOrder(
    String orderId,
    String targetDate,
  ) async {
    try {
      final response = await _apiClient.client.patch(
        ApiConstants.rescheduleOrder(orderId),
        data: {'date': targetDate},
      );
      return ScheduledOrderModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException(message: e.message ?? 'Failed to reschedule meal.');
    }
  }

  /// Undo the last mutation on the order
  Future<ScheduledOrderModel> undoOrder(String orderId) async {
    try {
      final response = await _apiClient.client.patch(
        ApiConstants.undoOrder(orderId),
      );
      return ScheduledOrderModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException(message: e.message ?? 'Failed to undo action.');
    }
  }

  /// Pause or resume subscription
  Future<SubscriptionModel> setSubscriptionPauseStatus(bool paused) async {
    try {
      final response = await _apiClient.client.post(
        ApiConstants.pauseSubscription,
        data: {'paused': paused},
      );
      return SubscriptionModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException(message: e.message ?? 'Failed to update subscription.');
    }
  }

  /// Get list of available meals
  Future<List<MealModel>> getAvailableMeals() async {
    try {
      final response = await _apiClient.client.get(ApiConstants.meals);
      final list = response.data['data'] as List<dynamic>;
      return list.map((e) => MealModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw AppException(message: e.message ?? 'Failed to fetch meals.');
    }
  }
}
