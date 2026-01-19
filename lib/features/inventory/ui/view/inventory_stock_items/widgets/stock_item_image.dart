import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/media/product_image.dart';

class StockItemImage extends StatelessWidget {
  const StockItemImage({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: ProductImage(
        imagePath: imageUrl,
        borderRadius: 12,
        placeholderIconSize: 24,
        showPlaceholderLabel: false,
      ),
    );
  }
}

