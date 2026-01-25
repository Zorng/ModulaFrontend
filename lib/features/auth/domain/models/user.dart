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

  User copyWith({
    String? id,
    String? name,
    String? role,
    String? tenantId,
    String? phone,
    String? status,
    List<UserBranch>? branches,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      tenantId: tenantId ?? this.tenantId,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      branches: branches ?? this.branches,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final branchList = (json['branches'] as List<dynamic>?)
            ?.map((b) => UserBranch.fromJson(b as Map<String, dynamic>))
            .toList() ??
        const <UserBranch>[];

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
      id: id,
      name: json['name'] as String? ?? fullName,
      role: inferredRole,
      tenantId: json['tenantId']?.toString() ?? json['tenant_id']?.toString() ?? '',
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
    final branchObject = json['branch'];
    return UserBranch(
      id: json['id']?.toString() ??
          json['assignmentId']?.toString() ??
          json['branchAssignmentId']?.toString() ??
          '',
      name: json['branch_name']?.toString() ??
          json['branchName']?.toString() ??
          json['name']?.toString() ??
          (branchObject is Map<String, dynamic>
              ? branchObject['name']?.toString()
              : null) ??
          '',
      role: json['role']?.toString() ?? '',
      active: json['active'] as bool? ??
          json['isActive'] as bool? ??
          json['enabled'] as bool? ??
          false,
      employeeId:
          json['employee_id']?.toString() ?? json['employeeId']?.toString() ?? '',
      branchId: json['branch_id']?.toString() ??
          json['branchId']?.toString() ??
          (branchObject is Map<String, dynamic> ? branchObject['id']?.toString() : null) ??
          '',
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
