import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static const _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');
  static const _authApiPrefixDefine = String.fromEnvironment('AUTH_API_PREFIX');
  static const _menuApiPrefixDefine = String.fromEnvironment('MENU_API_PREFIX');
  static const _inventoryApiPrefixDefine = String.fromEnvironment(
    'INVENTORY_API_PREFIX',
  );
  static const _salesApiPrefixDefine = String.fromEnvironment(
    'SALES_API_PREFIX',
  );
  static const _cashApiPrefixDefine = String.fromEnvironment('CASH_API_PREFIX');
  static const _reportingApiPrefixDefine = String.fromEnvironment(
    'REPORTING_API_PREFIX',
  );
  static const _policyApiPrefixDefine = String.fromEnvironment(
    'POLICY_API_PREFIX',
  );
  static const _attendanceApiPrefixDefine = String.fromEnvironment(
    'ATTENDANCE_API_PREFIX',
  );
  static const _branchApiPrefixDefine = String.fromEnvironment(
    'BRANCH_API_PREFIX',
  );
  static const _googleMapsApiKeyDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
  static const _showDebugErrorsDefine = String.fromEnvironment(
    'SHOW_DEBUG_ERRORS',
  );
  static const _attendanceRepositoryModeDefine = String.fromEnvironment(
    'ATTENDANCE_REPOSITORY_MODE',
  );
  static const _authRepositoryModeDefine = String.fromEnvironment(
    'AUTH_REPOSITORY_MODE',
  );
  static const _tenantRepositoryModeDefine = String.fromEnvironment(
    'TENANT_REPOSITORY_MODE',
  );
  static const _branchRepositoryModeDefine = String.fromEnvironment(
    'BRANCH_REPOSITORY_MODE',
  );
  static const _inventoryRepositoryModeDefine = String.fromEnvironment(
    'INVENTORY_REPOSITORY_MODE',
  );
  static const _discountRepositoryModeDefine = String.fromEnvironment(
    'DISCOUNT_REPOSITORY_MODE',
  );
  static const _policyRepositoryModeDefine = String.fromEnvironment(
    'POLICY_REPOSITORY_MODE',
  );
  static const _cashSessionRepositoryModeDefine = String.fromEnvironment(
    'CASH_SESSION_REPOSITORY_MODE',
  );

  static String get apiBaseUrl => _readString(
    primary: _apiBaseUrlDefine,
    dotenvKey: 'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static String get authApiPrefix => _readString(
    primary: _authApiPrefixDefine,
    dotenvKey: 'AUTH_API_PREFIX',
    defaultValue: '/v0/auth',
  );

  static String get menuApiPrefix => _readString(
    primary: _menuApiPrefixDefine,
    dotenvKey: 'MENU_API_PREFIX',
    defaultValue: '/v0/menu',
  );

  static String get inventoryApiPrefix => _readString(
    primary: _inventoryApiPrefixDefine,
    dotenvKey: 'INVENTORY_API_PREFIX',
    defaultValue: '/v0/inventory',
  );

  static String get salesApiPrefix => _readString(
    primary: _salesApiPrefixDefine,
    dotenvKey: 'SALES_API_PREFIX',
    defaultValue: '/v0/sales',
  );

  static String get cashApiPrefix => _readString(
    primary: _cashApiPrefixDefine,
    dotenvKey: 'CASH_API_PREFIX',
    defaultValue: '/v0/cash',
  );

  static String get reportingApiPrefix => _readString(
    primary: _reportingApiPrefixDefine,
    dotenvKey: 'REPORTING_API_PREFIX',
    defaultValue: '/v0/reports',
  );

  static String get policyApiPrefix => _readString(
    primary: _policyApiPrefixDefine,
    dotenvKey: 'POLICY_API_PREFIX',
    defaultValue: '/v0/policy',
  );

  static String get attendanceApiPrefix => _readString(
    primary: _attendanceApiPrefixDefine,
    dotenvKey: 'ATTENDANCE_API_PREFIX',
    defaultValue: '/v0/attendance',
  );

  static String get branchApiPrefix => _readString(
    primary: _branchApiPrefixDefine,
    dotenvKey: 'BRANCH_API_PREFIX',
    defaultValue: '/v0/branches',
  );

  static String get googleMapsApiKey => _readString(
    primary: _googleMapsApiKeyDefine,
    dotenvKey: 'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get showDebugErrors {
    if (kReleaseMode) return false;
    return _readBool(
      primary: _showDebugErrorsDefine,
      dotenvKey: 'SHOW_DEBUG_ERRORS',
      defaultValue: false,
    );
  }

  static bool get useMockAttendanceRepository {
    final mode = _readString(
      primary: _attendanceRepositoryModeDefine,
      dotenvKey: 'ATTENDANCE_REPOSITORY_MODE',
      defaultValue: 'api',
    );
    return mode.trim().toLowerCase() != 'api';
  }

  static bool get useMockAuthRepository {
    final mode = _readString(
      primary: _authRepositoryModeDefine,
      dotenvKey: 'AUTH_REPOSITORY_MODE',
      defaultValue: 'api',
    );
    return mode.trim().toLowerCase() == 'mock';
  }

  static bool get useMockTenantRepository {
    final mode = _readString(
      primary: _tenantRepositoryModeDefine,
      dotenvKey: 'TENANT_REPOSITORY_MODE',
      defaultValue: 'api',
    );
    return mode.trim().toLowerCase() == 'mock';
  }

  static bool get useMockBranchRepository {
    final mode = _readString(
      primary: _branchRepositoryModeDefine,
      dotenvKey: 'BRANCH_REPOSITORY_MODE',
      defaultValue: 'api',
    );
    return mode.trim().toLowerCase() == 'mock';
  }

  static bool get useMockInventoryRepository {
    final mode = _readString(
      primary: _inventoryRepositoryModeDefine,
      dotenvKey: 'INVENTORY_REPOSITORY_MODE',
      defaultValue: 'api',
    );
    return mode.trim().toLowerCase() == 'mock';
  }

  static bool get useMockDiscountRepository {
    final mode = _readString(
      primary: _discountRepositoryModeDefine,
      dotenvKey: 'DISCOUNT_REPOSITORY_MODE',
      defaultValue: 'api',
    );
    return mode.trim().toLowerCase() == 'mock';
  }

  static bool get useMockPolicyRepository {
    final mode = _readString(
      primary: _policyRepositoryModeDefine,
      dotenvKey: 'POLICY_REPOSITORY_MODE',
      defaultValue: 'api',
    );
    return mode.trim().toLowerCase() == 'mock';
  }

  static bool get useMockCashSessionRepository {
    final mode = _readString(
      primary: _cashSessionRepositoryModeDefine,
      dotenvKey: 'CASH_SESSION_REPOSITORY_MODE',
      defaultValue: 'api',
    );
    return mode.trim().toLowerCase() == 'mock';
  }

  static bool _readBool({
    required String primary,
    required String dotenvKey,
    required bool defaultValue,
  }) {
    if (primary.trim().isNotEmpty) {
      return _parseBool(primary, defaultValue: defaultValue);
    }

    String? fromDotEnv;
    try {
      fromDotEnv = dotenv.env[dotenvKey];
    } catch (_) {
      return defaultValue;
    }
    if (fromDotEnv == null || fromDotEnv.trim().isEmpty) {
      return defaultValue;
    }
    return _parseBool(fromDotEnv, defaultValue: defaultValue);
  }

  static bool _parseBool(String value, {required bool defaultValue}) {
    switch (value.trim().toLowerCase()) {
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

  static String _readString({
    required String primary,
    required String dotenvKey,
    required String defaultValue,
  }) {
    if (primary.trim().isNotEmpty) return primary.trim();

    String? fromDotEnv;
    try {
      fromDotEnv = dotenv.env[dotenvKey];
    } catch (_) {
      return defaultValue;
    }
    if (fromDotEnv == null || fromDotEnv.trim().isEmpty) return defaultValue;
    return fromDotEnv.trim();
  }
}
