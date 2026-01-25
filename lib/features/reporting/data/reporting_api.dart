import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/reporting/data/dto/x_report_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/z_report_dto.dart';

final reportingApiProvider = Provider<ReportingApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ReportingApi(dio);
});

class ReportingApi {
  ReportingApi(this._dio)
    : _prefix = dotenv.env['REPORTING_API_PREFIX'] ?? '/v1/reports';

  final Dio _dio;
  final String _prefix;

  Future<XReportDetailDto> fetchXReportDetail({
    required String sessionId,
    String? branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/cash/x/$sessionId',
        queryParameters: branchId != null && branchId.isNotEmpty
            ? {'branchId': branchId}
            : null,
      );
      final data = _requireDataMap(response.data);
      return XReportDetailDto.fromJson(data);
    } on DioError catch (error) {
      throw ReportingApiException.fromDio(error);
    }
  }

  Future<List<XReportListItemDto>> fetchXReportList({
    required String branchId,
    String? from,
    String? to,
    String? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/cash/x',
        queryParameters: {
          'branchId': branchId,
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final data = _requireDataList(response.data);
      return data.map(XReportListItemDto.fromJson).toList(growable: false);
    } on DioError catch (error) {
      throw ReportingApiException.fromDio(error);
    }
  }

  Future<ZReportSummaryDto> fetchZReportSummary({
    required String branchId,
    required String date,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_prefix/cash/z',
        queryParameters: {'branchId': branchId, 'date': date},
      );
      final data = _requireDataMap(response.data);
      return ZReportSummaryDto.fromJson(data);
    } on DioError catch (error) {
      throw ReportingApiException.fromDio(error);
    }
  }
}

class ReportingApiException implements Exception {
  const ReportingApiException(this.message, [this.statusCode]);

  factory ReportingApiException.fromDio(DioError exception) {
    final data = exception.response?.data;
    final message =
        data is Map ? data['message']?.toString() : null;
    return ReportingApiException(
      message ?? exception.message ?? 'Reporting API error',
      exception.response?.statusCode,
    );
  }

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ReportingApiException(statusCode: $statusCode, message: $message)';
}

Map<String, dynamic> _requireDataMap(Map<String, dynamic>? payload) {
  final body = payload ?? const {};
  final success = body['success'] == true;
  if (!success) {
    throw ReportingApiException(body['error']?.toString() ?? 'Request failed');
  }
  final data = body['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw const ReportingApiException('Invalid response payload');
}

List<Map<String, dynamic>> _requireDataList(Map<String, dynamic>? payload) {
  final body = payload ?? const {};
  final success = body['success'] == true;
  if (!success) {
    throw ReportingApiException(body['error']?.toString() ?? 'Request failed');
  }
  final data = body['data'];
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  throw const ReportingApiException('Invalid response payload');
}
