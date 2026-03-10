import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/reporting/data/reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/z_report.dart';

final cashSessionHistoryDetailProvider =
    FutureProvider.family<ZReportDetail, String>((ref, sessionId) async {
      final repo = ref.read(reportingRepositoryProvider);
      return repo.fetchZReportDetail(sessionId: sessionId);
    });
