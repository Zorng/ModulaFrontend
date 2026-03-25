import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/reporting/data/dto/attendance_reporting_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/restock_spend_reporting_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/sales_reporting_dto.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/report_scope.dart';

final managementReportingApiProvider = Provider<ManagementReportingApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ManagementReportingApi(dio);
});

class ManagementReportingApi {
  ManagementReportingApi(this._dio) : _prefix = AppEnv.reportingApiPrefix;

  final Dio _dio;
  final String _prefix;

  Future<SalesSummaryReportDto> fetchSalesSummary(
    SalesSummaryReportQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/sales/summary',
        queryParameters: {
          ..._scopeQueryParameters(query.scope),
          'topN': query.topN,
        },
      );
      final data = _requireDataMap(
        response.data,
        fallbackMessage: 'Failed to load sales summary report.',
      );
      return SalesSummaryReportDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load sales summary report.',
      );
    }
  }

  Future<SalesDrillDownReportDto> fetchSalesDrillDown(
    SalesDrillDownReportQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/sales/drill-down',
        queryParameters: {
          ..._scopeQueryParameters(query.scope),
          'status': salesDrillDownStatusFilterToApi(query.status),
          'limit': query.limit,
          'offset': query.offset,
        },
      );
      final data = _requireDataMap(
        response.data,
        fallbackMessage: 'Failed to load sales drill-down report.',
      );
      return SalesDrillDownReportDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load sales drill-down report.',
      );
    }
  }

  Future<RestockSpendSummaryReportDto> fetchRestockSpendSummary(
    RestockSpendSummaryReportQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/restock-spend/summary',
        queryParameters: _scopeQueryParameters(query.scope),
      );
      final data = _requireDataMap(
        response.data,
        fallbackMessage: 'Failed to load restock spend summary report.',
      );
      return RestockSpendSummaryReportDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load restock spend summary report.',
      );
    }
  }

  Future<RestockSpendDrillDownReportDto> fetchRestockSpendDrillDown(
    RestockSpendDrillDownReportQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/restock-spend/drill-down',
        queryParameters: {
          ..._scopeQueryParameters(query.scope),
          'costFilter': restockSpendCostFilterToApi(query.costFilter),
          'limit': query.limit,
          'offset': query.offset,
        },
      );
      final data = _requireDataMap(
        response.data,
        fallbackMessage: 'Failed to load restock spend drill-down report.',
      );
      return RestockSpendDrillDownReportDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load restock spend drill-down report.',
      );
    }
  }

  Future<AttendanceSummaryReportDto> fetchAttendanceSummary(
    AttendanceSummaryReportQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/attendance/summary',
        queryParameters: {
          ..._scopeQueryParameters(query.scope),
          if (query.membershipId != null && query.membershipId!.isNotEmpty)
            'membershipId': query.membershipId,
        },
      );
      final data = _requireDataMap(
        response.data,
        fallbackMessage: 'Failed to load attendance summary report.',
      );
      return AttendanceSummaryReportDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load attendance summary report.',
      );
    }
  }

  Future<AttendanceDrillDownReportDto> fetchAttendanceDrillDown(
    AttendanceDrillDownReportQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/attendance/drill-down',
        queryParameters: {
          ..._scopeQueryParameters(query.scope),
          if (query.membershipId != null && query.membershipId!.isNotEmpty)
            'membershipId': query.membershipId,
          if (query.classification != null)
            'classification': attendanceClassificationFilterToApi(
              query.classification!,
            ),
          'limit': query.limit,
          'offset': query.offset,
        },
      );
      final data = _requireDataMap(
        response.data,
        fallbackMessage: 'Failed to load attendance drill-down report.',
      );
      return AttendanceDrillDownReportDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load attendance drill-down report.',
      );
    }
  }
}

Map<String, dynamic> _scopeQueryParameters(ReportScopeQuery query) {
  return {
    'window': reportTimeWindowToApi(query.window),
    if (query.from != null && query.from!.isNotEmpty) 'from': query.from,
    if (query.to != null && query.to!.isNotEmpty) 'to': query.to,
    'branchScope': reportBranchScopeToApi(query.branchScope),
    if (query.branchScope == ReportBranchScope.branch &&
        query.branchId != null &&
        query.branchId!.isNotEmpty)
      'branchId': query.branchId,
  };
}

Map<String, dynamic> _requireDataMap(
  Map<String, dynamic>? payload, {
  required String fallbackMessage,
}) {
  final body = ApiContract.asJsonMap(payload);
  if (body['success'] != true) {
    throw ApiClientException(
      message: ApiContract.errorMessage(body)?.trim().isNotEmpty == true
          ? ApiContract.errorMessage(body)!.trim()
          : fallbackMessage,
      code: ApiContract.errorCode(body),
      details: ApiContract.errorDetails(body),
    );
  }
  final data = ApiContract.unwrapData(body);
  final map = ApiContract.asJsonMap(data);
  if (map.isEmpty && data is! Map) {
    throw ApiClientException(message: fallbackMessage);
  }
  return map;
}
