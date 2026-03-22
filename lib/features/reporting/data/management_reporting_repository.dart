import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/reporting/data/mock_management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/data/remote_management_reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/attendance_reporting.dart';
import 'package:modular_pos/features/reporting/domain/models/report_query.dart';
import 'package:modular_pos/features/reporting/domain/models/restock_spend_reporting.dart';
import 'package:modular_pos/features/reporting/domain/models/sales_reporting.dart';

abstract class ManagementReportingRepository {
  const ManagementReportingRepository();

  Future<SalesSummaryReport> getSalesSummary(SalesSummaryReportQuery query);

  Future<SalesDrillDownReport> getSalesDrillDown(
    SalesDrillDownReportQuery query,
  );

  Future<RestockSpendSummaryReport> getRestockSpendSummary(
    RestockSpendSummaryReportQuery query,
  );

  Future<RestockSpendDrillDownReport> getRestockSpendDrillDown(
    RestockSpendDrillDownReportQuery query,
  );

  Future<AttendanceSummaryReport> getAttendanceSummary(
    AttendanceSummaryReportQuery query,
  );

  Future<AttendanceDrillDownReport> getAttendanceDrillDown(
    AttendanceDrillDownReportQuery query,
  );
}

final useMockManagementReportingRepositoryProvider = Provider<bool>(
  (ref) => AppEnv.useMockReportingRepository,
);

final managementReportingRepositoryProvider =
    Provider<ManagementReportingRepository>((ref) {
      final useMock = ref.watch(useMockManagementReportingRepositoryProvider);
      if (useMock) {
        return ref.watch(mockManagementReportingRepositoryProvider);
      }
      return ref.watch(remoteManagementReportingRepositoryProvider);
    });
