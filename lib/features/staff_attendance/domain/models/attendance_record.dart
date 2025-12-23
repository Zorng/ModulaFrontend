class AttendanceLocation {
  const AttendanceLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.employeeId,
    required this.type,
    required this.occurredAt,
    required this.createdAt,
    this.location,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String employeeId;
  final String type;
  final DateTime occurredAt;
  final DateTime createdAt;
  final AttendanceLocation? location;
}
