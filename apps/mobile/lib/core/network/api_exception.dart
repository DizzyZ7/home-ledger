import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final data = exception.response?.data;
    final detail = data is Map<String, dynamic> ? data['detail'] : null;
    final message = detail is Map<String, dynamic> ? detail['message'] : null;
    if (message is String && message.isNotEmpty) {
      return ApiException(message, statusCode: statusCode);
    }
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.connectionError) {
      return const ApiException('Network connection is unavailable.');
    }
    return ApiException('Request failed.', statusCode: statusCode);
  }

  @override
  String toString() => message;
}
