import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/media/product_image.dart';

class SaleItemDetailImage extends StatelessWidget {
  const SaleItemDetailImage({super.key, this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ProductImage(
      imagePath: imageUrl,
      borderRadius: 12,
      placeholderIconSize: 48,
    );
  }
}
