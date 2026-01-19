import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff_attendance/data/staff_attendance_repository.dart';
import 'package:modular_pos/features/staff_attendance/domain/models/attendance_record.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_management/attendance_management_utils.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_management/widgets/attendance_management_date_picker_row.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_management/widgets/attendance_management_message_card.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_management/widgets/attendance_management_record_card.dart';

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
      final range = buildUtcDayRange(_selectedDate);
      final repo = ref.read(staffAttendanceRepositoryProvider);
      final records = await repo.fetchAdminAttendance(
        branchId: branchId,
        from: range.fromIsoUtc,
        to: range.toIsoUtc,
      );
      if (!mounted) return;
      setState(() => _records = records);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            UserErrorMessage.build(context: 'Failed to load attendance', error: error),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AttendanceManagementDatePickerRow(
            selectedDate: _selectedDate,
            onPickDate: _pickDate,
            enabled: !_loading,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            AttendanceManagementMessageCard(message: _errorMessage!)
          else if (_records.isEmpty)
            const AttendanceManagementMessageCard(
              message: 'No attendance records for this date.',
            )
          else
            ..._records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AttendanceManagementRecordCard(record: record),
              ),
            ),
        ],
      ),
    );
  }
}
