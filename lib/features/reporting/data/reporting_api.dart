import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/reporting/data/dto/x_report_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/z_report_dto.dart';

final reportingApiProvider = Provider<ReportingApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ReportingApi(dio);
});

class ReportingApi {
  ReportingApi(this._dio) : _cashPrefix = AppEnv.cashApiPrefix;

  final Dio _dio;
  final String _cashPrefix;

  Future<XReportDetailDto> fetchXReportDetail({
    required String sessionId,
    String? branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_cashPrefix/sessions/$sessionId/x',
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
      final responseStatus = switch ((status ?? '').trim().toLowerCase()) {
        'open' => 'open',
        'closed' => 'all',
        _ => 'all',
      };
      final response = await _dio.get<Map<String, dynamic>>(
        '$_cashPrefix/sessions',
        queryParameters: {
          'status': responseStatus,
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
          'limit': 50,
          'offset': 0,
        },
      );
      final sessions = _requireDataList(response.data);
      final filtered = switch ((status ?? '').trim().toLowerCase()) {
        'open' => sessions.where((entry) => _statusOf(entry) == 'OPEN'),
        'closed' => sessions.where((entry) {
          final value = _statusOf(entry);
          return value == 'CLOSED' || value == 'FORCE_CLOSED';
        }),
        _ => sessions,
      };
      return filtered
          .map(
            (entry) => XReportListItemDto(
              id: entry['id']?.toString() ?? '',
              status: _statusOf(entry),
              openedByName: entry['openedByName']?.toString() ?? '',
              openedAt: _parseDate(entry['openedAt']),
              closedAt: _parseDate(entry['closedAt']),
            ),
          )
          .toList(growable: false);
    } on DioError catch (error) {
      throw ReportingApiException.fromDio(error);
    }
  }

  Future<ZReportSummaryDto> fetchZReportSummary({
    required String branchId,
    required String date,
  }) async {
    try {
      final range = _buildDayRange(date);
      final sessionsResponse = await _dio.get<Map<String, dynamic>>(
        '$_cashPrefix/sessions',
        queryParameters: {
          'status': 'all',
          'from': range.from,
          'to': range.to,
          'limit': 100,
          'offset': 0,
        },
      );
      final sessions = _requireDataList(sessionsResponse.data)
          .where((entry) {
            final status = _statusOf(entry);
            return status == 'CLOSED' || status == 'FORCE_CLOSED';
          })
          .toList(growable: false);

      if (sessions.isEmpty) {
        return ZReportSummaryDto(
          date: DateTime.tryParse(date),
          sessionCount: 0,
          openingFloatUsd: 0,
          openingFloatKhr: 0,
          totalSalesCashUsd: 0,
          totalSalesCashKhr: 0,
          totalPaidInUsd: 0,
          totalPaidInKhr: 0,
          totalPaidOutUsd: 0,
          totalPaidOutKhr: 0,
          expectedCashUsd: 0,
          expectedCashKhr: 0,
        );
      }

      double openingFloatUsd = 0;
      double openingFloatKhr = 0;
      double totalSalesCashUsd = 0;
      double totalSalesCashKhr = 0;
      double totalPaidInUsd = 0;
      double totalPaidInKhr = 0;
      double totalPaidOutUsd = 0;
      double totalPaidOutKhr = 0;
      double expectedCashUsd = 0;
      double expectedCashKhr = 0;

      for (final session in sessions) {
        final sessionId = session['id']?.toString();
        if (sessionId == null || sessionId.isEmpty) continue;
        final response = await _dio.get<Map<String, dynamic>>(
          '$_cashPrefix/sessions/$sessionId/z',
        );
        final data = _requireDataMap(response.data);
        openingFloatUsd += _toDouble(data['openingFloatUsd']);
        openingFloatKhr += _toDouble(data['openingFloatKhr']);
        totalSalesCashUsd += _toDouble(data['totalSaleInUsd']);
        totalSalesCashKhr += _toDouble(data['totalSaleInKhr']);
        totalPaidInUsd += _toDouble(data['totalManualInUsd']);
        totalPaidInKhr += _toDouble(data['totalManualInKhr']);
        totalPaidOutUsd +=
            _toDouble(data['totalManualOutUsd']) +
            _toDouble(data['totalRefundOutUsd']);
        totalPaidOutKhr +=
            _toDouble(data['totalManualOutKhr']) +
            _toDouble(data['totalRefundOutKhr']);
        expectedCashUsd += _toDouble(data['expectedCashUsd']);
        expectedCashKhr += _toDouble(data['expectedCashKhr']);
      }

      return ZReportSummaryDto(
        date: DateTime.tryParse(date),
        sessionCount: sessions.length,
        openingFloatUsd: openingFloatUsd,
        openingFloatKhr: openingFloatKhr,
        totalSalesCashUsd: totalSalesCashUsd,
        totalSalesCashKhr: totalSalesCashKhr,
        totalPaidInUsd: totalPaidInUsd,
        totalPaidInKhr: totalPaidInKhr,
        totalPaidOutUsd: totalPaidOutUsd,
        totalPaidOutKhr: totalPaidOutKhr,
        expectedCashUsd: expectedCashUsd,
        expectedCashKhr: expectedCashKhr,
      );
    } on DioError catch (error) {
      throw ReportingApiException.fromDio(error);
    }
  }
}

class ReportingApiException implements Exception {
  const ReportingApiException(this.message, [this.statusCode]);

  factory ReportingApiException.fromDio(DioError exception) {
    final data = exception.response?.data;
    final message = data is Map ? data['message']?.toString() : null;
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

String _statusOf(Map<String, dynamic> entry) {
  return entry['status']?.toString().trim().toUpperCase() ?? '';
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

({String from, String to}) _buildDayRange(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    return (from: date, to: date);
  }
  final startLocal = DateTime(parsed.year, parsed.month, parsed.day);
  final endLocal = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
  return (
    from: startLocal.toUtc().toIso8601String(),
    to: endLocal.toUtc().toIso8601String(),
  );
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
