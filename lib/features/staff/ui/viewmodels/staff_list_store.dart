import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/data/staff_management_repository.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

class StaffListState {
  final List<Staff> staffList;
  final List<String> branchOptions;
  final String? selectedBranch;
  final String? selectedRole;
  final String? selectedStatus;
  final String searchQuery;
  final int maxStaffLimit;

  const StaffListState({
    this.staffList = const [],
    this.branchOptions = const [],
    this.selectedBranch,
    this.selectedRole,
    this.selectedStatus,
    this.searchQuery = '',
    this.maxStaffLimit = 100,
  });

  StaffListState copyWith({
    List<Staff>? staffList,
    List<String>? branchOptions,
    String? selectedBranch,
    bool clearSelectedBranch = false,
    String? selectedRole,
    bool clearSelectedRole = false,
    String? selectedStatus,
    bool clearSelectedStatus = false,
    String? searchQuery,
    int? maxStaffLimit,
  }) {
    return StaffListState(
      staffList: staffList ?? this.staffList,
      branchOptions: branchOptions ?? this.branchOptions,
      selectedBranch: clearSelectedBranch
          ? null
          : (selectedBranch ?? this.selectedBranch),
      selectedRole: clearSelectedRole
          ? null
          : (selectedRole ?? this.selectedRole),
      selectedStatus: clearSelectedStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      maxStaffLimit: maxStaffLimit ?? this.maxStaffLimit,
    );
  }
}

class StaffListAsyncNotifier extends AsyncNotifier<StaffListState> {
  @override
  Future<StaffListState> build() async {
    final user = ref.watch(loginControllerProvider).user;
    final branches = user?.branches ?? const [];
    final options = branches
        .map((b) => b.name)
        .where((name) => name.isNotEmpty)
        .toList();

    final initialState = StaffListState(
      branchOptions: options,
      selectedBranch: user?.role.toLowerCase() != 'admin' && options.isNotEmpty
          ? options.first
          : null,
    );

    final user2 = ref.read(loginControllerProvider).user;
    final isAdmin = user2?.role.toLowerCase() == 'admin';
    final branchId = isAdmin
        ? null
        : _branchIdForName(initialState.selectedBranch);
    final repo = ref.read(staffManagementRepositoryProvider);
    final rawStaff = await repo.fetchStaff(branchId: branchId);

    final validStaff = rawStaff.whereType<Staff>().toList();

    return initialState.copyWith(staffList: validStaff);
  }

  static final provider =
      AsyncNotifierProvider<StaffListAsyncNotifier, StaffListState>(
        () => StaffListAsyncNotifier(),
      );

  String? _branchIdForName(String? name) {
    if (name == null) return null;
    final branches =
        ref.read(loginControllerProvider).user?.branches ?? const [];
    final match = branches.firstWhere(
      (b) => b.name == name,
      orElse: () => const UserBranch(id: '', name: '', role: '', active: false),
    );
    if (match.id.isEmpty && match.branchId.isEmpty) return null;
    return match.branchId.isNotEmpty ? match.branchId : match.id;
  }

  void updateSearchQuery(String query) {
    state = AsyncData(state.value!.copyWith(searchQuery: query));
  }

  void updateSelectedBranch(String? value) {
    debugPrint('DEBUG: updateSelectedBranch called with value: $value');
    debugPrint('DEBUG: Current selectedBranch: ${state.value?.selectedBranch}');
    // Handle the '__all__' sentinel value from DropdownMenu
    final actualValue = value == '__all__' ? null : value;
    state = AsyncData(
      state.value!.copyWith(
        selectedBranch: actualValue,
        clearSelectedBranch: actualValue == null,
      ),
    );
    debugPrint('DEBUG: New selectedBranch: ${state.value?.selectedBranch}');
  }

  void updateSelectedRole(String? value) {
    // Handle the '__all__' sentinel value from DropdownMenu
    final actualValue = value == '__all__' ? null : value;
    state = AsyncData(
      state.value!.copyWith(
        selectedRole: actualValue,
        clearSelectedRole: actualValue == null,
      ),
    );
  }

  void updateSelectedStatus(String? value) {
    // Handle the '__all__' sentinel value from DropdownMenu
    final actualValue = value == '__all__' ? null : value;
    state = AsyncData(
      state.value!.copyWith(
        selectedStatus: actualValue,
        clearSelectedStatus: actualValue == null,
      ),
    );
  }

  Future<void> reloadStaff() async {
    // Capture current state before setting to loading
    final currentState = state.value;
    state = const AsyncLoading();
    try {
      final user = ref.read(loginControllerProvider).user;
      final isAdmin = user?.role.toLowerCase() == 'admin';
      final branchId = isAdmin
          ? null
          : _branchIdForName(currentState?.selectedBranch);
      final repo = ref.read(staffManagementRepositoryProvider);
      final rawStaff = await repo.fetchStaff(branchId: branchId);

      final validStaff = rawStaff.whereType<Staff>().toList();

      // Preserve filter state when reloading
      final newState =
          currentState?.copyWith(staffList: validStaff) ??
          StaffListState(staffList: validStaff);
      state = AsyncData(newState);
    } catch (e, stack) {
      // Restore previous state on error if available
      if (currentState != null) {
        state = AsyncData(currentState);
      }
      state = AsyncError('Failed to load staff: $e', stack);
    }
  }

  void updateStaff(Staff updatedStaff) {
    final current = state.value!;
    final index = current.staffList.indexWhere(
      (item) => item.id == updatedStaff.id,
    );
    if (index != -1) {
      final newList = List<Staff>.from(current.staffList);
      newList[index] = updatedStaff;
      state = AsyncData(current.copyWith(staffList: newList));
    }
  }

  List<Staff> getFilteredStaff() {
    final data = state.value!;
    final search = data.searchQuery.trim().toLowerCase();
    final validStaff = data.staffList.whereType<Staff>().toList();
    return validStaff.where((staff) {
      final matchesSearch =
          search.isEmpty ||
          (staff.userName.toLowerCase().contains(search)) ||
          (staff.phoneNumber.toLowerCase().contains(search));
      final matchesRole =
          data.selectedRole == null || staff.role == data.selectedRole;
      final matchesStatus =
          data.selectedStatus == null || staff.status == data.selectedStatus;
      final matchesBranch =
          data.selectedBranch == null || staff.branch == data.selectedBranch;
      return matchesSearch && matchesRole && matchesStatus && matchesBranch;
    }).toList();
  }

  String? getBranchIdForAdd() => _branchIdForName(state.value!.selectedBranch);

  /// Get active staff count (for limit checking)
  int getActiveStaffCount() {
    final data = state.value;
    if (data == null) return 0;
    return data.staffList.where((s) => s.isActive).length;
  }

  /// Check if staff limit is reached
  bool isStaffLimitReached() {
    final data = state.value;
    if (data == null) return false;
    final activeCount = getActiveStaffCount();
    return activeCount >= data.maxStaffLimit;
  }
}
