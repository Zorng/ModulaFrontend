import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AuthSession buildSession() {
    return AuthSession(
      user: User(
        id: 'user-1',
        name: 'Tester',
        role: 'ADMIN',
        tenantId: 'tenant-1',
      ),
      memberships: const [],
      activeTenantId: 'tenant-1',
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      accessTokenExpiresAt: DateTime.now().toUtc().add(
        const Duration(minutes: 15),
      ),
      refreshTokenExpiresAt: DateTime.now().toUtc().add(
        const Duration(hours: 72),
      ),
    );
  }

  test('load restores valid session snapshot with tokens', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);
    final session = buildSession();

    await store.save(session);
    final loaded = await store.load();

    expect(loaded, isNotNull);
    expect(loaded!.accessToken, 'access-1');
    expect(loaded.refreshToken, 'refresh-1');
  });

  test('load clears legacy snapshot when token pair is missing', () async {
    final legacySnapshot = <String, dynamic>{
      'user': {
        'id': 'user-1',
        'name': 'Tester',
        'role': 'ADMIN',
        'tenantId': 'tenant-1',
        'branches': const <Map<String, dynamic>>[],
      },
      'memberships': const <Map<String, dynamic>>[],
      'activeTenantId': 'tenant-1',
      'accessTokenExpiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 15))
          .toIso8601String(),
      'refreshTokenExpiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 72))
          .toIso8601String(),
    };

    SharedPreferences.setMockInitialValues({
      'auth_session_snapshot': jsonEncode(legacySnapshot),
    });
    final prefs = await SharedPreferences.getInstance();
    final store = AuthSessionStore(prefs);

    final loaded = await store.load();

    expect(loaded, isNull);
    expect(prefs.getString('auth_session_snapshot'), isNull);
  });
}
