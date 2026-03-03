import 'package:modular_pos/features/auth/data/dto/user_branch_dto.dart';

class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.name,
    required this.role,
    required this.tenantId,
    required this.phone,
    required this.status,
    required this.branches,
  });

  final String id;
  final String name;
  final String role;
  final String tenantId;
  final String phone;
  final String status;
  final List<UserBranchDto> branches;

  factory AuthUserDto.fromJson(
    Map<String, dynamic> json, {
    List<UserBranchDto> branches = const [],
  }) {
    final id = json['id']?.toString() ??
        json['employeeId']?.toString() ??
        json['employee_id']?.toString() ??
        json['accountId']?.toString() ??
        json['account_id']?.toString() ??
        json['userId']?.toString() ??
        json['user_id']?.toString() ??
        '';

    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString() ?? '';
    final fullName =
        [firstName, lastName].where((e) => e.isNotEmpty).join(' ').trim();

    final inferredRole = (() {
      final jsonRole = (json['role']?.toString() ?? '').trim();
      if (jsonRole.isNotEmpty) return jsonRole;
      if (branches.isNotEmpty && branches.first.role.isNotEmpty) {
        return branches.first.role;
      }
      return '';
    })();

    return AuthUserDto(
      id: id,
      name: (json['name']?.toString() ?? fullName).trim(),
      role: inferredRole,
      tenantId: json['tenantId']?.toString() ?? json['tenant_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      branches: branches,
    );
  }
}
