import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';

class StockItemImageSection extends StatelessWidget {
  const StockItemImageSection({
    super.key,
    required this.isEditing,
    required this.imageBytes,
    required this.imageUrl,
    required this.onPickImage,
    this.onClearImage,
  });

  final bool isEditing;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final Future<void> Function() onPickImage;
  final VoidCallback? onClearImage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ProductImagePicker(
        size: const Size(160, 149),
        imageBytes: imageBytes,
        imageUrl: imageBytes == null ? imageUrl : null,
        readOnly: !isEditing,
        placeholderLabel: isEditing ? 'Upload image' : 'No image',
        onPickImage: onPickImage,
        onClearLocalSelection: onClearImage,
      ),
    );
  }
}
