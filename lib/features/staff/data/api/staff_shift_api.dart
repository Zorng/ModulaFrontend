import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/staff/data/api/staff_api_helpers.dart';
import 'package:modular_pos/features/staff/data/dto/staff_shift_dto.dart';

final staffShiftApiProvider = Provider<StaffShiftApi>((ref) {
  final dio = ref.read(dioProvider);
  return StaffShiftApi(dio);
});

class StaffShiftApi {
  StaffShiftApi(this._dio);

  final Dio _dio;
  static const _prefix = '/v0/hr/shifts';

  Future<StaffShiftScheduleDto> fetchSchedule({
    required String branchId,
    required String from,
    required String to,
    String? membershipId,
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_prefix/schedule',
        queryParameters: {
          'branchId': branchId.trim(),
          'from': from.trim(),
          'to': to.trim(),
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
          if ((membershipId ?? '').trim().isNotEmpty)
            'membershipId': membershipId!.trim(),
        },
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return StaffShiftScheduleDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load shift schedule.',
      );
    }
  }

  Future<StaffShiftScheduleDto> fetchMembershipSchedule({
    required String membershipId,
    required String from,
    required String to,
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_prefix/memberships/${membershipId.trim()}',
        queryParameters: {
          'from': from.trim(),
          'to': to.trim(),
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return StaffShiftScheduleDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load membership schedule.',
      );
    }
  }

  Future<StaffShiftScheduleDto> fetchMySchedule() async {
    try {
      final response = await _dio.get<dynamic>('$_prefix/me');
      final data = StaffApiHelpers.unwrapMap(response.data);
      return StaffShiftScheduleDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load your shift schedule.',
      );
    }
  }

  Future<StaffShiftPatternDto> createPattern({
    required Map<String, dynamic> payload,
    String? intentId,
  }) async {
    return _writePattern(
      path: '$_prefix/patterns',
      actionKey: 'hr.shift.pattern.create',
      payload: payload,
      intentId: intentId,
      method: _dio.post,
    );
  }

  Future<StaffShiftPatternDto> updatePattern({
    required String patternId,
    required Map<String, dynamic> payload,
    String? intentId,
  }) async {
    return _writePattern(
      path: '$_prefix/patterns/${patternId.trim()}',
      actionKey: 'hr.shift.pattern.update',
      payload: payload,
      intentId: intentId,
      method: _dio.patch,
    );
  }

  Future<StaffShiftPatternDto> deactivatePattern({
    required String patternId,
    required String reason,
    String? intentId,
  }) async {
    final payload = {'reason': reason.trim()};
    return _writePattern(
      path: '$_prefix/patterns/${patternId.trim()}/deactivate',
      actionKey: 'hr.shift.pattern.deactivate',
      payload: payload,
      intentId: intentId,
      method: _dio.post,
    );
  }

  Future<StaffShiftInstanceDto> createInstance({
    required Map<String, dynamic> payload,
    String? intentId,
  }) async {
    return _writeInstance(
      path: '$_prefix/instances',
      actionKey: 'hr.shift.instance.create',
      payload: payload,
      intentId: intentId,
      method: _dio.post,
    );
  }

  Future<StaffShiftInstanceDto> updateInstance({
    required String instanceId,
    required Map<String, dynamic> payload,
    String? intentId,
  }) async {
    return _writeInstance(
      path: '$_prefix/instances/${instanceId.trim()}',
      actionKey: 'hr.shift.instance.update',
      payload: payload,
      intentId: intentId,
      method: _dio.patch,
    );
  }

  Future<StaffShiftInstanceDto> cancelInstance({
    required String instanceId,
    required String reason,
    String? intentId,
  }) async {
    final payload = {'reason': reason.trim()};
    return _writeInstance(
      path: '$_prefix/instances/${instanceId.trim()}/cancel',
      actionKey: 'hr.shift.instance.cancel',
      payload: payload,
      intentId: intentId,
      method: _dio.post,
    );
  }

  Future<StaffShiftPatternDto> _writePattern({
    required String path,
    required String actionKey,
    required Map<String, dynamic> payload,
    required Future<Response<dynamic>> Function(
      String path, {
      dynamic data,
      Options? options,
    })
    method,
    String? intentId,
  }) async {
    try {
      final response = await method(
        path,
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: actionKey,
            payload: payload,
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId!.trim(),
            scope: IdempotencyScope.tenant,
          ),
        ),
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return StaffShiftPatternDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Shift pattern request failed.',
      );
    }
  }

  Future<StaffShiftInstanceDto> _writeInstance({
    required String path,
    required String actionKey,
    required Map<String, dynamic> payload,
    required Future<Response<dynamic>> Function(
      String path, {
      dynamic data,
      Options? options,
    })
    method,
    String? intentId,
  }) async {
    try {
      final response = await method(
        path,
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: actionKey,
            payload: payload,
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId!.trim(),
            scope: IdempotencyScope.tenant,
          ),
        ),
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return StaffShiftInstanceDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Shift instance request failed.',
      );
    }
  }
}
