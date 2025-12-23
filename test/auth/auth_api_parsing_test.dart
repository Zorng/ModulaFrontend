import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/auth/data/auth_api.dart';

import '../test_utils/fixture_reader.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    // AuthApi reads `dotenv.env[...]`; widget/unit tests don't load .env files.
    dotenv.testLoad();
  });

  test('AuthApi.login parses established single-tenant session', () async {
    final payload = readJsonMapFixture(
      'test/fixtures/auth/login_single_tenant.json',
    );

    final dio = _MockDio();
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: payload,
        requestOptions: RequestOptions(path: '/v1/auth/login'),
      ),
    );

    final api = AuthApi(dio);

    final session = await api.login(username: '+123', password: 'pw');

    expect(session.requiresTenantSelection, isFalse);
    expect(session.tenantSelectionToken, isEmpty);

    expect(session.accessToken, isNotEmpty);
    expect(session.refreshToken, 'refresh-token');
    expect(session.activeTenantId, 'tenant-1');

    expect(session.user.id, '770e8400-e29b-41d4-a716-446655440010');
    expect(session.user.name, 'Admin User');
    expect(session.user.phone, '+1234567890');
    expect(session.user.status, 'ACTIVE');
    expect(session.user.tenantId, 'tenant-1');
    expect(session.user.role, 'ADMIN');

    expect(session.memberships, hasLength(1));
    final membership = session.memberships.first;
    expect(membership.tenantId, 'tenant-1');
    expect(membership.branches, hasLength(1));

    expect(session.user.branches, hasLength(1));
    final branch = session.user.branches.first;
    expect(branch.id, 'assign-1');
    expect(branch.branchId, '660e8400-e29b-41d4-a716-446655440000');
    expect(branch.name, 'Main Branch');
    expect(branch.role, 'ADMIN');
    expect(branch.active, true);
  });

  test('AuthApi.login returns tenant-selection required session', () async {
    final payload = readJsonMapFixture(
      'test/fixtures/auth/login_multi_tenant.json',
    );

    final dio = _MockDio();
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        data: payload,
        requestOptions: RequestOptions(path: '/v1/auth/login'),
      ),
    );

    final api = AuthApi(dio);

    final session = await api.login(username: '+123', password: 'pw');

    expect(session.requiresTenantSelection, isTrue);
    expect(session.tenantSelectionToken, 'selection-token-123');
    expect(session.activeTenantId, isNull);
    expect(session.accessToken, isEmpty);
    expect(session.refreshToken, isEmpty);

    expect(session.memberships, hasLength(2));
    expect(session.memberships.first.tenantId, 'tenant-1');
    expect(session.memberships.first.tenantName, 'Tenant One');
    expect(session.memberships.last.tenantId, 'tenant-2');
    expect(session.memberships.last.tenantName, 'Tenant Two');
  });
}
