import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modular_pos/features/auth/domain/models/auth_session.dart';

class AuthSessionStore {
  AuthSessionStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'auth_session_snapshot';

  Future<void> save(AuthSession session) async {
    final jsonStr = jsonEncode(session.toJson());
    await _prefs.setString(_key, jsonStr);
  }

  Future<AuthSession?> load() async {
    final jsonStr = _prefs.getString(_key);
    if (jsonStr == null) return null;

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      final session = AuthSession.fromJson(decoded);
      // Drop expired sessions (respect 72h window).
      if (session.isRefreshTokenExpired) {
        await clear();
        return null;
      }
      return session;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}

/// Storage instance, provided from `main.dart` so we can wire SharedPreferences once.
final authSessionStoreProvider = Provider<AuthSessionStore>((ref) {
  throw UnimplementedError(
    'authSessionStoreProvider must be overridden in main.dart',
  );
});

/// Session loaded on app startup, if any.
final initialAuthSessionProvider = Provider<AuthSession?>((ref) => null);

