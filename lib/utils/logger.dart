import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: true,
  ),
);

void logInfo(String message) => _logger.i(message);
void logDebug(String message) => _logger.d(message);
void logWarning(String message) => _logger.w(message);
void logError(String message, [dynamic error, StackTrace? stackTrace]) => 
    _logger.e(message, error: error, stackTrace: stackTrace);

void logBusiness(String action, [Map<String, dynamic>? data]) {
  _logger.i('[BUSINESS] $action\n${data ?? ''}');
}
