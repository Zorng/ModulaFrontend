import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/reporting/data/reporting_repository.dart';

class ZReportSummary {
  ZReportSummary({
    required this.date,
    required this.sessionCount,
    required this.openingFloatUsd,
    required this.openingFloatKhr,
    required this.totalSalesCashUsd,
    required this.totalSalesCashKhr,
    required this.totalPaidInUsd,
    required this.totalPaidInKhr,
    required this.totalPaidOutUsd,
    required this.totalPaidOutKhr,
    required this.expectedCashUsd,
    required this.expectedCashKhr,
  });

  final DateTime date;
  final int sessionCount;
  final double openingFloatUsd;
  final double openingFloatKhr;
  final double totalSalesCashUsd;
  final double totalSalesCashKhr;
  final double totalPaidInUsd;
  final double totalPaidInKhr;
  final double totalPaidOutUsd;
  final double totalPaidOutKhr;
  final double expectedCashUsd;
  final double expectedCashKhr;

  factory ZReportSummary.fromJson(Map<String, dynamic> json) {
    return ZReportSummary(
      date: _parseDate(json['date']) ?? DateTime.now(),
      sessionCount: _toInt(json['sessionCount']),
      openingFloatUsd: _toDouble(json['openingFloatUsd']),
      openingFloatKhr: _toDouble(json['openingFloatKhr']),
      totalSalesCashUsd: _toDouble(json['totalSalesCashUsd']),
      totalSalesCashKhr: _toDouble(json['totalSalesCashKhr']),
      totalPaidInUsd: _toDouble(json['totalPaidInUsd']),
      totalPaidInKhr: _toDouble(json['totalPaidInKhr']),
      totalPaidOutUsd: _toDouble(json['totalPaidOutUsd']),
      totalPaidOutKhr: _toDouble(json['totalPaidOutKhr']),
      expectedCashUsd: _toDouble(json['expectedCashUsd']),
      expectedCashKhr: _toDouble(json['expectedCashKhr']),
    );
  }
}

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
    state = state.copyWith(
      isLoading: true,
      error: null,
      recentFetches: recent,
    );

    try {
      final payload = await _repo.fetchZReportSummary(
        branchId: branchId,
        date: DateFormat('yyyy-MM-dd').format(state.date),
      );
      final data = payload['data'];
      if (data is! Map<String, dynamic>) {
        state = state.copyWith(
          isLoading: false,
          error: 'No report data returned.',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        summary: ZReportSummary.fromJson(Map<String, dynamic>.from(data)),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final zReportProvider = NotifierProvider<ZReportNotifier, ZReportState>(
  ZReportNotifier.new,
);

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

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
