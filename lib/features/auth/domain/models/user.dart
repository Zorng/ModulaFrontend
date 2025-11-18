class User {
  final String id;
  final String name;
  final String role;
  final String tenantId;
  final String phone;
  final String status;
  final List<UserBranch> branches;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.tenantId,
    this.phone = '',
    this.status = '',
    this.branches = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final branchList = (json['branches'] as List<dynamic>?)
            ?.map((b) => UserBranch.fromJson(b as Map<String, dynamic>))
            .toList() ??
        const <UserBranch>[];

    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString() ?? '';
    final fullName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ').trim();
    final inferredRole = (() {
      final jsonRole = json['role']?.toString() ?? '';
      if (jsonRole.isNotEmpty) return jsonRole;
      if (branchList.isNotEmpty && branchList.first.role.isNotEmpty) {
        return branchList.first.role;
      }
      return 'cashier';
    })();

    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? fullName,
      role: inferredRole,
      tenantId: json['tenantId'] as String? ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      branches: branchList,
    );
  }
}

class UserBranch {
  const UserBranch({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    this.employeeId = '',
    this.branchId = '',
  });

  final String id;
  final String name;
  final String role;
  final bool active;
  final String employeeId;
  final String branchId;

  factory UserBranch.fromJson(Map<String, dynamic> json) {
    return UserBranch(
      id: json['id']?.toString() ?? '',
      name: json['branch_name']?.toString() ?? json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      active: json['active'] as bool? ?? false,
      employeeId: json['employee_id']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'active': active,
        'employee_id': employeeId,
        'branch_id': branchId,
      };
}
