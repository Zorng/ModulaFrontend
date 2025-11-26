class MenuBranch {
  const MenuBranch({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory MenuBranch.fromJson(Map<String, dynamic> json) {
    return MenuBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Branch',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
