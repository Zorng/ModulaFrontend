import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/reporting/data/dto/x_report_dto.dart';
import 'package:modular_pos/features/reporting/data/dto/z_report_dto.dart';
import 'package:modular_pos/features/reporting/data/reporting_api.dart';
import 'package:modular_pos/features/reporting/data/reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/cash_session_status.dart';
import 'package:modular_pos/features/reporting/domain/models/z_report.dart';
import 'package:modular_pos/features/reporting/domain/models/x_report.dart';

import '../test_utils/fixture_reader.dart';
import '../test_utils/riverpod_test_utils.dart';

class _FakeReportingApi extends ReportingApi {
  _FakeReportingApi() : super(Dio());

  @override
  Future<List<XReportListItemDto>> fetchXReportList({
    required String branchId,
    String? from,
    String? to,
    String? status,
  }) async {
    return [
      XReportListItemDto(
        id: 'session-1',
        status: 'OPEN',
        openedByName: 'John Smith',
        openedAt: DateTime.parse('2025-12-23T08:00:00.000Z'),
        closedAt: null,
      ),
    ];
  }

  @override
  Future<XReportDetailDto> fetchXReportDetail({
    required String sessionId,
    String? branchId,
  }) async {
    return XReportDetailDto(
      id: sessionId,
      status: 'OPEN',
      openedByName: 'John Smith',
      openedAt: DateTime.parse('2025-12-23T08:00:00.000Z'),
      closedAt: null,
      openingFloatUsd: 10,
      openingFloatKhr: 0,
      totalSalesKhqrUsd: 20,
      totalSalesKhqrKhr: 80000,
      totalSalesCashUsd: 45,
      totalSalesCashKhr: 0,
      totalPaidInUsd: 0,
      totalPaidInKhr: 0,
      totalPaidOutUsd: 5,
      totalPaidOutKhr: 0,
      expectedCashUsd: 50,
      expectedCashKhr: 0,
    );
  }

  @override
  Future<ZReportSummaryDto> fetchZReportSummary({
    required String branchId,
    required String date,
  }) async {
    return ZReportSummaryDto(
      date: DateTime.parse('2025-12-23'),
      sessionCount: 2,
      openingFloatUsd: 20,
      openingFloatKhr: 0,
      totalSalesCashUsd: 165,
      totalSalesCashKhr: 0,
      totalPaidInUsd: 0,
      totalPaidInKhr: 0,
      totalPaidOutUsd: 5,
      totalPaidOutKhr: 0,
      expectedCashUsd: 180,
      expectedCashKhr: 0,
    );
  }

  @override
  Future<ZReportDetailDto> fetchZReportDetail({
    required String sessionId,
  }) async {
    return ZReportDetailDto(
      sessionId: sessionId,
      status: 'CLOSED',
      openedByName: 'John Smith',
      openedAt: DateTime.parse('2025-12-23T08:00:00.000Z'),
      closedAt: DateTime.parse('2025-12-23T16:00:00.000Z'),
      openingFloatUsd: 20,
      openingFloatKhr: 0,
      totalSalesKhqrUsd: 7.5,
      totalSalesKhqrKhr: 0,
      totalSalesCashUsd: 15,
      totalSalesCashKhr: 0,
      totalPaidInUsd: 5,
      totalPaidInKhr: 0,
      totalPaidOutUsd: 2,
      totalPaidOutKhr: 0,
      expectedCashUsd: 37,
      expectedCashKhr: 0,
      countedCashUsd: 37,
      countedCashKhr: 0,
      varianceUsd: 0,
      varianceKhr: 0,
      closedByName: 'Jane Doe',
      closeReason: 'NORMAL_CLOSE',
    );
  }
}

void main() {
  setUpAll(() {
    dotenv.testLoad();
  });

  group('Reporting DTO parsing', () {
    test('parses X report list response item', () {
      final payload = readJsonMapFixture(
        fixturePath('reporting/x_report_list_response.json'),
      );
      final items = payload['data'] as List<dynamic>;
      final dto = XReportListItemDto.fromJson(
        Map<String, dynamic>.from(items.first as Map),
      );

      expect(dto.id, '11111111-1111-1111-1111-111111111111');
      expect(dto.status, 'OPEN');
      expect(dto.openedByName, 'John Smith');
      expect(
        dto.openedAt?.toUtc().toIso8601String(),
        '2025-12-23T08:00:00.000Z',
      );
      expect(dto.closedAt, isNull);
    });

    test('parses X report detail response', () {
      final data = <String, dynamic>{
        'sessionId': '11111111-1111-1111-1111-111111111111',
        'status': 'OPEN',
        'openedByName': 'John Smith',
        'openedAt': '2025-12-23T08:00:00.000Z',
        'closedAt': null,
        'openingFloatUsd': 10,
        'openingFloatKhr': 0,
        'totalSalesKhqrUsd': 20,
        'totalSalesKhqrKhr': 80000,
        'totalSaleInUsd': 45,
        'totalSaleInKhr': 0,
        'totalRefundOutUsd': 2,
        'totalRefundOutKhr': 0,
        'totalManualInUsd': 3,
        'totalManualInKhr': 0,
        'totalManualOutUsd': 5,
        'totalManualOutKhr': 0,
        'totalAdjustmentUsd': 0,
        'totalAdjustmentKhr': 0,
        'expectedCashUsd': 51,
        'expectedCashKhr': 0,
      };
      final dto = XReportDetailDto.fromJson(data);

      expect(dto.id, '11111111-1111-1111-1111-111111111111');
      expect(dto.status, 'OPEN');
      expect(dto.openedByName, 'John Smith');
      expect(dto.openingFloatUsd, 10);
      expect(dto.totalSalesKhqrUsd, 20);
      expect(dto.totalSalesCashUsd, 45);
      expect(dto.totalPaidInUsd, 3);
      expect(dto.totalPaidOutUsd, 7);
    });

    test('parses Z report summary response', () {
      final payload = readJsonMapFixture(
        fixturePath('reporting/z_report_summary_response.json'),
      );
      final data = Map<String, dynamic>.from(payload['data'] as Map);
      final dto = ZReportSummaryDto.fromJson(data);

      expect(dto.date?.year, 2025);
      expect(dto.sessionCount, 2);
      expect(dto.expectedCashUsd, 180);
    });

    test('parses Z report detail response', () {
      final data = <String, dynamic>{
        'sessionId': 'session-1',
        'status': 'CLOSED',
        'openedByName': 'John Smith',
        'openedAt': '2026-03-10T01:00:00.000Z',
        'closedAt': '2026-03-10T09:00:00.000Z',
        'openingFloatUsd': 20,
        'openingFloatKhr': 50000,
        'totalSalesNonCashUsd': 7.5,
        'totalSalesNonCashKhr': 0,
        'totalSalesKhqrUsd': 7.5,
        'totalSalesKhqrKhr': 0,
        'totalSaleInUsd': 15,
        'totalSaleInKhr': 0,
        'totalRefundOutUsd': 0,
        'totalRefundOutKhr': 0,
        'totalManualInUsd': 5,
        'totalManualInKhr': 0,
        'totalManualOutUsd': 2,
        'totalManualOutKhr': 0,
        'totalAdjustmentUsd': -1,
        'totalAdjustmentKhr': 0,
        'expectedCashUsd': 37,
        'expectedCashKhr': 50000,
        'countedCashUsd': 37,
        'countedCashKhr': 50000,
        'varianceUsd': 0,
        'varianceKhr': 0,
        'closedByName': 'Jane Doe',
        'closeReason': 'NORMAL_CLOSE',
      };
      final dto = ZReportDetailDto.fromJson(data);

      expect(dto.sessionId, 'session-1');
      expect(dto.totalSalesKhqrUsd, 7.5);
      expect(dto.countedCashUsd, 37);
      expect(dto.varianceUsd, 0);
      expect(dto.closedByName, 'Jane Doe');
    });
  });

  group('Reporting repository mapping', () {
    test('maps X report list items to domain', () async {
      final container = createTestContainer(
        overrides: [
          reportingApiProvider.overrideWithValue(_FakeReportingApi()),
        ],
      );

      final repo = container.read(reportingRepositoryProvider);
      final reports = await repo.fetchXReportList(branchId: 'branch-1');

      expect(reports, hasLength(1));
      final first = reports.first;
      expect(first, isA<XReportListItem>());
      expect(first.status, CashSessionStatus.open);
      expect(first.openedByName, 'John Smith');
    });

    test('maps Z report summary to domain', () async {
      final container = createTestContainer(
        overrides: [
          reportingApiProvider.overrideWithValue(_FakeReportingApi()),
        ],
      );

      final repo = container.read(reportingRepositoryProvider);
      final summary = await repo.fetchZReportSummary(
        branchId: 'branch-1',
        date: '2025-12-23',
      );

      expect(summary, isA<ZReportSummary>());
      expect(summary.sessionCount, 2);
      expect(summary.expectedCashUsd, 180);
    });

    test('maps Z report detail to domain', () async {
      final container = createTestContainer(
        overrides: [
          reportingApiProvider.overrideWithValue(_FakeReportingApi()),
        ],
      );

      final repo = container.read(reportingRepositoryProvider);
      final detail = await repo.fetchZReportDetail(sessionId: 'session-1');

      expect(detail, isA<ZReportDetail>());
      expect(detail.sessionId, 'session-1');
      expect(detail.closedByName, 'Jane Doe');
      expect(detail.countedCashUsd, 37);
    });
  });
}
