import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static bool get showDebugErrors {
    if (kReleaseMode) return false;
    return _readBool('SHOW_DEBUG_ERRORS', defaultValue: false);
  }

  static bool _readBool(String key, {required bool defaultValue}) {
    final raw = dotenv.env[key];
    if (raw == null) return defaultValue;
    switch (raw.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'y':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'n':
      case 'off':
        return false;
      default:
        return defaultValue;
    }
  }
}

