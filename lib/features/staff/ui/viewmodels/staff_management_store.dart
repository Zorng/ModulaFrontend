import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/features/staff/data/staff_management_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

enum StaffManagementMode { create, view, edit }

class StaffManagementState {
  final StaffManagementMode mode;
  final Staff? initialStaff;
  final bool isLoading;
  final String? error;

  const StaffManagementState({
    required this.mode,
    this.initialStaff,
    this.isLoading = false,
    this.error,
  });

  StaffManagementState copyWith({
    StaffManagementMode? mode,
    Staff? initialStaff,
    bool? isLoading,
    String? error,
  }) {
    return StaffManagementState(
      mode: mode ?? this.mode,
      initialStaff: initialStaff ?? this.initialStaff,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Switched to Notifier (keepAlive) to resolve AutoDisposeNotifier type error.
class StaffManagementController extends Notifier<StaffManagementState> {
  @override
  StaffManagementState build() {
    return const StaffManagementState(mode: StaffManagementMode.create);
  }

  Future<void> initialize(Staff? staff, String? branchId) async {
    if (staff != null) {
      state = state.copyWith(
        mode: StaffManagementMode.view,
        initialStaff: staff,
      );
      // Fetch schedule if existing staff
      if (staff.id != null) {
        // Optimistically show what we have, but load full details including schedule
        await _fetchSchedule(staff.id!);
      }
    } else {
      state = state.copyWith(
        mode: StaffManagementMode.create,
        // For create mode, we might want to preset the branchId if provided
        initialStaff: branchId != null
            ? Staff(
                userName: '',
                phoneNumber: '',
                email: '',
                isActive: true, // Default active
                branchId: branchId,
              )
            : null,
      );
    }
  }

  Future<void> _fetchSchedule(String staffId) async {
    // We don't set loading=true for the whole page to avoid flickering,
    // but we will update the state with the enriched staff object when done.
    try {
      final currentStaff = state.initialStaff;
      
      // Guard against null - if staff is null, don't proceed
      if (currentStaff == null) {
        AppLog.d('WARNING: Cannot fetch schedule: initialStaff is null');
        return;
      }

      final repository = ref.read(staffManagementRepositoryProvider);
      final branchId = currentStaff.branchId ?? '';
      
      if (branchId.isEmpty) {
        AppLog.d('WARNING: Cannot fetch schedule: branchId is empty');
        return;
      }
      
      final schedule = await repository.fetchShiftSchedule(
        userId: staffId,
        branchId: branchId,
      );

      // Check again if initialStaff is still available after async call
      if (state.initialStaff != null) {
        final updatedStaff = state.initialStaff!.copyWith(shiftSchedule: schedule);
        state = state.copyWith(initialStaff: updatedStaff);
      } else {
        AppLog.d('WARNING: Staff became null during schedule fetch');
      }
    } catch (e) {
      // Log but don't block the UI if schedule fails
      AppLog.e('Failed to fetch schedule: $e');
    }
  }

  void toggleEditMode() {
    if (state.mode == StaffManagementMode.view) {
      state = state.copyWith(mode: StaffManagementMode.edit);
    } else if (state.mode == StaffManagementMode.edit) {
      // Cancel edit -> Revert to view
      state = state.copyWith(mode: StaffManagementMode.view, error: null);
    }
  }

  Future<bool> submit(Staff staffData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(staffManagementRepositoryProvider);

      if (state.mode == StaffManagementMode.create) {
        await repository.createInvite(staffData);
      } else if (state.mode == StaffManagementMode.edit) {
        // TODO: Implement update API when available
        // await repository.update(staffData);
        // For now, we simulate update success and just return true
        await Future.delayed(const Duration(milliseconds: 500));
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e, stack) {
      AppLog.e('Failed to save staff: $e', error: e, stackTrace: stack);
      state = state.copyWith(
        isLoading: false,
        error: UserErrorMessage.build(error: e),
      );
      return false;
    }
  }
}

final staffManagementControllerProvider =
    NotifierProvider<StaffManagementController, StaffManagementState>(
      StaffManagementController.new,
    );