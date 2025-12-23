import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/reporting/data/reporting_api.dart';

final reportingRepositoryProvider = Provider<ReportingRepository>((ref) {
  final api = ref.watch(reportingApiProvider);
  return ReportingRepository(api);
});

class ReportingRepository {
  ReportingRepository(this._api);

  final ReportingApi _api;

  Future<Map<String, dynamic>> fetchXReportDetail({
    required String sessionId,
    String? branchId,
  }) {
    return _api.fetchXReportDetail(sessionId: sessionId, branchId: branchId);
  }

  Future<Map<String, dynamic>> fetchXReportList({
    required String branchId,
    String? from,
    String? to,
    String? status,
  }) {
    return _api.fetchXReportList(
      branchId: branchId,
      from: from,
      to: to,
      status: status,
    );
  }

  Future<Map<String, dynamic>> fetchZReportSummary({
    required String branchId,
    required String date,
  }) {
    return _api.fetchZReportSummary(branchId: branchId, date: date);
  }
}
