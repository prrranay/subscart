class ApiErrorModel {
  final int statusCode;
  final String code;
  final String message;
  final String? cutoffAt;

  const ApiErrorModel({
    required this.statusCode,
    required this.code,
    required this.message,
    this.cutoffAt,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      statusCode: json['statusCode'] ?? 400,
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? 'An error occurred.',
      cutoffAt: json['cutoffAt']?.toString(),
    );
  }
}
