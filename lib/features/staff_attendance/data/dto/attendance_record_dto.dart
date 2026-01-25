class AttendanceRecordDto {
  const AttendanceRecordDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.employeeId,
    required this.type,
    required this.occurredAt,
    required this.createdAt,
    required this.location,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String employeeId;
  final String type;
  final DateTime occurredAt;
  final DateTime createdAt;
  final AttendanceLocationDto? location;

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String key) =>
        DateTime.tryParse(json[key]?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    AttendanceLocationDto? parseLocation(dynamic value) {
      if (value is! Map<String, dynamic>) return null;
      final lat = value['lat'];
      final lng = value['lng'];
      if (lat is num && lng is num) {
        return AttendanceLocationDto(lat: lat.toDouble(), lng: lng.toDouble());
      }
      return null;
    }

    return AttendanceRecordDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      occurredAt: parseDate('occurredAt'),
      createdAt: parseDate('createdAt'),
      location: parseLocation(json['location']),
    );
  }
}

class AttendanceLocationDto {
  const AttendanceLocationDto({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

