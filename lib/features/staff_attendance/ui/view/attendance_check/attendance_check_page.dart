import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_check/widgets/shift_info_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_check/widgets/today_shift_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shared/attendance_utils.dart';

class AttendanceCheckPage extends ConsumerStatefulWidget {
  const AttendanceCheckPage({super.key});

  @override
  ConsumerState<AttendanceCheckPage> createState() =>
      _AttendanceCheckPageState();
}

class _AttendanceCheckPageState extends ConsumerState<AttendanceCheckPage> {
  bool? _shiftExpanded;
  bool _checkedIn = false;
  bool _scheduleLoading = false;
  bool _submitting = false;
  String? _errorMessage;

  DateTime? _todayCheckInAt;
  DateTime? _todayCheckOutAt;

  List<AttendanceShiftScheduleEntry> _shiftSchedule = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedule();
      _loadTodayAttendance();
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
      if (mounted) {
        setState(() => _scheduleLoading = false);
      }
    }
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      _errorMessage = null;
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
        limit: 100,
        offset: 0,
      );
      if (!mounted) return;
      _syncTodayFromRecords(records);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load today attendance');
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
      _loadTodayAttendance();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update attendance.')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _syncTodayFromRecords(List<AttendanceRecord> records) {
    final todayKey = formatDateKey(DateTime.now());
    final todayRecords =
        records
            .where(
              (record) =>
                  formatDateKey(record.occurredAt.toLocal()) == todayKey,
            )
            .toList()
          ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final checkIn = todayRecords.firstWhere(
      (record) => record.type == 'CHECK_IN',
      orElse: () => AttendanceRecord(
        id: '',
        tenantId: '',
        branchId: '',
        employeeId: '',
        type: '',
        occurredAt: DateTime.fromMillisecondsSinceEpoch(0),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    final checkOut = todayRecords.lastWhere(
      (record) => record.type == 'CHECK_OUT',
      orElse: () => checkIn,
    );

    final todayCheckInAt = checkIn.type == 'CHECK_IN'
        ? checkIn.occurredAt
        : null;
    final todayCheckOutAt = checkOut.type == 'CHECK_OUT'
        ? checkOut.occurredAt
        : null;

    setState(() {
      _todayCheckInAt = todayCheckInAt;
      _todayCheckOutAt = todayCheckOutAt;
      _checkedIn = _todayCheckInAt != null && _todayCheckOutAt == null;
    });
  }

  String _scheduleLabelForDay(int dayIndex) {
    final entry = _shiftSchedule.firstWhere(
      (item) => item.dayOfWeek == dayIndex,
      orElse: () =>
          const AttendanceShiftScheduleEntry(dayOfWeek: -1, isOff: true),
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

    final scheduleRows =
        const [
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _handleCheckAction,
              child: Text(_checkedIn ? 'Check-out' : 'Check-in'),
            ),
          ),
        ],
      ),
    );
  }
}
