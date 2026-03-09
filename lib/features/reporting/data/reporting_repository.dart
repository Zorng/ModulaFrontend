import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/reporting/data/reporting_api.dart';
import 'package:modular_pos/features/reporting/domain/models/cash_session_status.dart';
import 'package:modular_pos/features/reporting/domain/models/x_report.dart';
import 'package:modular_pos/features/reporting/domain/models/z_report.dart';

final reportingRepositoryProvider = Provider<ReportingRepository>((ref) {
  final api = ref.watch(reportingApiProvider);
  return ReportingRepository(api);
});

class ReportingRepository {
  ReportingRepository(this._api);

  final ReportingApi _api;

  Future<XReportDetail> fetchXReportDetail({
    required String sessionId,
    String? branchId,
  }) async {
    final dto = await _api.fetchXReportDetail(
      sessionId: sessionId,
      branchId: branchId,
    );
    return XReportDetail(
      id: dto.id,
      status: cashSessionStatusFromApi(dto.status),
      openedByName: dto.openedByName,
      openedAt: dto.openedAt,
      closedAt: dto.closedAt,
      openingFloatUsd: dto.openingFloatUsd,
      openingFloatKhr: dto.openingFloatKhr,
      totalSalesKhqrUsd: dto.totalSalesKhqrUsd,
      totalSalesKhqrKhr: dto.totalSalesKhqrKhr,
      totalSalesCashUsd: dto.totalSalesCashUsd,
      totalSalesCashKhr: dto.totalSalesCashKhr,
      totalPaidInUsd: dto.totalPaidInUsd,
      totalPaidInKhr: dto.totalPaidInKhr,
      totalPaidOutUsd: dto.totalPaidOutUsd,
      totalPaidOutKhr: dto.totalPaidOutKhr,
      expectedCashUsd: dto.expectedCashUsd,
      expectedCashKhr: dto.expectedCashKhr,
    );
  }

  Future<List<XReportListItem>> fetchXReportList({
    required String branchId,
    String? from,
    String? to,
    String? status,
  }) async {
    final dtos = await _api.fetchXReportList(
      branchId: branchId,
      from: from,
      to: to,
      status: status,
    );
    return dtos
        .map(
          (dto) => XReportListItem(
            id: dto.id,
            status: cashSessionStatusFromApi(dto.status),
            openedByName: dto.openedByName,
            openedAt: dto.openedAt,
            closedAt: dto.closedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<ZReportSummary> fetchZReportSummary({
    required String branchId,
    required String date,
  }) async {
    final dto = await _api.fetchZReportSummary(branchId: branchId, date: date);
    return ZReportSummary(
      date: dto.date ?? DateTime.now(),
      sessionCount: dto.sessionCount,
      openingFloatUsd: dto.openingFloatUsd,
      openingFloatKhr: dto.openingFloatKhr,
      totalSalesCashUsd: dto.totalSalesCashUsd,
      totalSalesCashKhr: dto.totalSalesCashKhr,
      totalPaidInUsd: dto.totalPaidInUsd,
      totalPaidInKhr: dto.totalPaidInKhr,
      totalPaidOutUsd: dto.totalPaidOutUsd,
      totalPaidOutKhr: dto.totalPaidOutKhr,
      expectedCashUsd: dto.expectedCashUsd,
      expectedCashKhr: dto.expectedCashKhr,
    );
  }
}
