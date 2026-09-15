import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  /// Automatically resolves base URL depending on device platform
  /// Configured for local network IP: http://192.168.1.36:3000
  /// Override with: --dart-define=API_BASE_URL=http://your-ip:3000
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    return 'http://192.168.1.36:3000';
  }

  // Endpoints
  static const String schedule = '/schedule';
  static const String subscription = '/subscription';
  static const String pauseSubscription = '/subscription/pause';
  static const String meals = '/meals';

  static String skipOrder(String orderId) => '/schedule/$orderId/skip';
  static String swapMeal(String orderId) => '/schedule/$orderId/swap';
  static String moveOrder(String orderId) => '/schedule/$orderId/move';
  static String rescheduleOrder(String orderId) => '/schedule/$orderId/reschedule';
  static String undoOrder(String orderId) => '/schedule/$orderId/undo';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
