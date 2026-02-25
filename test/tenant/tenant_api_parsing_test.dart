import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/tenant/data/tenant_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  test('createTenant unwraps canonical envelope and parses dto', () async {
    final dio = _MockDio();
    when(
      () => dio.post<dynamic>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v0/org/tenants'),
        data: {
          'success': true,
          'data': {
            'tenant': {'id': 'tenant-1', 'name': 'X Cafe', 'status': 'ACTIVE'},
            'ownerMembership': {
              'id': 'membership-1',
              'roleKey': 'OWNER',
              'status': 'ACTIVE',
            },
            'branch': null,
          },
        },
      ),
    );

    final api = TenantApi(dio);
    final result = await api.createTenant(tenantName: 'X Cafe');

    expect(result.tenant.id, 'tenant-1');
    expect(result.ownerMembership.roleKey, 'OWNER');
    expect(result.branch, isNull);
  });

  test(
    'getCurrentTenantProfile unwraps canonical envelope and parses dto',
    () async {
      final dio = _MockDio();
      when(() => dio.get<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/v0/org/tenant/current'),
          data: {
            'success': true,
            'data': {
              'tenantId': 'tenant-1',
              'tenantName': 'X Cafe',
              'tenantAddress': 'Street 2004',
              'contactNumber': '+85512000001',
              'logoUrl': 'https://example.com/logo.png',
              'status': 'ACTIVE',
            },
          },
        ),
      );

      final api = TenantApi(dio);
      final result = await api.getCurrentTenantProfile();

      expect(result.tenantId, 'tenant-1');
      expect(result.tenantName, 'X Cafe');
      expect(result.status, 'ACTIVE');
    },
  );

  test('createTenant maps error envelope to ApiClientException', () async {
    final dio = _MockDio();
    when(
      () => dio.post<dynamic>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioError(
        requestOptions: RequestOptions(path: '/v0/org/tenants'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/v0/org/tenants'),
          statusCode: 409,
          data: {
            'success': false,
            'error': 'Tenant hard limit reached',
            'code': 'FAIRUSE_HARD_LIMIT_EXCEEDED',
          },
        ),
        error: 'conflict',
        type: DioErrorType.badResponse,
      ),
    );

    final api = TenantApi(dio);

    await expectLater(
      () => api.createTenant(tenantName: 'X Cafe'),
      throwsA(
        isA<ApiClientException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.code, 'code', 'FAIRUSE_HARD_LIMIT_EXCEEDED'),
      ),
    );
  });
}
