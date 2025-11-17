class User {
  final String id;
  final String name;
  final String role;
  final String tenantId;
  final List<UserBranch> branches;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.tenantId,
    this.branches = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final branchList = (json['branches'] as List<dynamic>?)
            ?.map((b) => UserBranch.fromJson(b as Map<String, dynamic>))
            .toList() ??
        const <UserBranch>[];

    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'cashier',
      tenantId: json['tenantId'] as String? ?? '',
      branches: branchList,
    );
  }
}

class UserBranch {
  const UserBranch({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory UserBranch.fromJson(Map<String, dynamic> json) {
    return UserBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
