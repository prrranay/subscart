import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../errors/app_exception.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('🌐 [DIO REQ] ${options.method} ${options.uri}');
            if (options.data != null) {
              print('📦 [BODY] ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ [DIO RES] ${response.statusCode} ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            print('❌ [DIO ERR] ${e.response?.statusCode} ${e.requestOptions.uri}');
            print('❌ [RES BODY] ${e.response?.data}');
          }

          final appException = _handleDioError(e);
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: appException,
              response: e.response,
              type: e.type,
            ),
          );
        },
      ),
    );
  }

  Dio get client => _dio;

  AppException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AppException(
        message: 'Connection timed out. Please check your network.',
        code: 'TIMEOUT',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return AppException(
        message: 'Unable to connect to the server. Please verify backend is running.',
        code: 'CONNECTION_ERROR',
      );
    }

    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      final message = data['message'] ?? 'An unexpected error occurred.';
      final code = data['code'] ?? 'API_ERROR';
      final cutoffAt = data['cutoffAt']?.toString();
      final statusCode = error.response?.statusCode;

      return AppException(
        message: message is List ? message.join(', ') : message.toString(),
        code: code.toString(),
        statusCode: statusCode,
        cutoffAt: cutoffAt,
      );
    }

    return AppException(
      message: error.message ?? 'Network error occurred.',
      code: 'UNKNOWN_NETWORK_ERROR',
      statusCode: error.response?.statusCode,
    );
  }
}
