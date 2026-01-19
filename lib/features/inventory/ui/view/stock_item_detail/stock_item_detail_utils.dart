import 'package:modular_pos/features/auth/domain/models/user.dart';

String initialsFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

String branchName(String? id, List<UserBranch> branches) {
  if (id == null) return 'Unknown';
  final match = branches.firstWhere(
    (b) => (b.branchId.isNotEmpty ? b.branchId : b.id) == id,
    orElse: () => UserBranch(
      id: id,
      name: 'Branch $id',
      role: '',
      active: true,
    ),
  );
  return match.name;
}

