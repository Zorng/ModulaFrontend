import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/core/widgets/layout/bounded_content_frame.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_cache_store.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_history_entry.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_history/widgets/attendance_history_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shared/attendance_utils.dart';

class AttendanceHistoryPage extends ConsumerStatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  ConsumerState<AttendanceHistoryPage> createState() =>
      _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends ConsumerState<AttendanceHistoryPage> {
  bool _loading = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _offset = 0;
  List<AttendanceRecord> _records = const [];
  List<AttendanceHistoryEntry> _historyEntries = const [];

  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedHistory();
      _loadHistory(reset: true);
    });
  }

  Future<void> _loadCachedHistory() async {
    final scope = ref.read(attendanceCacheScopeProvider);
    if (scope == null) return;

    final snapshot = await ref.read(attendanceCacheStoreProvider).read(scope);
    if (!mounted || snapshot.records.isEmpty) return;

    setState(() {
      _records = snapshot.records;
      _offset = snapshot.records.length;
      _hasMore = snapshot.records.length >= _limit;
    });
    _rebuildHistoryEntries();
  }

  Future<void> _loadHistory({required bool reset}) async {
    if (_loading) return;
    final requestedScope = ref.read(attendanceCacheScopeProvider);
    setState(() {
      _loading = true;
      _errorMessage = null;
      if (reset) {
        _offset = 0;
        _hasMore = true;
      }
    });

    try {
      final branchId = ref.read(authActiveBranchIdProvider);
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final from = DateTime(
        start.year,
        start.month,
        start.day,
      ).toUtc().toIso8601String();
      final to = DateTime(
        now.year,
        now.month,
        now.day + 1,
      ).toUtc().toIso8601String();
      final repo = ref.read(staffAttendanceRepositoryProvider);
      final records = await repo.fetchMyAttendance(
        branchId: branchId,
        from: from,
        to: to,
        limit: _limit,
        offset: _offset,
      );
      if (!mounted) return;
      if (requestedScope != null &&
          ref.read(attendanceCacheScopeProvider) != requestedScope) {
        return;
      }
      final updated = reset ? records : [..._records, ...records];
      if (requestedScope != null) {
        await ref
            .read(attendanceCacheStoreProvider)
            .writeRecords(scope: requestedScope, records: updated);
      }
      setState(() {
        _records = updated;
        _offset += records.length;
        _hasMore = records.length == _limit;
      });
      _rebuildHistoryEntries();
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load attendance history');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _rebuildHistoryEntries() {
    final grouped = <String, List<AttendanceRecord>>{};
    for (final record in _records) {
      final dateKey = formatDateKey(record.occurredAt.toLocal());
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    final entries = grouped.entries.map((entry) {
      final sorted = [...entry.value]
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      final checkIn = sorted.firstWhere(
        (record) => record.type == 'CHECK_IN',
        orElse: () => sorted.first,
      );
      final checkOut = sorted.lastWhere(
        (record) => record.type == 'CHECK_OUT',
        orElse: () => checkIn,
      );
      return AttendanceHistoryEntry(
        date: entry.key,
        checkInAt: checkIn.type == 'CHECK_IN' ? checkIn.occurredAt : null,
        checkOutAt: checkOut.type == 'CHECK_OUT' ? checkOut.occurredAt : null,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    setState(() => _historyEntries = entries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BoundedContentFrame(
          maxWidth: 960,
          child: ListView(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ),
              if (_loading && _historyEntries.isEmpty)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_historyEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No attendance history found.'),
                  )
                else
                  ..._historyEntries.map(
                    (entry) => AttendanceHistoryCard(entry: entry),
                  ),
                const SizedBox(height: 12),
                if (_hasMore)
                  FilledButton(
                    style: AppButtons.primary(context),
                    onPressed: _loading
                        ? null
                        : () => _loadHistory(reset: false),
                    child: Text(_loading ? 'Loading...' : 'Load more'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
