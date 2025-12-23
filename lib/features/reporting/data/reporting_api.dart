import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/dio_client.dart';

final reportingApiProvider = Provider<ReportingApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ReportingApi(dio);
});

class ReportingApi {
  ReportingApi(this._dio)
      : _prefix = dotenv.env['REPORTING_API_PREFIX'] ?? '/v1/reports';

  final Dio _dio;
  final String _prefix;

  Future<Map<String, dynamic>> fetchXReportDetail({
    required String sessionId,
    String? branchId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/cash/x/$sessionId',
      queryParameters:
          branchId != null && branchId.isNotEmpty ? {'branchId': branchId} : null,
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> fetchXReportList({
    required String branchId,
    String? from,
    String? to,
    String? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/cash/x',
      queryParameters: {
        'branchId': branchId,
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> fetchZReportSummary({
    required String branchId,
    required String date,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/cash/z',
      queryParameters: {
        'branchId': branchId,
        'date': date,
      },
    );
    return response.data ?? const {};
  }
}
