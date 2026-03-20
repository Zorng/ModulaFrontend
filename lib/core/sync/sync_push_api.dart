import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/core/sync/sync_models.dart';

enum SyncPushResultStatus { applied, duplicate, failed }

class SyncPushResult {
  const SyncPushResult({
    required this.clientOpId,
    required this.status,
    this.resultRefId,
    this.errorCode,
    this.errorMessage,
  });

  final String clientOpId;
  final SyncPushResultStatus status;
  final String? resultRefId;
  final String? errorCode;
  final String? errorMessage;
}

class SyncPushEnvelope {
  const SyncPushEnvelope({
    required this.pushedAt,
    required this.results,
    required this.rawData,
  });

  final DateTime pushedAt;
  final List<SyncPushResult> results;
  final Map<String, dynamic> rawData;
}

final syncPushApiProvider = Provider<SyncPushApi>((ref) {
  final dio = ref.read(dioProvider);
  return SyncPushApi(dio);
});

class SyncPushApi {
  SyncPushApi(this._dio);

  final Dio _dio;
  static const _path = '/v0/sync/push';

  Future<SyncPushEnvelope> push({
    required SyncPullContext context,
    required List<OfflineCommandRecord> operations,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        _path,
        data: {
          'deviceId': context.deviceId,
          'operations': operations
              .map(_encodeOperation)
              .toList(growable: false),
        },
      );
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      final results = _readResults(data);
      if (operations.isNotEmpty && results.isEmpty) {
        throw const ApiClientException(
          message: 'Push sync response did not include operation results.',
          code: 'SYNC_PUSH_INVALID_RESPONSE',
        );
      }
      return SyncPushEnvelope(
        pushedAt: DateTime.now(),
        results: results,
        rawData: data,
      );
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to run push sync.',
      );
    }
  }

  Map<String, dynamic> _encodeOperation(OfflineCommandRecord operation) {
    final payload = _decodePayload(operation.payloadJson);
    final dependsOn = (operation.dependsOnClientOpId ?? '').trim();
    return {
      'clientOpId': operation.clientOpId,
      'operationType': operation.operationType.apiValue,
      'occurredAt': operation.occurredAt.toUtc().toIso8601String(),
      'payload': payload,
      if (dependsOn.isNotEmpty) 'dependsOn': [dependsOn],
    };
  }

  dynamic _decodePayload(String payloadJson) {
    try {
      return jsonDecode(payloadJson);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  List<SyncPushResult> _readResults(Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['results'],
      data['operationResults'],
      data['operation_results'],
      data['operations'],
    ];
    for (final candidate in candidates) {
      if (candidate is! List) continue;
      final parsed = candidate
          .map((item) => _parseResult(item))
          .whereType<SyncPushResult>()
          .toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    return const <SyncPushResult>[];
  }

  SyncPushResult? _parseResult(dynamic value) {
    final map = ApiContract.asJsonMap(value);
    if (map.isEmpty) return null;
    final clientOpId = _readClientOpId(map);
    if (clientOpId.isEmpty) return null;
    return SyncPushResult(
      clientOpId: clientOpId,
      status: _readStatus(map),
      resultRefId: _readResultRefId(map),
      errorCode: _readErrorCode(map),
      errorMessage: _readErrorMessage(map),
    );
  }

  String _readClientOpId(Map<String, dynamic> map) {
    final candidates = <dynamic>[map['clientOpId'], map['client_op_id']];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  SyncPushResultStatus _readStatus(Map<String, dynamic> map) {
    final candidates = <dynamic>[map['status'], map['result']];
    for (final candidate in candidates) {
      final normalized = candidate?.toString().trim().toUpperCase() ?? '';
      switch (normalized) {
        case 'APPLIED':
          return SyncPushResultStatus.applied;
        case 'DUPLICATE':
          return SyncPushResultStatus.duplicate;
        case 'FAILED':
          return SyncPushResultStatus.failed;
      }
    }
    return SyncPushResultStatus.failed;
  }

  String? _readErrorCode(Map<String, dynamic> map) {
    final details = ApiContract.asJsonMap(map['details']);
    final candidates = <dynamic>[
      map['code'],
      map['reasonCode'],
      map['reason_code'],
      details['code'],
      details['reasonCode'],
      details['reason_code'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  String? _readResultRefId(Map<String, dynamic> map) {
    final candidates = <dynamic>[map['resultRefId'], map['result_ref_id']];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  String? _readErrorMessage(Map<String, dynamic> map) {
    final details = ApiContract.asJsonMap(map['details']);
    final candidates = <dynamic>[
      map['message'],
      map['error'],
      map['reasonMessage'],
      map['reason_message'],
      details['message'],
      details['error'],
      details['reasonMessage'],
      details['reason_message'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }
}
