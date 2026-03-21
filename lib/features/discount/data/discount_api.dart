import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/discount/data/discount_error_codes.dart';
import 'package:modular_pos/features/discount/data/dto/discount_item_preflight_result_dto.dart';
import 'package:modular_pos/features/discount/data/dto/discount_rule_dto.dart';
import 'package:modular_pos/features/discount/data/dto/discount_rule_list_envelope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';

final discountApiProvider = Provider<DiscountApi>((ref) {
  final dio = ref.watch(dioProvider);
  return DiscountApi(dio);
});

class DiscountApi {
  DiscountApi(this._dio) : _prefix = '/v0/discount';

  final Dio _dio;
  final String _prefix;

  Future<List<DiscountRuleDto>> getDiscountRules({
    String? status,
    String? scope,
    String? branchId,
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_prefix/rules',
        queryParameters: {
          if ((status ?? '').trim().isNotEmpty) 'status': status,
          if ((scope ?? '').trim().isNotEmpty) 'scope': scope,
          if ((branchId ?? '').trim().isNotEmpty) 'branchId': branchId,
          if ((search ?? '').trim().isNotEmpty) 'search': search,
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      );
      final rows = DiscountRuleListEnvelope.unwrapDataList(
        response.data,
        fallbackMessage: 'Failed to load discount rules.',
      );
      return rows.map(DiscountRuleDto.fromJson).toList(growable: false);
    } on DioError catch (error) {
      throw _mapDiscountDioError(
        error,
        fallbackMessage: 'Failed to load discount rules.',
      );
    }
  }

  Future<DiscountRuleDto> getDiscountRuleById(String ruleId) async {
    try {
      final response = await _dio.get<dynamic>('$_prefix/rules/$ruleId');
      final data = DiscountRuleListEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to load discount rule.',
      );
      return DiscountRuleDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapDiscountDioError(
        error,
        fallbackMessage: 'Failed to load discount rule.',
      );
    }
  }

  Future<DiscountRuleDto> createDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  }) async {
    final payload = _toWritePayload(rule, confirmOverlap: confirmOverlap);
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/rules',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'discount.rules.create',
            payload: payload,
          ),
        ),
      );
      final data = DiscountRuleListEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to create discount rule.',
      );
      return DiscountRuleDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapDiscountDioError(
        error,
        fallbackMessage: 'Failed to create discount rule.',
      );
    }
  }

  Future<DiscountRuleDto> updateDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  }) async {
    final payload = _toWritePayload(rule, confirmOverlap: confirmOverlap);
    try {
      final response = await _dio.patch<dynamic>(
        '$_prefix/rules/${rule.id}',
        data: payload,
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'discount.rules.update',
            payload: payload,
          ),
        ),
      );
      final data = DiscountRuleListEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to update discount rule.',
      );
      return DiscountRuleDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapDiscountDioError(
        error,
        fallbackMessage: 'Failed to update discount rule.',
      );
    }
  }

  Future<DiscountRuleDto> updateDiscountRuleStatus({
    required String ruleId,
    required String status,
  }) async {
    final normalized = status.trim().toUpperCase();
    final path = switch (normalized) {
      'ACTIVE' => 'activate',
      'INACTIVE' => 'deactivate',
      'ARCHIVED' => 'archive',
      _ => throw const ApiClientException(
        message: 'Unsupported discount status action.',
        code: 'DISCOUNT_RULE_INVALID',
      ),
    };

    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/rules/$ruleId/$path',
        options: withIdempotency(
          request: IdempotencyRequest(
            actionKey: 'discount.rules.$path',
            payload: {'ruleId': ruleId, 'status': normalized},
          ),
        ),
      );
      final data = DiscountRuleListEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to update discount rule status.',
      );
      return DiscountRuleDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapDiscountDioError(
        error,
        fallbackMessage: 'Failed to update discount rule status.',
      );
    }
  }

  Future<DiscountItemPreflightResultDto> resolveEligibleItemsForBranch({
    required String branchId,
    required List<String> itemIds,
  }) async {
    final payload = <String, dynamic>{'branchId': branchId, 'itemIds': itemIds};
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/preflight/eligible-items',
        data: payload,
      );
      final data = DiscountRuleListEnvelope.unwrapDataMap(
        response.data,
        fallbackMessage: 'Failed to validate discount items for branch.',
      );
      return DiscountItemPreflightResultDto.fromJson(data);
    } on DioError catch (error) {
      throw _mapDiscountDioError(
        error,
        fallbackMessage: 'Failed to validate discount items for branch.',
      );
    }
  }

  Map<String, dynamic> _toWritePayload(
    DiscountRule rule, {
    required bool confirmOverlap,
  }) {
    return <String, dynamic>{
      'name': rule.name,
      'branchId': rule.branchId,
      'percentage': rule.percentage,
      'scope': rule.scope,
      'itemIds': rule.itemIds,
      'schedule': {
        'startAt': rule.schedule.startAt?.toIso8601String(),
        'endAt': rule.schedule.endAt?.toIso8601String(),
      },
      'confirmOverlap': confirmOverlap,
    }..removeWhere((key, value) => value == null);
  }
}

ApiClientException _mapDiscountDioError(
  DioError error, {
  required String fallbackMessage,
}) {
  final isOfflineLike =
      error.response == null && error.type != DioErrorType.badResponse;
  if (isOfflineLike) {
    return const ApiClientException(
      message: 'This action requires online connectivity.',
      code: DiscountErrorCodes.offlineUnreachable,
    );
  }
  final mapped = ApiClientException.fromDio(
    error,
    fallbackMessage: fallbackMessage,
  );
  return ApiClientException(
    message: mapped.message,
    code: DiscountErrorCodes.normalize(mapped.code),
    statusCode: mapped.statusCode,
    details: mapped.details,
  );
}
