import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/sync/sync_models.dart';

final syncPullApiProvider = Provider<SyncPullApi>((ref) {
  final dio = ref.read(dioProvider);
  return SyncPullApi(dio);
});

class SyncPullApi {
  SyncPullApi(this._dio);

  final Dio _dio;
  static const _path = '/v0/sync/pull';

  Future<SyncPullEnvelope> pull({
    required SyncPullContext context,
    required Set<SyncModuleScope> moduleScopes,
    String? cursor,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        _path,
        data: {
          'deviceId': context.deviceId,
          if ((cursor ?? '').trim().isNotEmpty) 'cursor': cursor!.trim(),
          'moduleScopes': moduleScopes
              .map((scope) => scope.apiValue)
              .toList(growable: false),
        },
      );
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      final pulledAt = DateTime.now();
      final nextCursor = _readCursor(data);
      final moduleData = _readModuleData(data);
      final payloadByScope = <String, dynamic>{
        for (final scope in moduleScopes)
          scope.apiValue: moduleData.containsKey(scope.apiValue)
              ? moduleData[scope.apiValue]
              : data[scope.apiValue],
      };
      return SyncPullEnvelope(
        cursor: nextCursor,
        pulledAt: pulledAt,
        payloadByScope: payloadByScope,
        rawData: data,
      );
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to run pull sync.',
      );
    }
  }

  String? _readCursor(Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['nextCursor'],
      data['next_cursor'],
      data['cursor'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  Map<String, dynamic> _readModuleData(Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['modules'],
      data['moduleData'],
      data['module_data'],
    ];
    for (final candidate in candidates) {
      final parsed = ApiContract.asJsonMap(candidate);
      if (parsed.isNotEmpty) return parsed;
    }
    return const <String, dynamic>{};
  }
}
