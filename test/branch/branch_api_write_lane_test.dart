import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/branchV2/data/branch_api.dart';

class _MockDio extends Mock implements Dio {}

class _FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeOptions());
  });

  group('BranchApi write lane', () {
    test(
      'updateCurrentBranchKhqrReceiver includes payload, auth header, and idempotency metadata',
      () async {
        final dio = _MockDio();
        final api = BranchApi(dio);
        const payload = {
          'khqrReceiverAccountId': 'bakong-001',
          'khqrReceiverName': 'Olympic Receiver',
        };

        when(
          () => dio.patch<dynamic>(
            '/v0/org/branch/current/khqr-receiver',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(
              path: '/v0/org/branch/current/khqr-receiver',
            ),
            data: {
              'success': true,
              'data': {
                'branchId': 'branch-1',
                'tenantId': 'tenant-1',
                'branchName': 'Olympic',
                'branchAddress': 'Street 2004',
                'contactNumber': '+85512000009',
                ...payload,
                'attendanceLocationVerificationMode': 'disabled',
                'workplaceLocation': null,
                'status': 'ACTIVE',
              },
            },
          ),
        );

        await api.updateCurrentBranchKhqrReceiver(
          khqrReceiverAccountId: payload['khqrReceiverAccountId']!,
          khqrReceiverName: payload['khqrReceiverName']!,
          accessTokenOverride: 'token-123',
        );

        final captured = verify(
          () => dio.patch<dynamic>(
            '/v0/org/branch/current/khqr-receiver',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        final body = Map<String, dynamic>.from(captured[0] as Map);
        final options = captured[1] as Options;
        final request =
            options.extra?[idempotencyRequestExtraKey] as IdempotencyRequest;

        expect(body, payload);
        expect(options.headers?['Authorization'], 'Bearer token-123');
        expect(request.actionKey, 'branch.current.khqrReceiver.update');
        expect(request.payload, payload);
      },
    );

    test(
      'updateCurrentBranchAttendanceLocation includes payload, auth header, and idempotency metadata',
      () async {
        final dio = _MockDio();
        final api = BranchApi(dio);
        const payload = {
          'attendanceLocationVerificationMode': 'checkin_only',
          'workplaceLocation': {
            'latitude': 11.5564,
            'longitude': 104.9282,
            'radiusMeters': 100.0,
          },
        };

        when(
          () => dio.patch<dynamic>(
            '/v0/org/branch/current/attendance-location',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(
              path: '/v0/org/branch/current/attendance-location',
            ),
            data: {
              'success': true,
              'data': {
                'branchId': 'branch-1',
                'tenantId': 'tenant-1',
                'branchName': 'Olympic',
                'branchAddress': 'Street 2004',
                'contactNumber': '+85512000009',
                'khqrReceiverAccountId': null,
                'khqrReceiverName': null,
                ...payload,
                'status': 'ACTIVE',
              },
            },
          ),
        );

        await api.updateCurrentBranchAttendanceLocation(
          attendanceLocationVerificationMode:
              payload['attendanceLocationVerificationMode']! as String,
          workplaceLocation: null,
          accessTokenOverride: 'token-456',
        );

        final captured = verify(
          () => dio.patch<dynamic>(
            '/v0/org/branch/current/attendance-location',
            data: captureAny(named: 'data'),
            options: captureAny(named: 'options'),
          ),
        ).captured;
        final body = Map<String, dynamic>.from(captured[0] as Map);
        final options = captured[1] as Options;
        final request =
            options.extra?[idempotencyRequestExtraKey] as IdempotencyRequest;

        expect(body['attendanceLocationVerificationMode'], 'checkin_only');
        expect(body['workplaceLocation'], isNull);
        expect(options.headers?['Authorization'], 'Bearer token-456');
        expect(request.actionKey, 'branch.current.attendanceLocation.update');
        expect(
          (request.payload
              as Map<String, dynamic>)['attendanceLocationVerificationMode'],
          'checkin_only',
        );
      },
    );
  });
}
