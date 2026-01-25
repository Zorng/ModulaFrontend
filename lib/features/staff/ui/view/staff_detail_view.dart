import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/staff/data/staff_management_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

class StaffDetailView extends ConsumerStatefulWidget {
  const StaffDetailView({super.key, required this.staff});

  final Staff staff;

  @override
  ConsumerState<StaffDetailView> createState() => _StaffDetailViewState();
}

class _StaffDetailViewState extends ConsumerState<StaffDetailView> {
  late Staff _currentStaff;
  bool _loadingSchedule = false;
  String? _scheduleError;

  @override
  void initState() {
    super.initState();
    _currentStaff = widget.staff;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedule();
    });
  }

  Future<void> _loadSchedule() async {
    final userId = _currentStaff.id?.trim();
    final branchId =
        _currentStaff.branchId?.trim() ?? ref.read(authActiveBranchIdProvider);
    if (userId == null || userId.isEmpty) return;
    if (branchId == null || branchId.isEmpty) return;

    setState(() {
      _loadingSchedule = true;
      _scheduleError = null;
    });
    try {
      final repo = ref.read(staffManagementRepositoryProvider);
      final schedule = await repo.fetchShiftSchedule(
        userId: userId,
        branchId: branchId,
      );
      if (!mounted) return;
      setState(() {
        _currentStaff = Staff(
          id: _currentStaff.id,
          userName: _currentStaff.userName,
          gender: _currentStaff.gender,
          phoneNumber: _currentStaff.phoneNumber,
          email: _currentStaff.email,
          role: _currentStaff.role,
          branch: _currentStaff.branch,
          scheduleOption: _currentStaff.scheduleOption,
          isActive: _currentStaff.isActive,
          workingDays: _currentStaff.workingDays,
          startTime: _currentStaff.startTime,
          endTime: _currentStaff.endTime,
          customHours: _currentStaff.customHours,
          shiftSchedule: schedule,
          branchId: _currentStaff.branchId,
          status: _currentStaff.status,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _scheduleError = 'Failed to load schedule');
    } finally {
      if (mounted) {
        setState(() => _loadingSchedule = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(_currentStaff),
        ),
        title: const Text('Staff Details'),
        actions: [
          CupertinoButton(
            child: const Text('Edit'),
            onPressed: () async {
              final updatedStaff = await context.push<Staff>(
                AppRoute.staffForm.path,
                extra: _currentStaff,
              );

              if (updatedStaff != null) {
                setState(() {
                  _currentStaff = updatedStaff;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User Name', _currentStaff.userName),
            _buildDetailRow('Gender', _currentStaff.gender),
            _buildDetailRow('Phone Number', _currentStaff.phoneNumber),
            _buildDetailRow('Email', _currentStaff.email),
            _buildDetailRow('Role', _currentStaff.role),
            _buildDetailRow('Branch', _currentStaff.branch),
            _buildDetailRow(
              'Status',
              _currentStaff.status ??
                  (_currentStaff.isActive ? 'Active' : 'Inactive'),
            ),
            _buildShiftScheduleCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftScheduleCard() {
    final schedule = _currentStaff.shiftSchedule;
    final days = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shift Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_loadingSchedule)
              const Center(child: CircularProgressIndicator())
            else if (_scheduleError != null)
              Text(
                _scheduleError!,
                style: TextStyle(color: Colors.red.shade600),
              )
            else if (schedule == null || schedule.isEmpty)
              Text(
                'No schedule available.',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(0.6),
                  1: FlexColumnWidth(1.4),
                },
                children: [
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Day',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Shift',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  ...List.generate(7, (index) {
                    final entry = schedule.firstWhere(
                      (item) => item.dayOfWeek == index,
                      orElse: () =>
                          const ShiftScheduleEntry(dayOfWeek: -1, isOff: true),
                    );
                    final shiftLabel = entry.dayOfWeek == -1
                        ? '-'
                        : entry.isOff
                        ? 'Off'
                        : '${entry.startTime ?? '--'} - ${entry.endTime ?? '--'}';
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(days[index]),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(shiftLabel),
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}
