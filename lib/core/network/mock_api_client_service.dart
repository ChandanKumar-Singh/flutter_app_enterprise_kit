// ─── MockApiClientService ─────────────────────────────────────────────────────
// In-memory IApiClientService for testing, Storybook, CI, and offline demos.
//
// Usage in tests:
//   final mock = MockApiClientService()
//     ..stub('users/1', {'id': 1, 'name': 'Alice'})
//     ..stubError('users/2', AppApiError.notFound)
//     ..stubList('posts', [{'id': 1, 'title': 'Hello'}]);
//
//   final result = await mock.get<User>(
//     'users/1',
//     fromJson: User.fromJson,
//   );
//   expect(result.isSuccess, true);
//   expect(result.dataOrNull?.name, 'Alice');
//
// Usage in showcase:
//   AppApiServiceRegistry.register('mock', MockApiClientService(
//     delay: Duration(milliseconds: 800),
//   ));
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/network/app_api_request.dart';
import 'package:enterprise_kit/core/network/i_api_client_service.dart';

// ─── Stub entry ───────────────────────────────────────────────────────────────

sealed class _Stub {}

class _DataStub extends _Stub {
  final dynamic data;
  final int statusCode;
  _DataStub(this.data, {this.statusCode = 200});
}

class _ErrorStub extends _Stub {
  final AppApiError error;
  final String? message;
  final int? statusCode;
  _ErrorStub(this.error, {this.message, this.statusCode});
}

// ─── Service ──────────────────────────────────────────────────────────────────

class MockApiClientService implements IApiClientService {
  /// Simulated network latency.
  final Duration delay;

  /// When true every request fails with [AppApiError.noConnectivity].
  bool isOffline;

  /// When set, every request fails with this error (useful for global failure testing).
  AppApiError? globalError;

  final _stubs     = <String, _Stub>{};
  final _callLog   = <_CallRecord>[];

  MockApiClientService({
    this.delay     = const Duration(milliseconds: 120),
    this.isOffline = false,
    this.globalError,
  });

  // ─── Stub registration ────────────────────────────────────────────────────

  /// Register a successful response for [path].
  MockApiClientService stub(
    String path,
    dynamic data, {
    int statusCode = 200,
  }) {
    _stubs[_normalise(path)] = _DataStub(data, statusCode: statusCode);
    return this;
  }

  /// Register a List response — shorthand for stub(path, [...]).
  MockApiClientService stubList(String path, List<dynamic> data) =>
      stub(path, data);

  /// Register an error response for [path].
  MockApiClientService stubError(
    String path,
    AppApiError error, {
    String? message,
    int? statusCode,
  }) {
    _stubs[_normalise(path)] = _ErrorStub(
      error,
      message:    message    ?? error.label,
      statusCode: statusCode ?? _defaultCode(error),
    );
    return this;
  }

  /// Remove a stub so the service returns "not found" for that path.
  void removeStub(String path) => _stubs.remove(_normalise(path));

  /// Clear all stubs.
  void clearStubs() => _stubs.clear();

  // ─── Call inspection (useful in tests) ────────────────────────────────────

  List<_CallRecord> get callLog => List.unmodifiable(_callLog);

  int callCount(String path) =>
      _callLog.where((r) => r.path == _normalise(path)).length;

  bool wasCalled(String path) => callCount(path) > 0;

  void clearLog() => _callLog.clear();

  // ─── IApiClientService ────────────────────────────────────────────────────

  @override
  Future<AppApiResult<T>> request<T>(AppApiRequest<T> req) async {
    await Future.delayed(delay);

    final normPath = _normalise(req.path);
    _callLog.add(_CallRecord(req.method.httpMethod, normPath));

    // Global offline / error overrides
    if (isOffline) {
      return AppApiFailure<T>(
        message: 'Device offline (mock)',
        error:   AppApiError.noConnectivity,
      );
    }
    if (globalError != null) {
      return AppApiFailure<T>(
        message: globalError!.label,
        error:   globalError!,
      );
    }

    final stub = _stubs[normPath];
    if (stub == null) {
      return AppApiFailure<T>(
        message:    'No stub registered for "$normPath"',
        error:      AppApiError.notFound,
        statusCode: 404,
      );
    }

    return switch (stub) {
      _DataStub s => _resolve<T>(s.data, req.fromJson, s.statusCode),
      _ErrorStub s => AppApiFailure<T>(
          message:    s.message ?? s.error.label,
          error:      s.error,
          statusCode: s.statusCode,
        ),
    };
  }

  @override
  Future<AppApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    bool isAuth           = true,
    bool canCache         = false,
    String? cacheKey,
    Duration cacheDuration = const Duration(minutes: 5),
    bool canRetry          = true,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:     path,
        method:   ApiMethod.get,
        fromJson: fromJson,
        tag:      tag,
      ));

  @override
  Future<AppApiResult<T>> post<T>(
    String path, {
    dynamic body,
    bool isAuth   = true,
    bool canRetry = false,
    Map<String, String>? extraHeaders,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:     path,
        method:   ApiMethod.post,
        body:     body,
        fromJson: fromJson,
        tag:      tag,
      ));

  @override
  Future<AppApiResult<T>> put<T>(
    String path, {
    dynamic body,
    bool isAuth   = true,
    bool canRetry = false,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:     path,
        method:   ApiMethod.put,
        body:     body,
        fromJson: fromJson,
        tag:      tag,
      ));

  @override
  Future<AppApiResult<T>> patch<T>(
    String path, {
    dynamic body,
    bool isAuth   = true,
    bool canRetry = false,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:     path,
        method:   ApiMethod.patch,
        body:     body,
        fromJson: fromJson,
        tag:      tag,
      ));

  @override
  Future<AppApiResult<T>> delete<T>(
    String path, {
    bool isAuth   = true,
    bool canRetry = false,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:     path,
        method:   ApiMethod.delete,
        fromJson: fromJson,
        tag:      tag,
      ));

  @override
  Future<AppApiResult<T>> upload<T>(
    String path, {
    required FormData formData,
    bool isAuth              = true,
    bool canRetry            = false,
    ProgressCallback? onSendProgress,
    T Function(dynamic)? fromJson,
    String? tag,
  }) =>
      request<T>(AppApiRequest<T>(
        path:            path,
        method:          ApiMethod.multipart,
        formData:        formData,
        onSendProgress:  onSendProgress,
        fromJson:        fromJson,
        tag:             tag,
      ));

  // ─── Config no-ops (mock has no real transport) ───────────────────────────

  @override void updateBaseUrl(String url) {}
  @override void updateHeaders(Map<String, String> h) {}
  @override void removeHeader(String key) {}
  @override void updateTimeout({Duration? connect, Duration? receive, Duration? send}) {}
  @override void setAuthToken(String token) {}
  @override void clearAuthToken() {}
  @override void clearCache() {}
  @override void clearCacheKey(String key) {}

  // ─── Helpers ──────────────────────────────────────────────────────────────

  AppApiResult<T> _resolve<T>(dynamic raw, T Function(dynamic)? fromJson, int code) {
    try {
      final data = fromJson != null ? fromJson(raw) : raw as T;
      return AppApiSuccess<T>(data: data, statusCode: code, elapsedMs: delay.inMilliseconds);
    } catch (e) {
      return AppApiFailure<T>(message: e.toString(), error: AppApiError.parse);
    }
  }

  String _normalise(String path) =>
      path.replaceAll(RegExp(r'^/+|/+$'), ''); // strip leading/trailing slashes

  int _defaultCode(AppApiError e) => switch (e) {
        AppApiError.unauthorized  => 401,
        AppApiError.forbidden     => 403,
        AppApiError.notFound      => 404,
        AppApiError.unprocessable => 422,
        AppApiError.serverError   => 500,
        _                         => 400,
      };
}

class _CallRecord {
  final String method;
  final String path;
  final DateTime time;
  _CallRecord(this.method, this.path) : time = DateTime.now();
}
