import 'package:modular_pos/core/config/app_env.dart';

class UserErrorMessage {
  static const generic = 'Oops, something went wrong.';

  static String build({
    String? context,
    Object? error,
  }) {
    final prefix =
        (context != null && context.trim().isNotEmpty) ? context.trim() : null;
    final base = prefix == null ? generic : '$prefix. $generic';

    if (error == null || !AppEnv.showDebugErrors) return base;
    return '$base\n\nDetails: $error';
  }
}

