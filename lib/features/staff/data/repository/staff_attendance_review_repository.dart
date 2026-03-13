import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/staff/data/api/staff_attendance_review_api.dart';
import 'package:modular_pos/features/staff/domain/models/staff_attendance_review_models.dart';

abstract class StaffAttendanceReviewRepository {
  Future<List<StaffAttendanceReviewRecord>> fetchTenantAttendance({
    String? branchId,
    String? accountId,
    String? occurredFrom,
    String? occurredTo,
    int limit = 50,
    int offset = 0,
  });
}

final staffAttendanceReviewRepositoryProvider =
    Provider<StaffAttendanceReviewRepository>((ref) {
      final api = ref.read(staffAttendanceReviewApiProvider);
      return RemoteStaffAttendanceReviewRepository(api);
    });

class RemoteStaffAttendanceReviewRepository
    implements StaffAttendanceReviewRepository {
  const RemoteStaffAttendanceReviewRepository(this._api);

  final StaffAttendanceReviewApi _api;

  @override
  Future<List<StaffAttendanceReviewRecord>> fetchTenantAttendance({
    String? branchId,
    String? accountId,
    String? occurredFrom,
    String? occurredTo,
    int limit = 50,
    int offset = 0,
  }) async {
    final dtos = await _api.fetchTenantAttendance(
      branchId: branchId,
      accountId: accountId,
      occurredFrom: occurredFrom,
      occurredTo: occurredTo,
      limit: limit,
      offset: offset,
    );
    return dtos
        .map(
          (dto) => StaffAttendanceReviewRecord(
            id: dto.id,
            tenantId: dto.tenantId,
            branchId: dto.branchId,
            accountId: dto.accountId,
            type: dto.type,
            occurredAt: dto.occurredAt,
            createdAt: dto.createdAt,
            locationVerification: dto.locationVerification == null
                ? null
                : AttendanceLocationVerification(
                    observedLatitude: dto.locationVerification!.observedLatitude,
                    observedLongitude:
                        dto.locationVerification!.observedLongitude,
                    observedAccuracyMeters:
                        dto.locationVerification!.observedAccuracyMeters,
                    capturedAt: dto.locationVerification!.capturedAt,
                    status: dto.locationVerification!.status,
                    reason: dto.locationVerification!.reason,
                    distanceMeters: dto.locationVerification!.distanceMeters,
                  ),
            forceEndedByAccountId: dto.forceEndedByAccountId,
            forceEndReason: dto.forceEndReason,
            account: AttendanceAccountSummary(
              id: dto.account.id,
              phone: dto.account.phone,
              firstName: dto.account.firstName,
              lastName: dto.account.lastName,
            ),
            branch: AttendanceBranchSummary(
              id: dto.branch.id,
              name: dto.branch.name,
            ),
          ),
        )
        .toList(growable: false);
  }
}
