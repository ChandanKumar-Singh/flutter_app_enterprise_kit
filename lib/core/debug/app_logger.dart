import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  late final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
  );

  void v(String msg) => _logger.t(msg);
  void d(String msg) => _logger.d(msg);
  void i(String msg) => _logger.i(msg);
  void w(String msg) => _logger.w(msg);
  void e(String msg, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(msg, error: error, stackTrace: stackTrace);
  void wtf(String msg) => _logger.f(msg);

  static void log(String msg) => instance.d(msg);
}
