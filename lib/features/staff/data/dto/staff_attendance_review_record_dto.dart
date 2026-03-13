import 'package:modular_pos/features/staff/data/api/staff_api_helpers.dart';

class AttendanceLocationVerificationDto {
  const AttendanceLocationVerificationDto({
    required this.observedLatitude,
    required this.observedLongitude,
    required this.observedAccuracyMeters,
    required this.capturedAt,
    required this.status,
    required this.reason,
    required this.distanceMeters,
  });

  final double? observedLatitude;
  final double? observedLongitude;
  final double? observedAccuracyMeters;
  final DateTime? capturedAt;
  final String? status;
  final String? reason;
  final double? distanceMeters;

  factory AttendanceLocationVerificationDto.fromJson(Map<String, dynamic> json) {
    return AttendanceLocationVerificationDto(
      observedLatitude: StaffApiHelpers.parseDouble(json['observedLatitude']),
      observedLongitude: StaffApiHelpers.parseDouble(json['observedLongitude']),
      observedAccuracyMeters: StaffApiHelpers.parseDouble(
        json['observedAccuracyMeters'],
      ),
      capturedAt: StaffApiHelpers.parseDateTime(json['capturedAt']),
      status: json['status']?.toString(),
      reason: json['reason']?.toString(),
      distanceMeters: StaffApiHelpers.parseDouble(json['distanceMeters']),
    );
  }
}

class AttendanceAccountSummaryDto {
  const AttendanceAccountSummaryDto({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;

  factory AttendanceAccountSummaryDto.fromJson(Map<String, dynamic> json) {
    return AttendanceAccountSummaryDto(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
    );
  }
}

class AttendanceBranchSummaryDto {
  const AttendanceBranchSummaryDto({required this.id, required this.name});

  final String id;
  final String name;

  factory AttendanceBranchSummaryDto.fromJson(Map<String, dynamic> json) {
    return AttendanceBranchSummaryDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class StaffAttendanceReviewRecordDto {
  const StaffAttendanceReviewRecordDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.accountId,
    required this.type,
    required this.occurredAt,
    required this.createdAt,
    required this.locationVerification,
    required this.forceEndedByAccountId,
    required this.forceEndReason,
    required this.account,
    required this.branch,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String accountId;
  final String type;
  final DateTime occurredAt;
  final DateTime createdAt;
  final AttendanceLocationVerificationDto? locationVerification;
  final String? forceEndedByAccountId;
  final String? forceEndReason;
  final AttendanceAccountSummaryDto account;
  final AttendanceBranchSummaryDto branch;

  factory StaffAttendanceReviewRecordDto.fromJson(Map<String, dynamic> json) {
    final locationRaw = json['locationVerification'];
    final accountRaw = json['account'];
    final branchRaw = json['branch'];
    return StaffAttendanceReviewRecordDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      accountId: json['accountId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      occurredAt:
          StaffApiHelpers.parseDateTime(json['occurredAt']) ?? DateTime(1970),
      createdAt:
          StaffApiHelpers.parseDateTime(json['createdAt']) ?? DateTime(1970),
      locationVerification: locationRaw is Map<String, dynamic>
          ? AttendanceLocationVerificationDto.fromJson(locationRaw)
          : null,
      forceEndedByAccountId: json['forceEndedByAccountId']?.toString(),
      forceEndReason: json['forceEndReason']?.toString(),
      account: AttendanceAccountSummaryDto.fromJson(
        accountRaw is Map<String, dynamic> ? accountRaw : const {},
      ),
      branch: AttendanceBranchSummaryDto.fromJson(
        branchRaw is Map<String, dynamic> ? branchRaw : const {},
      ),
    );
  }
}
