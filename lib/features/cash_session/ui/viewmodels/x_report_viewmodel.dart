import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/reporting/data/reporting_repository.dart';
import 'package:modular_pos/features/reporting/domain/models/cash_session_status.dart';
import 'package:modular_pos/features/reporting/domain/models/x_report.dart';

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
    required this.ownerName,
    required this.status,
    required this.openedAt,
    required this.closedAt,
  });

  final String id;
  final String ownerName;
  final String status;
  final DateTime? openedAt;
  final DateTime? closedAt;
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

  final reports = await repo.fetchXReportList(
    branchId: branchId,
    from: range.from,
    to: range.to,
    status: status,
  );
  return reports
      .map(
        (report) => XReportEntry(
          id: report.id,
          ownerName: report.openedByName.isNotEmpty
              ? report.openedByName
              : 'Cashier',
          status: report.status.label,
          openedAt: report.openedAt,
          closedAt: report.closedAt,
        ),
      )
      .toList(growable: false);
});

final xReportDetailProvider =
    FutureProvider.family<XReportDetail?, XReportEntry>((ref, entry) async {
      final branchId = ref.watch(authActiveBranchIdProvider);
      if (branchId == null || branchId.isEmpty) return null;
      final repo = ref.read(reportingRepositoryProvider);
      final detail = await repo.fetchXReportDetail(
        sessionId: entry.id,
        branchId: branchId,
      );
      return detail;
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

({String from, String to}) _buildDateRange(DateTime date) {
  final startLocal = DateTime(date.year, date.month, date.day);
  final endLocal = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  return (
    from: startLocal.toUtc().toIso8601String(),
    to: endLocal.toUtc().toIso8601String(),
  );
}
