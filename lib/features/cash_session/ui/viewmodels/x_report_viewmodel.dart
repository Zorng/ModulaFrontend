import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/reporting/data/reporting_repository.dart';

enum XReportStatusFilter { all, open, closed }

class XReportFilters {
  XReportFilters({required this.date, this.status = XReportStatusFilter.all});

  final DateTime date;
  final XReportStatusFilter status;

  XReportFilters copyWith({DateTime? date, XReportStatusFilter? status}) {
    return XReportFilters(
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}

class XReportEntry {
  XReportEntry({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    required this.openedAt,
    required this.closedAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String status;
  final DateTime? openedAt;
  final DateTime? closedAt;

  factory XReportEntry.fromJson(Map<String, dynamic> json) {
    return XReportEntry(
      id: json['id']?.toString() ?? '',
      ownerId: json['openedById']?.toString() ?? '',
      ownerName: json['openedByName']?.toString() ?? 'Cashier',
      status: _normalizeStatus(json['status']),
      openedAt: _parseDate(json['openedAt']),
      closedAt: _parseDate(json['closedAt']),
    );
  }
}

class XReportDetail {
  XReportDetail({
    required this.id,
    required this.status,
    required this.openedByName,
    required this.openedAt,
    required this.closedAt,
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

  final String id;
  final String status;
  final String openedByName;
  final DateTime? openedAt;
  final DateTime? closedAt;
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

  factory XReportDetail.fromJson(Map<String, dynamic> json) {
    return XReportDetail(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      openedByName: json['openedByName']?.toString() ?? 'Cashier',
      openedAt: _parseDate(json['openedAt']),
      closedAt: _parseDate(json['closedAt']),
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

  factory XReportDetail.mockFromEntry(XReportEntry entry) {
    return XReportDetail(
      id: entry.id,
      status: entry.status,
      openedByName: entry.ownerName,
      openedAt: entry.openedAt,
      closedAt: entry.closedAt,
      openingFloatUsd: 20,
      openingFloatKhr: 0,
      totalSalesCashUsd: 120,
      totalSalesCashKhr: 0,
      totalPaidInUsd: 10,
      totalPaidInKhr: 0,
      totalPaidOutUsd: 5,
      totalPaidOutKhr: 0,
      expectedCashUsd: 145,
      expectedCashKhr: 0,
    );
  }
}

class XReportFiltersNotifier extends Notifier<XReportFilters> {
  @override
  XReportFilters build() {
    final now = DateTime.now();
    return XReportFilters(date: DateTime(now.year, now.month, now.day));
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setStatus(XReportStatusFilter status) {
    state = state.copyWith(status: status);
  }
}

final xReportFiltersProvider =
    NotifierProvider<XReportFiltersNotifier, XReportFilters>(
      XReportFiltersNotifier.new,
    );

final xReportEntriesProvider = FutureProvider<List<XReportEntry>>((ref) async {
  final session = ref.watch(loginControllerProvider).session;
  final branchId = ref.watch(authActiveBranchIdProvider);
  final filters = ref.watch(xReportFiltersProvider);
  // Re-fetch when cash session state changes.
  ref.watch(
    cashSessionViewModelProvider.select(
      (state) => (state.sessionId, state.sessionStatus),
    ),
  );

  if (session == null || branchId == null || branchId.isEmpty) {
    return const [];
  }

  final repo = ref.read(reportingRepositoryProvider);
  final range = _buildDateRange(filters.date);
  final status = switch (filters.status) {
    XReportStatusFilter.all => 'all',
    XReportStatusFilter.open => 'open',
    XReportStatusFilter.closed => 'closed',
  };

  final payload = await repo.fetchXReportList(
    branchId: branchId,
    from: range.from,
    to: range.to,
    status: status,
  );
  final data = payload['data'];
  if (data is! List) return const [];
  return data
      .whereType<Map<String, dynamic>>()
      .map((item) => XReportEntry.fromJson(item))
      .toList();
});

final xReportDetailProvider =
    FutureProvider.family<XReportDetail?, XReportEntry>((ref, entry) async {
      if (entry.id.startsWith('mock-')) {
        return XReportDetail.mockFromEntry(entry);
      }
      final branchId = ref.watch(authActiveBranchIdProvider);
      if (branchId == null || branchId.isEmpty) return null;
      final repo = ref.read(reportingRepositoryProvider);
      final payload = await repo.fetchXReportDetail(
        sessionId: entry.id,
        branchId: branchId,
      );
      final data = payload['data'];
      if (data is! Map<String, dynamic>) return null;
      return XReportDetail.fromJson(Map<String, dynamic>.from(data));
    });

class XReportExpandedNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  void collapseAll() {
    state = <String>{};
  }
}

final xReportExpandedProvider =
    NotifierProvider<XReportExpandedNotifier, Set<String>>(
      XReportExpandedNotifier.new,
    );

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

({String from, String to}) _buildDateRange(DateTime date) {
  final startLocal = DateTime(date.year, date.month, date.day);
  final endLocal = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  return (
    from: startLocal.toUtc().toIso8601String(),
    to: endLocal.toUtc().toIso8601String(),
  );
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

String _normalizeStatus(dynamic value) {
  final raw = value?.toString().toUpperCase() ?? '';
  return switch (raw) {
    'OPEN' => 'Open',
    'CLOSED' => 'Closed',
    'PENDING_REVIEW' => 'Pending review',
    'APPROVED' => 'Approved',
    _ => value?.toString() ?? '',
  };
}
