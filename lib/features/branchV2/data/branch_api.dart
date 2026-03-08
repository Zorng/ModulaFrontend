import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/branchV2/data/dto/branch_dto.dart';
import 'package:modular_pos/features/branchV2/data/dto/branch_envelope.dart';

final branchApiProvider = Provider<BranchApi>((ref) {
  final dio = ref.read(dioProvider);
  return BranchApi(dio);
});

class BranchApi {
  BranchApi(this._dio);

  final Dio _dio;

  static const _orgPrefix = '/v0/org';
  String get _authPrefix => AppEnv.authApiPrefix;

  Options? _authorizedOptions(String? accessTokenOverride) {
    final token = (accessTokenOverride ?? '').trim();
    if (token.isEmpty) return null;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<BranchAccessibleBranchDto>> loadAccessibleBranches() async {
    try {
      final response = await _dio.get<dynamic>(
        '$_orgPrefix/branches/accessible',
      );
      final list = BranchEnvelope.unwrapDataList(
        response.data,
        fallbackMessage: 'Failed to load branch list.',
      );
      return list
          .map(BranchAccessibleBranchDto.fromJson)
          .where((item) => item.branchId.trim().isNotEmpty)
          .toList(growable: false);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load branch list.',
      );
    }
  }

  Future<BranchAccessibleBranchDto> getCurrentBranchProfile({
    String? accessTokenOverride,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_orgPrefix/branch/current',
        options: _authorizedOptions(accessTokenOverride),
      );
      final data = BranchEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to load branch profile.',
      );
      return BranchAccessibleBranchDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load branch profile.',
      );
    }
  }

  Future<BranchAccessibleBranchDto> updateCurrentBranchKhqrReceiver({
    required String khqrReceiverAccountId,
    required String khqrReceiverName,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    final payload = <String, dynamic>{
      'khqrReceiverAccountId': khqrReceiverAccountId.trim(),
      'khqrReceiverName': khqrReceiverName.trim(),
    };
    try {
      final response = await _dio.patch<dynamic>(
        '$_orgPrefix/branch/current/khqr-receiver',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'branch.current.khqrReceiver.update',
            payload: payload,
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId!.trim(),
            scope: IdempotencyScope.branch,
          ),
        ).copyWith(headers: _authorizedOptions(accessTokenOverride)?.headers),
      );
      final data = BranchEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to update KHQR receiver.',
      );
      return BranchAccessibleBranchDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to update KHQR receiver.',
      );
    }
  }

  Future<BranchAccessibleBranchDto> updateCurrentBranchAttendanceLocation({
    required String attendanceLocationVerificationMode,
    BranchWorkplaceLocationDto? workplaceLocation,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    final payload = <String, dynamic>{
      'attendanceLocationVerificationMode': attendanceLocationVerificationMode
          .trim(),
      'workplaceLocation': workplaceLocation?.toJson(),
    };
    try {
      final response = await _dio.patch<dynamic>(
        '$_orgPrefix/branch/current/attendance-location',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'branch.current.attendanceLocation.update',
            payload: payload,
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId!.trim(),
            scope: IdempotencyScope.branch,
          ),
        ).copyWith(headers: _authorizedOptions(accessTokenOverride)?.headers),
      );
      final data = BranchEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to update attendance location.',
      );
      return BranchAccessibleBranchDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to update attendance location.',
      );
    }
  }

  Future<BranchActivationInitiateDto> initiateBranchActivation({
    required String branchName,
    String? intentId,
  }) async {
    final payload = BranchActivationInitiateRequestDto(
      branchName: branchName.trim(),
    ).toJson();
    try {
      final response = await _dio.post<dynamic>(
        '$_orgPrefix/branches/activation/initiate',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'branch.activation.initiate',
            payload: payload,
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId?.trim(),
            scope: IdempotencyScope.tenant,
          ),
        ),
      );
      final data = BranchEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to initiate branch activation.',
      );
      return BranchActivationInitiateDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to initiate branch activation.',
      );
    }
  }

  Future<BranchActivationConfirmDto> confirmBranchActivation({
    required String draftId,
    required String paymentToken,
    String? intentId,
  }) async {
    final payload = BranchActivationConfirmRequestDto(
      draftId: draftId.trim(),
      paymentToken: paymentToken.trim(),
    ).toJson();
    try {
      final response = await _dio.post<dynamic>(
        '$_orgPrefix/branches/activation/confirm',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'branch.activation.confirm',
            payload: payload,
            intentId: (intentId ?? '').trim().isEmpty ? null : intentId?.trim(),
            scope: IdempotencyScope.tenant,
          ),
        ),
      );
      final data = BranchEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to confirm branch activation.',
      );
      return BranchActivationConfirmDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to confirm branch activation.',
      );
    }
  }

  Future<BranchContextTokenResultDto> selectBranchContext({
    required String branchId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_authPrefix/context/branch/select',
        data: <String, dynamic>{'branchId': branchId.trim()},
      );
      final data = BranchEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to select branch context.',
      );
      return BranchContextTokenResultDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to select branch context.',
      );
    }
  }
}
