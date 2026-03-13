class AttendanceLocationVerification {
  const AttendanceLocationVerification({
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
}

class AttendanceAccountSummary {
  const AttendanceAccountSummary({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;

  String get displayName {
    final parts = <String>[
      if ((firstName ?? '').trim().isNotEmpty) firstName!.trim(),
      if ((lastName ?? '').trim().isNotEmpty) lastName!.trim(),
    ];
    final fullName = parts.join(' ').trim();
    if (fullName.isNotEmpty) return fullName;
    return phone.trim().isEmpty ? id : phone.trim();
  }
}

class AttendanceBranchSummary {
  const AttendanceBranchSummary({required this.id, required this.name});

  final String id;
  final String name;
}

class StaffAttendanceReviewRecord {
  const StaffAttendanceReviewRecord({
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
  final AttendanceLocationVerification? locationVerification;
  final String? forceEndedByAccountId;
  final String? forceEndReason;
  final AttendanceAccountSummary account;
  final AttendanceBranchSummary branch;

  String get typeLabel {
    final normalized = type.trim().toUpperCase();
    if (normalized.isEmpty) return 'Unknown';
    return normalized
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0]}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}
