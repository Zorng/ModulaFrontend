import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/staff/data/repository/staff_shift_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/domain/models/staff_shift_models.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_shift_controller.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_support_providers.dart';
import '../test_utils/riverpod_test_utils.dart';

void main() {
  test('updateInstance forwards date/time/note to repository', () async {
    final repository = _FakeStaffShiftRepository();
    final container = createTestContainer(
      overrides: [
        staffShiftRepositoryProvider.overrideWithValue(repository),
        staffTenantBranchesProvider.overrideWith(
          (ref) async => const [
            BranchListItem(
              branchId: 'branch-1',
              tenantId: 'tenant-1',
              branchName: 'Main Branch',
              status: 'ACTIVE',
            ),
          ],
        ),
        staffMembershipOptionsProvider.overrideWith(
          (ref) async => const [
            StaffMembershipSummary(
              membershipId: 'membership-1',
              tenantId: 'tenant-1',
              accountId: 'account-1',
              roleKey: 'CASHIER',
              membershipStatus: MembershipLifecycleStatus.active,
              phone: '+85512345678',
              firstName: 'John',
              lastName: 'Smith',
              staffProfileStatus: 'ACTIVE',
              invitedAt: null,
              acceptedAt: null,
              rejectedAt: null,
              revokedAt: null,
              pendingBranchIds: <String>[],
              activeBranchIds: <String>['branch-1'],
            ),
          ],
        ),
      ],
    );

    await container.read(staffShiftControllerProvider.future);
    final notifier = container.read(staffShiftControllerProvider.notifier);
    final updatedDate = DateTime(2026, 3, 9);

    await notifier.updateInstance(
      instanceId: 'instance-1',
      date: updatedDate,
      plannedStartTime: '11:00',
      plannedEndTime: '15:00',
      note: 'updated by manager',
    );

    expect(repository.lastUpdatedInstanceId, 'instance-1');
    expect(repository.lastUpdatedDate, updatedDate);
    expect(repository.lastUpdatedStartTime, '11:00');
    expect(repository.lastUpdatedEndTime, '15:00');
    expect(repository.lastUpdatedNote, 'updated by manager');
  });
}

class _FakeStaffShiftRepository implements StaffShiftRepository {
  String? lastUpdatedInstanceId;
  DateTime? lastUpdatedDate;
  String? lastUpdatedStartTime;
  String? lastUpdatedEndTime;
  String? lastUpdatedNote;

  @override
  Future<StaffShiftInstance> cancelInstance({
    required String instanceId,
    required String reason,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StaffShiftInstance> createInstance({
    required String membershipId,
    required String branchId,
    required DateTime date,
    required String plannedStartTime,
    required String plannedEndTime,
    String? note,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StaffShiftPattern> createPattern({
    required String membershipId,
    required String branchId,
    required List<int> daysOfWeek,
    required String plannedStartTime,
    required String plannedEndTime,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? note,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StaffShiftPattern> deactivatePattern({
    required String patternId,
    required String reason,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<StaffShiftSchedule> fetchMySchedule() async {
    return const StaffShiftSchedule(patterns: [], instances: []);
  }

  @override
  Future<StaffShiftSchedule> fetchSchedule({
    required String branchId,
    required String from,
    required String to,
    String? membershipId,
  }) async {
    return const StaffShiftSchedule(patterns: [], instances: []);
  }

  @override
  Future<StaffShiftInstance> updateInstance({
    required String instanceId,
    DateTime? date,
    String? plannedStartTime,
    String? plannedEndTime,
    String? note,
    String? intentId,
  }) async {
    lastUpdatedInstanceId = instanceId;
    lastUpdatedDate = date;
    lastUpdatedStartTime = plannedStartTime;
    lastUpdatedEndTime = plannedEndTime;
    lastUpdatedNote = note;
    return StaffShiftInstance(
      id: instanceId,
      tenantId: 'tenant-1',
      membershipId: 'membership-1',
      branchId: 'branch-1',
      patternId: null,
      date: date ?? DateTime(2026, 3, 8),
      plannedStartTime: plannedStartTime ?? '08:00',
      plannedEndTime: plannedEndTime ?? '17:00',
      status: StaffShiftInstanceStatus.updated,
      note: note,
      createdAt: DateTime(2026, 3, 8),
      updatedAt: DateTime(2026, 3, 8, 12),
    );
  }

  @override
  Future<StaffShiftPattern> updatePattern({
    required String patternId,
    List<int>? daysOfWeek,
    String? plannedStartTime,
    String? plannedEndTime,
    DateTime? effectiveTo,
    String? note,
    String? intentId,
  }) {
    throw UnimplementedError();
  }
}
