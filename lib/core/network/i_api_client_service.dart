// ─── IApiClientService ────────────────────────────────────────────────────────
// Contract every API client must satisfy.
//
// Implementations:
//   AppApiClientService  — real Dio-based HTTP client
//   MockApiClientService — in-memory stubs for testing / Storybook
//   Any custom client    — extend AppApiClientService OR implement this
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/network/app_api_request.dart';

abstract interface class IApiClientService {
  // ─── Core ────────────────────────────────────────────────────────────────

  /// Universal request method — all convenience wrappers delegate here.
  Future<AppApiResult<T>> request<T>(AppApiRequest<T> req);

  // ─── Convenience wrappers ────────────────────────────────────────────────

  Future<AppApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    bool isAuth,
    bool canCache,
    String? cacheKey,
    Duration cacheDuration,
    bool canRetry,
    T Function(dynamic)? fromJson,
    String? tag,
  });

  Future<AppApiResult<T>> post<T>(
    String path, {
    dynamic body,
    bool isAuth,
    bool canRetry,
    Map<String, String>? extraHeaders,
    T Function(dynamic)? fromJson,
    String? tag,
  });

  Future<AppApiResult<T>> put<T>(
    String path, {
    dynamic body,
    bool isAuth,
    bool canRetry,
    T Function(dynamic)? fromJson,
    String? tag,
  });

  Future<AppApiResult<T>> patch<T>(
    String path, {
    dynamic body,
    bool isAuth,
    bool canRetry,
    T Function(dynamic)? fromJson,
    String? tag,
  });

  Future<AppApiResult<T>> delete<T>(
    String path, {
    bool isAuth,
    bool canRetry,
    T Function(dynamic)? fromJson,
    String? tag,
  });

  Future<AppApiResult<T>> upload<T>(
    String path, {
    required FormData formData,
    bool isAuth,
    bool canRetry,
    ProgressCallback? onSendProgress,
    T Function(dynamic)? fromJson,
    String? tag,
  });

  // ─── Config ──────────────────────────────────────────────────────────────

  void updateBaseUrl(String url);
  void updateHeaders(Map<String, String> headers);
  void removeHeader(String key);
  void updateTimeout({Duration? connect, Duration? receive, Duration? send});
  void setAuthToken(String token);
  void clearAuthToken();
  void clearCache();
  void clearCacheKey(String key);
}
