import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/staff_management_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

final staffManagementStoreProvider =
    AsyncNotifierProvider<StaffManagementStore, void>(StaffManagementStore.new);

class StaffManagementStore extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state
  }

  Future<Staff> createInvite(Staff staff) async {
    final repository = ref.read(staffManagementRepositoryProvider);
    return await repository.createInvite(staff);
  }
}
