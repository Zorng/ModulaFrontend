import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance/attendance_models.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance/attendance_utils.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance/widgets/attendance_history_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance/widgets/attendance_tab_switcher.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance/widgets/shift_info_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance/widgets/today_shift_card.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  AttendanceTab _tab = AttendanceTab.check;
  bool? _shiftExpanded;
  bool _checkedIn = false;
  bool _historyLoading = false;
  bool _scheduleLoading = false;
  bool _submitting = false;
  bool _historyHasMore = true;
  String? _errorMessage;

  DateTime? _todayCheckInAt;
  DateTime? _todayCheckOutAt;
  int _historyOffset = 0;

  List<AttendanceShiftScheduleEntry> _shiftSchedule = const [];
  List<AttendanceRecord> _attendanceRecords = const [];
  List<AttendanceHistoryEntry> _historyEntries = const [];

  static const _historyLimit = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedule();
      _loadHistory(reset: true);
    });
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _scheduleLoading = true;
    });
    try {
      final repo = ref.read(staffAttendanceRepositoryProvider);
      final branchId = ref.read(authActiveBranchIdProvider);
      final schedule = await repo.fetchMyShiftSchedule(branchId: branchId);
      if (!mounted) return;
      setState(() => _shiftSchedule = schedule);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load shift schedule');
    } finally {
      if (!mounted) return;
      setState(() => _scheduleLoading = false);
    }
  }

  Future<void> _loadHistory({required bool reset}) async {
    if (_historyLoading) return;
    setState(() {
      _historyLoading = true;
      _errorMessage = null;
      if (reset) {
        _historyOffset = 0;
        _historyHasMore = true;
      }
    });

    try {
      final branchId = ref.read(authActiveBranchIdProvider);
      final range = _historyRange();
      final repo = ref.read(staffAttendanceRepositoryProvider);
      final records = await repo.fetchMyAttendance(
        branchId: branchId,
        from: range.start,
        to: range.end,
        limit: _historyLimit,
        offset: _historyOffset,
      );
      if (!mounted) return;
      final updated = reset ? records : [..._attendanceRecords, ...records];
      setState(() {
        _attendanceRecords = updated;
        _historyOffset += records.length;
        _historyHasMore = records.length == _historyLimit;
      });
      _rebuildHistoryEntries();
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load attendance history');
    } finally {
      if (!mounted) return;
      setState(() => _historyLoading = false);
    }
  }

  Future<void> _handleCheckAction() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final now = DateTime.now();
    final repo = ref.read(staffAttendanceRepositoryProvider);
    try {
      AttendanceRecord? record;
      if (_todayCheckInAt == null || _todayCheckOutAt != null) {
        record = await repo.checkIn(occurredAt: now.toUtc().toIso8601String());
        if (record == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check-in requires approval.')),
          );
          return;
        }
        setState(() {
          _todayCheckInAt = record?.occurredAt ?? now;
          _todayCheckOutAt = null;
          _checkedIn = true;
        });
      } else {
        record = await repo.checkOut(occurredAt: now.toUtc().toIso8601String());
        if (record != null) {
          setState(() {
            _todayCheckOutAt = record?.occurredAt ?? now;
            _checkedIn = false;
          });
        }
      }
      _loadHistory(reset: true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update attendance.')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  void _rebuildHistoryEntries() {
    final grouped = <String, List<AttendanceRecord>>{};
    for (final record in _attendanceRecords) {
      final dateKey = formatDateKey(record.occurredAt.toLocal());
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    final entries = grouped.entries.map((entry) {
      final sorted = [...entry.value]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
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
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final todayKey = formatDateKey(DateTime.now());
    final todayEntry = entries.firstWhere(
      (entry) => entry.date == todayKey,
      orElse: () => AttendanceHistoryEntry(date: todayKey),
    );

    setState(() {
      _historyEntries = entries;
      _todayCheckInAt = todayEntry.checkInAt;
      _todayCheckOutAt = todayEntry.checkOutAt;
      _checkedIn = _todayCheckInAt != null && _todayCheckOutAt == null;
    });
  }

  AttendanceDateRange _historyRange() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    return AttendanceDateRange(
      start: DateTime(start.year, start.month, start.day).toUtc().toIso8601String(),
      end: DateTime(now.year, now.month, now.day + 1).toUtc().toIso8601String(),
    );
  }

  String _scheduleLabelForDay(int dayIndex) {
    final entry = _shiftSchedule.firstWhere(
      (item) => item.dayOfWeek == dayIndex,
      orElse: () => const AttendanceShiftScheduleEntry(
        dayOfWeek: -1,
        isOff: true,
      ),
    );
    if (entry.dayOfWeek == -1) return '-';
    if (entry.isOff) return 'Off';
    return '${entry.startTime ?? '--'} - ${entry.endTime ?? '--'}';
  }

  @override
  Widget build(BuildContext context) {
    final shiftExpanded = _shiftExpanded ?? true;
    final today = DateTime.now();
    final todayLabel = formatDatePretty(today);
    final checkInLabel = _todayCheckInAt == null
        ? '-'
        : formatTimeAmPm(_todayCheckInAt!.toLocal());
    final checkOutLabel = _todayCheckOutAt == null
        ? '-'
        : formatTimeAmPm(_todayCheckOutAt!.toLocal());
    final hasShiftToday = _shiftSchedule.any((entry) {
      final day = today.weekday % 7;
      return entry.dayOfWeek == day && !entry.isOff;
    });
    final statusLabel = !hasShiftToday
        ? 'No shift'
        : (_todayCheckInAt == null
            ? 'Not checked-in'
            : (_todayCheckOutAt == null ? 'Checked-in' : 'Checked out'));

    final scheduleRows = const [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ]
        .asMap()
        .entries
        .map(
          (entry) => {
            'day': entry.value,
            'shift': _scheduleLabelForDay(entry.key),
          },
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance'), centerTitle: false),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _submitting ? null : _handleCheckAction,
            child: Text(_checkedIn ? 'Check-out' : 'Check-in'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade600),
              ),
            ),
          AttendanceTabSwitcher(
            tab: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 16),
          if (_tab == AttendanceTab.check) ...[
            Text(
              'Check-in/Check-out Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ShiftInfoCard(
              schedule: scheduleRows,
              expanded: shiftExpanded,
              loading: _scheduleLoading,
              onToggle: () => setState(() => _shiftExpanded = !shiftExpanded),
            ),
            const SizedBox(height: 12),
            TodayShiftCard(
              date: todayLabel,
              checkIn: checkInLabel,
              checkOut: checkOutLabel,
              status: statusLabel,
            ),
          ] else ...[
            Text(
              'Attendance History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_historyLoading && _historyEntries.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              ..._historyEntries.map(
                (entry) => AttendanceHistoryCard(entry: entry),
              ),
              const SizedBox(height: 12),
              if (_historyHasMore)
                FilledButton(
                  onPressed: _historyLoading ? null : () => _loadHistory(reset: false),
                  child: Text(_historyLoading ? 'Loading...' : 'Load more'),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

