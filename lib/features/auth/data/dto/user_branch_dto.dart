class UserBranchDto {
  const UserBranchDto({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    required this.employeeId,
    required this.branchId,
  });

  final String id;
  final String name;
  final String role;
  final bool active;
  final String employeeId;
  final String branchId;

  factory UserBranchDto.fromJson(Map<String, dynamic> json) {
    final branchObject = json['branch'];
    return UserBranchDto(
      id: json['id']?.toString() ??
          json['assignmentId']?.toString() ??
          json['branchAssignmentId']?.toString() ??
          '',
      name: json['branch_name']?.toString() ??
          json['branchName']?.toString() ??
          json['name']?.toString() ??
          (branchObject is Map ? branchObject['name']?.toString() : null) ??
          '',
      role: json['role']?.toString() ?? '',
      active: _asBool(
        json['active'] ?? json['isActive'] ?? json['enabled'],
        fallback: false,
      ),
      employeeId:
          json['employee_id']?.toString() ?? json['employeeId']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ??
          json['branchId']?.toString() ??
          (branchObject is Map ? branchObject['id']?.toString() : null) ??
          '',
    );
  }
}

bool _asBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.trim().toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

