import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

enum _AttendanceTab { check, history }

class _AttendancePageState extends ConsumerState<AttendancePage> {
  _AttendanceTab _tab = _AttendanceTab.check;
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
  List<_HistoryEntry> _historyEntries = const [];

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
      final dateKey = _formatDateKey(record.occurredAt.toLocal());
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
      return _HistoryEntry(
        date: entry.key,
        checkInAt: checkIn.type == 'CHECK_IN' ? checkIn.occurredAt : null,
        checkOutAt: checkOut.type == 'CHECK_OUT' ? checkOut.occurredAt : null,
      );
    }).toList();

    entries.sort((a, b) => b.date.compareTo(a.date));

    final todayKey = _formatDateKey(DateTime.now());
    final todayEntry = entries.firstWhere(
      (entry) => entry.date == todayKey,
      orElse: () => _HistoryEntry(date: todayKey),
    );

    setState(() {
      _historyEntries = entries;
      _todayCheckInAt = todayEntry.checkInAt;
      _todayCheckOutAt = todayEntry.checkOutAt;
      _checkedIn = _todayCheckInAt != null && _todayCheckOutAt == null;
    });
  }

  _DateRange _historyRange() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    return _DateRange(
      start: DateTime(start.year, start.month, start.day)
          .toUtc()
          .toIso8601String(),
      end: DateTime(now.year, now.month, now.day + 1)
          .toUtc()
          .toIso8601String(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year;
    return '$month $day, $year';
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
    final todayLabel = _formatDate(today);
    final checkInLabel =
        _todayCheckInAt == null ? '-' : _formatTime(_todayCheckInAt!.toLocal());
    final checkOutLabel =
        _todayCheckOutAt == null ? '-' : _formatTime(_todayCheckOutAt!.toLocal());
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
        .map((entry) => {
              'day': entry.value,
              'shift': _scheduleLabelForDay(entry.key),
            })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        centerTitle: false,
      ),
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
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    setState(() => _tab = _AttendanceTab.check);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _tab == _AttendanceTab.check
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: _tab == _AttendanceTab.check
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  child: const Text('Check'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    setState(() => _tab = _AttendanceTab.history);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _tab == _AttendanceTab.history
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: _tab == _AttendanceTab.history
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  child: const Text('History'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tab == _AttendanceTab.check) ...[
            Text(
              'Check-in/Check-out Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _ShiftInfoCard(
              schedule: scheduleRows,
              expanded: shiftExpanded,
              loading: _scheduleLoading,
              onToggle: () {
                setState(() => _shiftExpanded = !shiftExpanded);
              },
            ),
            const SizedBox(height: 12),
            _TodayShiftCard(
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
              ..._historyEntries.map((entry) => _HistoryCard(entry: entry)),
              const SizedBox(height: 12),
              if (_historyHasMore)
                FilledButton(
                  onPressed: _historyLoading
                      ? null
                      : () => _loadHistory(reset: false),
                  child:
                      Text(_historyLoading ? 'Loading...' : 'Load more'),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ShiftInfoCard extends StatelessWidget {
  const _ShiftInfoCard({
    required this.schedule,
    required this.expanded,
    required this.loading,
    required this.onToggle,
  });

  final List<Map<String, String>> schedule;
  final bool expanded;
  final bool loading;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Shift Info', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onToggle,
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
            if (expanded)
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(0.9),
                    1: FlexColumnWidth(1.1),
                  },
                  children: [
                    TableRow(
                      children: [
                        Text(
                          'Day',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Shifts',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    ...schedule.map(
                      (row) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(row['day'] ?? ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(row['shift'] ?? ''),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final checkInLabel =
        entry.checkInAt == null ? '-' : _formatTime(entry.checkInAt!);
    final checkOutLabel =
        entry.checkOutAt == null ? '-' : _formatTime(entry.checkOutAt!);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryRow(label: 'Date', value: entry.date),
            const SizedBox(height: 8),
            _HistoryRow(label: 'Check in', value: checkInLabel),
            const SizedBox(height: 8),
            _HistoryRow(label: 'Check out', value: checkOutLabel),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _TodayShiftCard extends StatelessWidget {
  const _TodayShiftCard({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  final String date;
  final String checkIn;
  final String checkOut;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Shift', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _HistoryRow(label: 'Date', value: date),
            const SizedBox(height: 8),
            _HistoryRow(label: 'Check in', value: checkIn),
            const SizedBox(height: 8),
            _HistoryRow(label: 'Check out', value: checkOut),
            const SizedBox(height: 8),
            _HistoryRow(label: 'Status', value: status),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.date,
    this.checkInAt,
    this.checkOutAt,
  });

  final String date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
}

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final String start;
  final String end;
}

String _formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
