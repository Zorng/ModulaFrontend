import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/auth/data/auth_api.dart';
import 'package:modular_pos/features/auth/data/dto/auth_login_response_dto.dart';

import '../test_utils/fixture_reader.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    // AuthApi reads `dotenv.env[...]`; widget/unit tests don't load .env files.
    dotenv.testLoad();
    registerFallbackValue(Options());
  });

  test('AuthApi.login parses established single-tenant session', () async {
    final payload = readJsonMapFixture(
      'test/fixtures/auth/login_single_tenant.json',
    );

    final dio = _MockDio();
    when(
      () => dio.post(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        data: payload,
        requestOptions: RequestOptions(path: '/v0/auth/login'),
      ),
    );

    final api = AuthApi(dio);

    final response = await api.login(username: '+123', password: 'pw');

    expect(response.requiresTenantSelection, isFalse);
    expect(response.tenantSelection, isNull);
    expect(response.established, isA<EstablishedAuthSessionDto>());

    final session = response.established!;
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

  test(
    'AuthApi.login returns tenant-selection required session (legacy)',
    () async {
      final payload = readJsonMapFixture(
        'test/fixtures/auth/login_multi_tenant.json',
      );

      final dio = _MockDio();
      when(
        () => dio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: payload,
          requestOptions: RequestOptions(path: '/v0/auth/login'),
        ),
      );

      final api = AuthApi(dio);

      final response = await api.login(username: '+123', password: 'pw');

      expect(response.requiresTenantSelection, isTrue);
      expect(response.established, isNull);
      expect(response.tenantSelection, isNotNull);

      final selection = response.tenantSelection!;
      expect(selection.selectionToken, 'selection-token-123');
      expect(selection.memberships, hasLength(2));
      expect(selection.memberships.first.tenantId, 'tenant-1');
      expect(selection.memberships.first.tenantName, 'Tenant One');
      expect(selection.memberships.last.tenantId, 'tenant-2');
      expect(selection.memberships.last.tenantName, 'Tenant Two');
      expect(selection.user, isNotNull);
      expect(selection.user!.name, '+123');
      expect(selection.user!.phone, '+123');
    },
  );

  test(
    'AuthApi.login returns tenant-selection required session (v0 context)',
    () async {
      final loginPayload = readJsonMapFixture(
        'test/fixtures/auth/login_v0_context_pending.json',
      );
      final tenantOptions = readJsonMapFixture(
        'test/fixtures/auth/context_tenants_selection_required_v0.json',
      );

      final dio = _MockDio();
      when(
        () => dio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: loginPayload,
          requestOptions: RequestOptions(path: '/v0/auth/login'),
        ),
      );
      when(() => dio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response<dynamic>(
          data: tenantOptions,
          requestOptions: RequestOptions(path: '/v0/auth/context/tenants'),
        ),
      );

      final api = AuthApi(dio);

      final response = await api.login(
        username: '+85511111111',
        password: 'pw',
      );

      expect(response.requiresTenantSelection, isTrue);
      expect(response.established, isNull);
      expect(response.tenantSelection, isNotNull);
      final selection = response.tenantSelection!;
      expect(selection.selectionToken, 'v0-context-selection');
      expect(selection.memberships, hasLength(2));
      expect(selection.accessToken, isNotEmpty);
      expect(selection.refreshToken, 'refresh-v0-1');
      expect(selection.accessTokenExpiresAt, isNotNull);
      expect(selection.refreshTokenExpiresAt, isNotNull);
      expect(selection.user, isNotNull);
      expect(selection.user!.name, 'Demo Owner');
      expect(selection.user!.phone, '+85511111111');
    },
  );

  test(
    'AuthApi.login parses established v0 session when tenant selected',
    () async {
      final loginPayload = readJsonMapFixture(
        'test/fixtures/auth/login_v0_tenant_selected.json',
      );
      final tenantOptions = readJsonMapFixture(
        'test/fixtures/auth/context_tenants_selected_v0.json',
      );

      final dio = _MockDio();
      when(
        () => dio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: loginPayload,
          requestOptions: RequestOptions(path: '/v0/auth/login'),
        ),
      );
      when(() => dio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response<dynamic>(
          data: tenantOptions,
          requestOptions: RequestOptions(path: '/v0/auth/context/tenants'),
        ),
      );

      final api = AuthApi(dio);

      final response = await api.login(
        username: '+85511111111',
        password: 'pw',
      );

      expect(response.requiresTenantSelection, isFalse);
      expect(response.established, isNotNull);
      final session = response.established!;
      expect(session.activeTenantId, 'tenant-1');
      expect(session.accessToken, isNotEmpty);
      expect(session.memberships, hasLength(1));
      expect(session.user.tenantId, 'tenant-1');
    },
  );
}
