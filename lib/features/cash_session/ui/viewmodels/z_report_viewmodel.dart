import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/reporting/data/reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/z_report.dart';

class ZReportState {
  const ZReportState({
    required this.date,
    this.isLoading = false,
    this.error,
    this.summary,
    this.recentFetches = const [],
  });

  final DateTime date;
  final bool isLoading;
  final String? error;
  final ZReportSummary? summary;
  final List<DateTime> recentFetches;

  ZReportState copyWith({
    DateTime? date,
    bool? isLoading,
    String? error,
    ZReportSummary? summary,
    List<DateTime>? recentFetches,
  }) {
    return ZReportState(
      date: date ?? this.date,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      summary: summary ?? this.summary,
      recentFetches: recentFetches ?? this.recentFetches,
    );
  }
}

class ZReportNotifier extends Notifier<ZReportState> {
  static const int _maxReloadsPerMinute = 5;

  ReportingRepository get _repo => ref.read(reportingRepositoryProvider);

  @override
  ZReportState build() {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    return ZReportState(date: date);
  }

  void setDate(DateTime date) {
    state = state.copyWith(
      date: DateTime(date.year, date.month, date.day),
      summary: null,
      error: null,
      recentFetches: const [],
    );
  }

  bool get canReload => _remainingReloads() > 0;

  int _remainingReloads() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    final recent = state.recentFetches.where((t) => t.isAfter(cutoff)).length;
    return _maxReloadsPerMinute - recent;
  }

  Future<void> generate() async {
    if (!canReload) {
      state = state.copyWith(
        error: 'Rate limit reached. Please wait a minute and try again.',
      );
      return;
    }

    final branchId = ref.read(authActiveBranchIdProvider);
    if (branchId == null || branchId.isEmpty) {
      state = state.copyWith(error: 'Select a branch to load Z report.');
      return;
    }

    final now = DateTime.now();
    final recent = [
      ...state.recentFetches.where(
        (t) => t.isAfter(now.subtract(const Duration(minutes: 1))),
      ),
      now,
    ];
    state = state.copyWith(isLoading: true, error: null, recentFetches: recent);

    try {
      final summary = await _repo.fetchZReportSummary(
        branchId: branchId,
        date: DateFormat('yyyy-MM-dd').format(state.date),
      );
      state = state.copyWith(isLoading: false, summary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final zReportProvider = NotifierProvider<ZReportNotifier, ZReportState>(
  ZReportNotifier.new,
);
