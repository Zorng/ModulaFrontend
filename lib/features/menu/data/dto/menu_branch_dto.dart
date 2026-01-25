class MenuBranchDto {
  const MenuBranchDto({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory MenuBranchDto.fromJson(Map<String, dynamic> json) {
    return MenuBranchDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Branch',
    );
  }
}

