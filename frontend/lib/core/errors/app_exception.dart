class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final String? cutoffAt;

  AppException({
    required this.message,
    this.code,
    this.statusCode,
    this.cutoffAt,
  });

  @override
  String toString() => message;
}
