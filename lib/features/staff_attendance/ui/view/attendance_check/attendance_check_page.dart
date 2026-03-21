import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff/data/repository/staff_shift_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_cache_store.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_offline_queue.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_shift_schedule.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_check/widgets/shift_info_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_check/widgets/today_shift_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shared/attendance_geolocation.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shared/attendance_utils.dart';
import 'package:uuid/uuid.dart';

typedef AttendanceGeoCapture = Future<AttendanceGeoSnapshot> Function();

final attendanceGeoCaptureProvider = Provider<AttendanceGeoCapture>((ref) {
  return AttendanceGeolocation.capture;
});

class AttendanceCheckPage extends ConsumerStatefulWidget {
  const AttendanceCheckPage({super.key});

  @override
  ConsumerState<AttendanceCheckPage> createState() =>
      _AttendanceCheckPageState();
}

class _AttendanceCheckPageState extends ConsumerState<AttendanceCheckPage> {
  static const Uuid _uuid = Uuid();

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
      _loadCachedAttendanceData();
      _loadSchedule();
      _loadAttendanceContext();
      _loadTodayAttendance();
    });
  }

  Future<void> _loadCachedAttendanceData() async {
    final scope = ref.read(attendanceCacheScopeProvider);
    if (scope == null) return;

    final snapshot = await ref.read(attendanceCacheStoreProvider).read(scope);
    if (!mounted) return;
    if (snapshot.context == null && snapshot.records.isEmpty) return;

    final todayAttendance = _deriveTodayAttendance(snapshot.records);
    setState(() {
      if (snapshot.context != null) {
        _attendanceContext = snapshot.context!;
      }
      _todayCheckInAt = todayAttendance.checkInAt;
      _todayCheckOutAt = todayAttendance.checkOutAt;
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
    final requestedScope = ref.read(attendanceCacheScopeProvider);
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
      if (requestedScope != null) {
        await ref
            .read(attendanceCacheStoreProvider)
            .writeContext(scope: requestedScope, context: attendanceContext);
      }
      if (!mounted) return;
      if (requestedScope != null &&
          ref.read(attendanceCacheScopeProvider) != requestedScope) {
        return;
      }
      setState(() => _attendanceContext = attendanceContext);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to refresh attendance context');
    } finally {
      if (mounted) {
        setState(() => _contextLoading = false);
      }
    }
  }

  Future<void> _loadTodayAttendance() async {
    final requestedScope = ref.read(attendanceCacheScopeProvider);
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
      if (requestedScope != null) {
        await ref
            .read(attendanceCacheStoreProvider)
            .writeRecords(scope: requestedScope, records: records);
      }
      if (!mounted) return;
      if (requestedScope != null &&
          ref.read(attendanceCacheScopeProvider) != requestedScope) {
        return;
      }
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
    final cacheScope = ref.read(attendanceCacheScopeProvider);
    final branchId = ref.read(authActiveBranchIdProvider);
    final connectivityStatus = ref.read(appConnectivityStatusProvider);
    final hasOpenAttendance =
        _attendanceContext.activeAttendance != null ||
        (_todayCheckInAt != null && _todayCheckOutAt == null);
    var shouldRefreshContext = true;

    if (branchId == null || branchId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resolve active branch.')),
      );
      setState(() => _submitting = false);
      return;
    }

    try {
      final position = await ref.read(attendanceGeoCaptureProvider)();
      final clientOpId = _buildClientOpId();
      if (connectivityStatus == AppConnectivityStatus.offline) {
        if (cacheScope == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to queue attendance offline right now.'),
            ),
          );
          return;
        }

        shouldRefreshContext = false;
        if (!hasOpenAttendance) {
          final payload = AttendanceCheckInPayload(
            branchId: branchId,
            deviceLat: position.latitude,
            deviceLng: position.longitude,
            deviceAccuracyM: position.accuracyM,
            clientOpId: clientOpId,
            clientTs: nowIsoUtc,
          );
          await ref
              .read(attendanceOfflineQueueProvider)
              .enqueueCheckIn(scope: cacheScope, payload: payload);
          await _applyOfflineQueuedMutation(
            scope: cacheScope,
            occurredAt: now,
            recordType: 'CHECK_IN',
            attendanceId: clientOpId,
            position: position,
          );
          if (!mounted || ref.read(attendanceCacheScopeProvider) != cacheScope) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Check-in saved offline. It will sync when you reconnect.',
              ),
            ),
          );
        } else {
          final payload = AttendanceCheckOutPayload(
            branchId: branchId,
            deviceLat: position.latitude,
            deviceLng: position.longitude,
            deviceAccuracyM: position.accuracyM,
            clientOpId: clientOpId,
            clientTs: nowIsoUtc,
          );
          await ref
              .read(attendanceOfflineQueueProvider)
              .enqueueCheckOut(scope: cacheScope, payload: payload);
          await _applyOfflineQueuedMutation(
            scope: cacheScope,
            occurredAt: now,
            recordType: 'CHECK_OUT',
            attendanceId: clientOpId,
            position: position,
          );
          if (!mounted || ref.read(attendanceCacheScopeProvider) != cacheScope) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Check-out saved offline. It will sync when you reconnect.',
              ),
            ),
          );
        }
        return;
      }
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
      if (shouldRefreshContext) {
        _loadAttendanceContext();
      }
    }
  }

  Future<void> _applyOfflineQueuedMutation({
    required AttendanceCacheScope scope,
    required DateTime occurredAt,
    required String recordType,
    required String attendanceId,
    required AttendanceGeoSnapshot position,
  }) async {
    final cacheStore = ref.read(attendanceCacheStoreProvider);
    final snapshot = await cacheStore.read(scope);
    final record = AttendanceRecord(
      id: attendanceId,
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      employeeId: scope.accountId,
      type: recordType,
      occurredAt: occurredAt,
      createdAt: occurredAt,
      location: position.latitude == null || position.longitude == null
          ? null
          : AttendanceLocation(
              lat: position.latitude!,
              lng: position.longitude!,
            ),
    );
    final updatedContext = recordType == 'CHECK_IN'
        ? AttendanceContext(
            canCheckIn: false,
            reasonCode: AttendanceReasonCodes.alreadyCheckedIn,
            reasonMessage: 'Attendance saved offline. Waiting to sync.',
            activeShift: _attendanceContext.activeShift,
            activeAttendance: ActiveAttendanceSession(
              attendanceId: attendanceId,
              startAt: occurredAt.toUtc().toIso8601String(),
            ),
            locationVerificationMode:
                _attendanceContext.locationVerificationMode,
            geofence: _attendanceContext.geofence,
          )
        : AttendanceContext(
            canCheckIn: true,
            reasonCode: null,
            reasonMessage: null,
            activeShift: _attendanceContext.activeShift,
            activeAttendance: null,
            locationVerificationMode:
                _attendanceContext.locationVerificationMode,
            geofence: _attendanceContext.geofence,
          );
    final updatedRecords = _mergeAttendanceRecords(
      snapshot.records,
      newRecord: record,
    );
    final todayAttendance = _deriveTodayAttendance(updatedRecords);
    await cacheStore.writeContext(scope: scope, context: updatedContext);
    await cacheStore.writeRecords(scope: scope, records: updatedRecords);
    if (!mounted) return;
    if (ref.read(attendanceCacheScopeProvider) != scope) return;
    setState(() {
      _attendanceContext = updatedContext;
      _todayCheckInAt = todayAttendance.checkInAt;
      _todayCheckOutAt = todayAttendance.checkOutAt;
      _errorMessage = null;
      _locationResultLabel = null;
      _locationResultMessage = null;
    });
  }

  List<AttendanceRecord> _mergeAttendanceRecords(
    List<AttendanceRecord> existingRecords, {
    required AttendanceRecord newRecord,
  }) {
    final merged = existingRecords
        .where((record) => record.id != newRecord.id)
        .toList(growable: true)
      ..add(newRecord)
      ..sort((a, b) {
        final occurredCompare = a.occurredAt.compareTo(b.occurredAt);
        if (occurredCompare != 0) return occurredCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
    return List<AttendanceRecord>.unmodifiable(merged);
  }

  void _syncTodayFromRecords(List<AttendanceRecord> records) {
    final todayAttendance = _deriveTodayAttendance(records);

    setState(() {
      _todayCheckInAt = todayAttendance.checkInAt;
      _todayCheckOutAt = todayAttendance.checkOutAt;
    });
  }

  ({DateTime? checkInAt, DateTime? checkOutAt}) _deriveTodayAttendance(
    List<AttendanceRecord> records,
  ) {
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

    return (
      checkInAt: checkIn.type == 'CHECK_IN' ? checkIn.occurredAt : null,
      checkOutAt: checkOut.type == 'CHECK_OUT' ? checkOut.occurredAt : null,
    );
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

  String _buildClientOpId() {
    return _uuid.v4();
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
