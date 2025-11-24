class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? imagePath;
  final int stock;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imagePath,
    this.stock = 0,
  });

  /// Creates a [MenuItem] from a JSON map.
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      imagePath: json['imagePath'] as String?,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}