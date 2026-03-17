import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';
import 'package:modular_pos/core/sync/sync_push_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  group('SyncPushApi', () {
    test('push sends device id and encoded operations', () async {
      final dio = _MockDio();
      final occurredAt = DateTime.utc(2026, 3, 17, 9);
      final operation = OfflineCommandRecord(
        clientOpId: 'op-1',
        operationType: OfflineOperationType.attendanceStartWork,
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        accountId: 'account-1',
        occurredAt: occurredAt,
        payloadJson: jsonEncode({'occurredAt': '2026-03-17T09:00:00Z'}),
        status: OfflineCommandQueueStatus.pending,
        retryCount: 0,
        createdAt: occurredAt,
        updatedAt: occurredAt,
      );
      when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/v0/sync/push'),
          data: {
            'success': true,
            'data': {
              'results': [
                {'clientOpId': 'op-1', 'status': 'APPLIED'},
              ],
            },
          },
        ),
      );

      final api = SyncPushApi(dio);
      await api.push(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          accountId: 'account-1',
        ),
        operations: [operation],
      );

      verify(
        () => dio.post<dynamic>(
          '/v0/sync/push',
          data: {
            'deviceId': 'device-1',
            'operations': [
              {
                'clientOpId': 'op-1',
                'operationType': 'attendance.startWork',
                'occurredAt': '2026-03-17T09:00:00.000Z',
                'payload': {'occurredAt': '2026-03-17T09:00:00Z'},
              },
            ],
          },
        ),
      ).called(1);
    });

    test('push parses applied duplicate and failed results', () async {
      final dio = _MockDio();
      when(() => dio.post<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/v0/sync/push'),
          data: {
            'success': true,
            'data': {
              'operationResults': [
                {'client_op_id': 'op-1', 'status': 'APPLIED'},
                {'clientOpId': 'op-2', 'status': 'DUPLICATE'},
                {
                  'clientOpId': 'op-3',
                  'status': 'FAILED',
                  'code': 'OFFLINE_SYNC_OPERATION_NOT_SUPPORTED',
                  'message': 'Replay not supported.',
                },
              ],
            },
          },
        ),
      );

      final api = SyncPushApi(dio);
      final envelope = await api.push(
        context: const SyncPullContext(
          deviceId: 'device-1',
          tenantId: 'tenant-1',
        ),
        operations: [_record('op-1'), _record('op-2'), _record('op-3')],
      );

      expect(envelope.results, hasLength(3));
      expect(envelope.results[0].status, SyncPushResultStatus.applied);
      expect(envelope.results[1].status, SyncPushResultStatus.duplicate);
      expect(envelope.results[2].status, SyncPushResultStatus.failed);
      expect(
        envelope.results[2].errorCode,
        'OFFLINE_SYNC_OPERATION_NOT_SUPPORTED',
      );
    });
  });
}

OfflineCommandRecord _record(String clientOpId) {
  final occurredAt = DateTime.utc(2026, 3, 17, 9);
  return OfflineCommandRecord(
    clientOpId: clientOpId,
    operationType: OfflineOperationType.cashSessionOpen,
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    accountId: '',
    occurredAt: occurredAt,
    payloadJson: '{}',
    status: OfflineCommandQueueStatus.pending,
    retryCount: 0,
    createdAt: occurredAt,
    updatedAt: occurredAt,
  );
}
