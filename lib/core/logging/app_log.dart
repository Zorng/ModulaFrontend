import 'package:flutter/foundation.dart';

/// Lightweight app logger.
///
/// - Debug builds: logs via `debugPrint`/`debugPrintStack`.
/// - Release/profile builds: no-op (keeps production console clean).
///
/// This is intentionally minimal; if we later adopt a full logging solution,
/// we can route these methods to it without changing call sites.
class AppLog {
  const AppLog._();

  static void d(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    if (error != null) {
      debugPrint('$message: $error');
    } else {
      debugPrint(message);
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

