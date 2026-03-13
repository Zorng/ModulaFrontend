import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/auth/data/membership_invitation_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  test('listInvitations unwraps canonical envelope and parses dto', () async {
    final dio = _MockDio();
    when(
      () => dio.get<dynamic>(any(), options: any(named: 'options')),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/v0/org/memberships/invitations'),
        data: {
          'success': true,
          'data': {
            'invitations': [
              {
                'membershipId': 'membership-1',
                'tenantId': 'tenant-1',
                'tenantName': 'X Cafe',
                'roleKey': 'CASHIER',
                'invitedAt': '2026-02-13T10:00:00.000Z',
                'invitedByMembershipId': 'membership-owner',
              },
            ],
          },
        },
      ),
    );

    final api = MembershipInvitationApi(dio);
    final invitations = await api.listInvitations();

    expect(invitations, hasLength(1));
    expect(invitations.first.membershipId, 'membership-1');
    expect(invitations.first.tenantName, 'X Cafe');
    expect(invitations.first.roleKey, 'CASHIER');
    expect(
      invitations.first.invitedAt,
      DateTime.parse('2026-02-13T10:00:00.000Z'),
    );
  });

  test('acceptInvitation includes account-scoped idempotency metadata', () async {
    final dio = _MockDio();
    when(
      () => dio.post<dynamic>(any(), options: any(named: 'options')),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v0/org/memberships/invitations/membership-1/accept',
        ),
        data: {
          'success': true,
          'data': {
            'membershipId': 'membership-1',
            'tenantId': 'tenant-1',
            'status': 'ACTIVE',
            'activeBranchIds': ['branch-1'],
          },
        },
      ),
    );

    final api = MembershipInvitationApi(dio);
    final result = await api.acceptInvitation(
      membershipId: 'membership-1',
      intentId: 'accept-1',
    );

    final captured = verify(
      () => dio.post<dynamic>(
        '/v0/org/memberships/invitations/membership-1/accept',
        data: any(named: 'data'),
        options: captureAny(named: 'options'),
      ),
    ).captured.single as Options;
    final request =
        (captured.extra ?? const <String, dynamic>{})[idempotencyRequestExtraKey]
            as IdempotencyRequest;
    expect(request.actionKey, 'org.membership.invitation.accept');
    expect(request.scope, IdempotencyScope.account);
    expect(request.payload, {'membershipId': 'membership-1'});
    expect(result.activeBranchIds, ['branch-1']);
  });

  test('rejectInvitation includes account-scoped idempotency metadata', () async {
    final dio = _MockDio();
    when(
      () => dio.post<dynamic>(any(), options: any(named: 'options')),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v0/org/memberships/invitations/membership-1/reject',
        ),
        data: {
          'success': true,
          'data': {
            'membershipId': 'membership-1',
            'tenantId': 'tenant-1',
            'status': 'REVOKED',
          },
        },
      ),
    );

    final api = MembershipInvitationApi(dio);
    final result = await api.rejectInvitation(
      membershipId: 'membership-1',
      intentId: 'reject-1',
    );

    final captured = verify(
      () => dio.post<dynamic>(
        '/v0/org/memberships/invitations/membership-1/reject',
        data: any(named: 'data'),
        options: captureAny(named: 'options'),
      ),
    ).captured.single as Options;
    final request =
        (captured.extra ?? const <String, dynamic>{})[idempotencyRequestExtraKey]
            as IdempotencyRequest;
    expect(request.actionKey, 'org.membership.invitation.revoke');
    expect(request.scope, IdempotencyScope.account);
    expect(request.payload, {'membershipId': 'membership-1'});
    expect(result.status, 'REVOKED');
  });

  test('listInvitations maps error envelope to ApiClientException', () async {
    final dio = _MockDio();
    when(
      () => dio.get<dynamic>(any(), options: any(named: 'options')),
    ).thenThrow(
      DioError(
        requestOptions: RequestOptions(path: '/v0/org/memberships/invitations'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(
            path: '/v0/org/memberships/invitations',
          ),
          statusCode: 403,
          data: {
            'success': false,
            'error': 'Invitation inbox unavailable',
            'code': 'PERMISSION_DENIED',
          },
        ),
        error: 'forbidden',
        type: DioErrorType.badResponse,
      ),
    );

    final api = MembershipInvitationApi(dio);

    await expectLater(
      () => api.listInvitations(),
      throwsA(
        isA<ApiClientException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having((error) => error.code, 'code', 'PERMISSION_DENIED'),
      ),
    );
  });
}
