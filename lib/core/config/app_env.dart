import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static bool get showDebugErrors {
    if (kReleaseMode) return false;
    return _readBool('SHOW_DEBUG_ERRORS', defaultValue: false);
  }

  static bool get useMockAttendanceRepository {
    final mode = _readString(
      'ATTENDANCE_REPOSITORY_MODE',
      defaultValue: 'mock',
    );
    return mode.trim().toLowerCase() != 'api';
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

  static String _readString(String key, {required String defaultValue}) {
    final raw = dotenv.env[key];
    if (raw == null || raw.trim().isEmpty) return defaultValue;
    return raw;
  }
}
