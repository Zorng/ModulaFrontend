import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/widgets/layout/bounded_content_frame.dart';
import 'package:modular_pos/core/widgets/navigation/branch_workspace_scaffold.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff/data/staff_admin_attendance_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_attendance_record.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance/staff_attendance_utils.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance/widgets/staff_attendance_date_picker_row.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance/widgets/staff_attendance_message_card.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance/widgets/staff_attendance_record_card.dart';

class StaffAttendancePage extends ConsumerStatefulWidget {
  const StaffAttendancePage({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<StaffAttendancePage> createState() =>
      _StaffAttendancePageState();
}

class _StaffAttendancePageState extends ConsumerState<StaffAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  String? _errorMessage;
  List<StaffAttendanceRecord> _records = const [];

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
      final repo = ref.read(staffAdminAttendanceRepositoryProvider);
      final records = await repo.fetchAttendanceRecords(
        branchId: branchId,
        from: range.fromIsoUtc,
        to: range.toIsoUtc,
      );
      if (!mounted) return;
      setState(() => _records = records);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = UserErrorMessage.build(
          context: 'Failed to load attendance',
          error: error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: BoundedContentFrame(
        maxWidth: 1040,
        child: ListView(
          children: [
            StaffAttendanceDatePickerRow(
              selectedDate: _selectedDate,
              onPickDate: _pickDate,
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              StaffAttendanceMessageCard(message: _errorMessage!)
            else if (_records.isEmpty)
              const StaffAttendanceMessageCard(
                message: 'No attendance records for this date.',
              )
            else
              ..._records.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StaffAttendanceRecordCard(record: record),
                ),
              ),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      return Scaffold(body: content);
    }

    return BranchWorkspaceScaffold(title: 'Attendance', body: content);
  }
}
