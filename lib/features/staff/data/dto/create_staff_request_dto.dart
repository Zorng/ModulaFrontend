class InviteStaffRequestDto {
  const InviteStaffRequestDto({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    required this.branchId,
    this.note,
    this.expiresInHours = 48,
    this.password,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String role;
  final String branchId;
  final String? note;
  final int expiresInHours;
  final String? password;

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': role,
      'branch_id': branchId,
      'note': note,
      'expires_in_hours': expiresInHours,
    };
  }
}
