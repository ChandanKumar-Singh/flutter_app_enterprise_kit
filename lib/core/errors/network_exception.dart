import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const NetworkException({required this.message, this.statusCode, this.data});

  factory NetworkException.fromDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout => const NetworkException(message: 'Connection timeout'),
      DioExceptionType.receiveTimeout => const NetworkException(message: 'Receive timeout'),
      DioExceptionType.sendTimeout => const NetworkException(message: 'Send timeout'),
      DioExceptionType.connectionError => NetworkException(
          message: e.message ?? 'Connection error'),
      DioExceptionType.badResponse => NetworkException(
          message: _parseErrorMessage(e.response),
          statusCode: e.response?.statusCode,
          data: e.response?.data),
      _ => NetworkException(message: e.message ?? 'Unknown error'),
    };
  }

  static String _parseErrorMessage(Response? r) {
    if (r == null) return 'Server error';
    if (r.data is Map) return r.data['message'] ?? r.data['error'] ?? 'Server error';
    return 'HTTP ${r.statusCode}';
  }

  @override
  String toString() => 'NetworkException($statusCode): $message';
}
