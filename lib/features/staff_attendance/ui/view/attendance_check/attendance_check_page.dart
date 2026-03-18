import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff/data/repository/staff_shift_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_check/widgets/shift_info_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_check/widgets/today_shift_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shared/attendance_geolocation.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shared/attendance_utils.dart';

class AttendanceCheckPage extends ConsumerStatefulWidget {
  const AttendanceCheckPage({super.key});

  @override
  ConsumerState<AttendanceCheckPage> createState() =>
      _AttendanceCheckPageState();
}

class _AttendanceCheckPageState extends ConsumerState<AttendanceCheckPage> {
  bool _shiftExpanded = false;
  bool _contextLoading = false;
  bool _scheduleLoading = false;
  bool _submitting = false;
  String? _errorMessage;
  String? _locationResultLabel;
  String? _locationResultMessage;

  AttendanceContext _attendanceContext = const AttendanceContext.empty();
  DateTime? _todayCheckInAt;
  DateTime? _todayCheckOutAt;

  List<AttendanceShiftScheduleEntry> _shiftSchedule = const [];
  StaffShiftSchedule _canonicalShiftSchedule = StaffShiftSchedule(
    patterns: <StaffShiftPattern>[],
    instances: <StaffShiftInstance>[],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedule();
      _loadAttendanceContext();
      _loadTodayAttendance();
    });
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _scheduleLoading = true;
    });
    try {
      final branchId = ref.read(authActiveBranchIdProvider);
      if (branchId == null || branchId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _canonicalShiftSchedule = StaffShiftSchedule(
            patterns: <StaffShiftPattern>[],
            instances: <StaffShiftInstance>[],
          );
          _shiftSchedule = const <AttendanceShiftScheduleEntry>[];
        });
        return;
      }
      final repo = ref.read(staffShiftRepositoryProvider);
      final schedule = await repo.fetchMySchedule();
      if (!mounted) return;
      setState(() {
        _canonicalShiftSchedule = schedule;
        _shiftSchedule = _buildWeeklyScheduleEntries(
          schedule: schedule,
          branchId: branchId,
          referenceDate: DateTime.now(),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load shift schedule');
    } finally {
      if (mounted) {
        setState(() => _scheduleLoading = false);
      }
    }
  }

  Future<void> _loadAttendanceContext() async {
    setState(() => _contextLoading = true);
    try {
      final repo = ref.read(staffAttendanceRepositoryProvider);
      final branchId = ref.read(authActiveBranchIdProvider);
      if (branchId == null || branchId.isEmpty) {
        if (!mounted) return;
        setState(() => _attendanceContext = const AttendanceContext.empty());
        return;
      }
      final attendanceContext = await repo.getAttendanceContext(
        branchId: branchId,
      );
      if (!mounted) return;
      setState(() => _attendanceContext = attendanceContext);
    } catch (_) {
      if (!mounted) return;
      setState(() => _attendanceContext = const AttendanceContext.empty());
    } finally {
      if (mounted) {
        setState(() => _contextLoading = false);
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
    final nowIsoUtc = now.toUtc().toIso8601String();
    final repo = ref.read(staffAttendanceRepositoryProvider);
    final branchId = ref.read(authActiveBranchIdProvider);
    final hasOpenAttendance =
        _attendanceContext.activeAttendance != null ||
        (_todayCheckInAt != null && _todayCheckOutAt == null);

    if (branchId == null || branchId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resolve active branch.')),
      );
      setState(() => _submitting = false);
      return;
    }

    try {
      final position = await AttendanceGeolocation.capture();
      final clientOpId = _buildClientOpId(
        hasOpenAttendance ? 'attendance-end' : 'attendance-start',
      );
      if (!hasOpenAttendance) {
        final result = await repo.checkInWithPayload(
          AttendanceCheckInPayload(
            branchId: branchId,
            deviceLat: position.latitude,
            deviceLng: position.longitude,
            deviceAccuracyM: position.accuracyM,
            clientOpId: clientOpId,
            clientTs: nowIsoUtc,
          ),
        );
        final record = result.record;
        setState(() {
          _todayCheckInAt = record?.occurredAt ?? now;
          _todayCheckOutAt = null;
          _locationResultLabel = _locationResultToLabel(result.locationResult);
          _locationResultMessage = result.message;
        });
      } else {
        final result = await repo.checkOutWithPayload(
          AttendanceCheckOutPayload(
            branchId: branchId,
            deviceLat: position.latitude,
            deviceLng: position.longitude,
            deviceAccuracyM: position.accuracyM,
            clientOpId: clientOpId,
            clientTs: nowIsoUtc,
          ),
        );
        final record = result.record;
        setState(() {
          _todayCheckOutAt = record?.occurredAt ?? now;
          _locationResultLabel = _locationResultToLabel(result.locationResult);
          _locationResultMessage = result.message;
        });
      }
      _loadTodayAttendance();
    } on AttendanceRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update attendance.')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
      _loadAttendanceContext();
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

  String _buildClientOpId(String action) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    return '$action-$micros';
  }

  List<AttendanceShiftScheduleEntry> _buildWeeklyScheduleEntries({
    required StaffShiftSchedule schedule,
    required String branchId,
    required DateTime referenceDate,
  }) {
    final normalizedBranchId = branchId.trim();
    final dayRows = <AttendanceShiftScheduleEntry>[
      for (var day = 0; day < 7; day++)
        AttendanceShiftScheduleEntry(dayOfWeek: day, isOff: true),
    ];

    for (final pattern in schedule.patterns) {
      if (!_matchesActiveBranch(pattern.branchId, normalizedBranchId)) continue;
      if (pattern.status != StaffShiftPatternStatus.active) continue;
      if (!_isPatternEffectiveOn(pattern, referenceDate)) continue;
      for (final day in pattern.daysOfWeek) {
        if (day < 0 || day > 6) continue;
        if (!dayRows[day].isOff) continue;
        dayRows[day] = AttendanceShiftScheduleEntry(
          dayOfWeek: day,
          startTime: pattern.plannedStartTime,
          endTime: pattern.plannedEndTime,
          isOff: false,
        );
      }
    }

    return List<AttendanceShiftScheduleEntry>.unmodifiable(dayRows);
  }

  _TodayShiftInfo _resolveTodayShiftInfo(DateTime today, String? branchId) {
    final normalizedBranchId = (branchId ?? '').trim();
    final instanceCandidates = _canonicalShiftSchedule.instances
        .where((entry) {
          if (!_matchesActiveBranch(entry.branchId, normalizedBranchId)) {
            return false;
          }
          if (entry.status == StaffShiftInstanceStatus.cancelled) {
            return false;
          }
          return _isSameDate(entry.date, today);
        })
        .toList(growable: false);
    if (instanceCandidates.isNotEmpty) {
      instanceCandidates.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final instance = instanceCandidates.last;
      return _TodayShiftInfo(
        label: '${instance.plannedStartTime} - ${instance.plannedEndTime}',
        hasAssignedShift: true,
        sourceLabel: 'One-time shift',
      );
    }

    final weekday = today.weekday % 7;
    final patternCandidates = _canonicalShiftSchedule.patterns
        .where((entry) {
          if (!_matchesActiveBranch(entry.branchId, normalizedBranchId)) {
            return false;
          }
          if (entry.status != StaffShiftPatternStatus.active) {
            return false;
          }
          if (!_isPatternEffectiveOn(entry, today)) {
            return false;
          }
          return entry.daysOfWeek.contains(weekday);
        })
        .toList(growable: false);
    if (patternCandidates.isNotEmpty) {
      patternCandidates.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final pattern = patternCandidates.last;
      return _TodayShiftInfo(
        label: '${pattern.plannedStartTime} - ${pattern.plannedEndTime}',
        hasAssignedShift: true,
        sourceLabel: 'Recurring shift',
      );
    }

    return const _TodayShiftInfo(
      label: 'No shift today',
      hasAssignedShift: false,
      sourceLabel: 'No assigned shift',
    );
  }

  _UpcomingInstanceInfo? _resolveUpcomingInstanceInfo(
    DateTime today,
    String? branchId,
  ) {
    final normalizedBranchId = (branchId ?? '').trim();
    final todayDate = DateTime(today.year, today.month, today.day);
    final instanceCandidates = _canonicalShiftSchedule.instances
        .where((entry) {
          if (!_matchesActiveBranch(entry.branchId, normalizedBranchId)) {
            return false;
          }
          if (entry.status == StaffShiftInstanceStatus.cancelled) {
            return false;
          }
          final localDate = entry.date.toLocal();
          final normalizedDate = DateTime(
            localDate.year,
            localDate.month,
            localDate.day,
          );
          return normalizedDate.isAfter(todayDate);
        })
        .toList(growable: false);
    if (instanceCandidates.isEmpty) return null;
    instanceCandidates.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
    final nextInstance = instanceCandidates.first;
    return _UpcomingInstanceInfo(
      dateLabel: formatDatePretty(nextInstance.date.toLocal()),
      timeLabel:
          '${nextInstance.plannedStartTime} - ${nextInstance.plannedEndTime}',
    );
  }

  bool _matchesActiveBranch(String candidateBranchId, String activeBranchId) {
    if (activeBranchId.isEmpty) return true;
    return candidateBranchId.trim() == activeBranchId;
  }

  bool _isPatternEffectiveOn(StaffShiftPattern pattern, DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    final effectiveFrom = pattern.effectiveFrom;
    if (effectiveFrom != null) {
      final fromDate = DateTime(
        effectiveFrom.year,
        effectiveFrom.month,
        effectiveFrom.day,
      );
      if (localDate.isBefore(fromDate)) return false;
    }
    final effectiveTo = pattern.effectiveTo;
    if (effectiveTo != null) {
      final toDate = DateTime(
        effectiveTo.year,
        effectiveTo.month,
        effectiveTo.day,
      );
      if (localDate.isAfter(toDate)) return false;
    }
    return true;
  }

  bool _isSameDate(DateTime left, DateTime right) {
    final localLeft = left.toLocal();
    return localLeft.year == right.year &&
        localLeft.month == right.month &&
        localLeft.day == right.day;
  }

  String _locationResultToLabel(AttendanceLocationResult result) {
    switch (result) {
      case AttendanceLocationResult.match:
        return 'MATCH';
      case AttendanceLocationResult.mismatch:
        return 'MISMATCH';
      case AttendanceLocationResult.unknown:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayLabel = formatDatePretty(today);
    final branchId = ref.watch(authActiveBranchIdProvider);
    final todayShift = _resolveTodayShiftInfo(today, branchId);
    final upcomingInstance = _resolveUpcomingInstanceInfo(today, branchId);
    final hasShiftToday = todayShift.hasAssignedShift;
    final shiftLabel = todayShift.label;
    final checkInLabel = _todayCheckInAt == null
        ? '-'
        : formatTimeAmPm(_todayCheckInAt!.toLocal());
    final checkOutLabel = _todayCheckOutAt == null
        ? '-'
        : formatTimeAmPm(_todayCheckOutAt!.toLocal());
    final hasOpenAttendance =
        _attendanceContext.activeAttendance != null ||
        (_todayCheckInAt != null && _todayCheckOutAt == null);
    final buttonLabel = hasOpenAttendance ? 'Check-out' : 'Check-in';
    final canTakeAction =
        !_submitting &&
        !_contextLoading &&
        branchId != null &&
        branchId.isNotEmpty;

    final statusLabel = !hasShiftToday && !hasOpenAttendance
        ? 'No shift'
        : (hasOpenAttendance ? 'Working' : 'Not working');
    final showNoShiftAlert = !hasShiftToday && !hasOpenAttendance;

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
      body: Column(
        children: [
          if (showNoShiftAlert)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFC2410C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Shift Today',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: const Color(0xFF9A3412),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You do not have an assigned shift today. You can still record attendance, and the system will capture location evidence normally.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF9A3412)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
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
                TodayShiftCard(
                  date: todayLabel,
                  shift: shiftLabel,
                  shiftSource: todayShift.sourceLabel,
                  checkIn: checkInLabel,
                  checkOut: checkOutLabel,
                  status: statusLabel,
                  nextInstanceDate: upcomingInstance?.dateLabel,
                  nextInstanceShift: upcomingInstance?.timeLabel,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: AppButtons.primary(context),
                    onPressed: canTakeAction ? _handleCheckAction : null,
                    child: Text(_submitting ? 'Please wait...' : buttonLabel),
                  ),
                ),
                if (_locationResultLabel != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Location result: $_locationResultLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_locationResultMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _locationResultMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ShiftInfoCard(
                  schedule: scheduleRows,
                  expanded: _shiftExpanded,
                  loading: _scheduleLoading,
                  onToggle: () =>
                      setState(() => _shiftExpanded = !_shiftExpanded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayShiftInfo {
  const _TodayShiftInfo({
    required this.label,
    required this.hasAssignedShift,
    required this.sourceLabel,
  });

  final String label;
  final bool hasAssignedShift;
  final String sourceLabel;
}

class _UpcomingInstanceInfo {
  const _UpcomingInstanceInfo({
    required this.dateLabel,
    required this.timeLabel,
  });

  final String dateLabel;
  final String timeLabel;
}
