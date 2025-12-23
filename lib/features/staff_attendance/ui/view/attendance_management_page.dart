import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';

class AttendanceManagementPage extends ConsumerStatefulWidget {
  const AttendanceManagementPage({super.key});

  @override
  ConsumerState<AttendanceManagementPage> createState() =>
      _AttendanceManagementPageState();
}

class _AttendanceManagementPageState
    extends ConsumerState<AttendanceManagementPage> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  String? _errorMessage;
  List<AttendanceRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
    });
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 1),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final branchId = ref.read(authActiveBranchIdProvider);
      final range = _buildDateRange(_selectedDate);
      final repo = ref.read(staffAttendanceRepositoryProvider);
      final records = await repo.fetchAdminAttendance(
        branchId: branchId,
        from: range.start,
        to: range.end,
      );
      if (!mounted) return;
      setState(() => _records = records);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load attendance');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(DateTime date) {
    final timeOfDay = TimeOfDay.fromDateTime(date);
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minutes = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minutes $period';
  }

  _DateRange _buildDateRange(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _DateRange(
      start: start.toUtc().toIso8601String(),
      end: end.toUtc().toIso8601String(),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final records =
        _records.where((record) => _isSameDay(record.occurredAt, _selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(_formatDate(_selectedDate)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_errorMessage!),
              ),
            )
          else if (records.isEmpty)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No attendance records for this date.'),
              ),
            )
          else
            ...records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Status', _titleCase(record.type)),
                        const SizedBox(height: 8),
                        _infoRow('Staff', record.employeeId),
                        const SizedBox(height: 8),
                        _infoRow(
                          'Occurred at',
                          '${_formatDate(record.occurredAt)} ${_formatTime(record.occurredAt)}',
                        ),
                        const SizedBox(height: 8),
                        _infoRow(
                          'Created at',
                          '${_formatDate(record.createdAt)} ${_formatTime(record.createdAt)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final String start;
  final String end;
}
