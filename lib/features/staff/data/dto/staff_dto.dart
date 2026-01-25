class StaffDto {
  const StaffDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.role,
    required this.branchName,
    required this.branchId,
    required this.status,
    required this.recordType,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String role;
  final String branchName;
  final String? branchId;
  final String status;
  final String recordType;

  factory StaffDto.fromJson(Map<String, dynamic> json) {
    return StaffDto(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? '',
      branchId: json['branch_id']?.toString(),
      status: json['status']?.toString() ?? '',
      recordType: json['record_type']?.toString() ?? '',
    );
  }
}

