import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';

class UploadImageTile extends StatelessWidget {
  const UploadImageTile({
    super.key,
    required this.onPressed,
    this.imageBytes,
    this.onClearLocalSelection,
  });

  final VoidCallback onPressed;
  final Uint8List? imageBytes;
  final VoidCallback? onClearLocalSelection;

  @override
  Widget build(BuildContext context) {
    return ProductImagePicker(
      size: const Size(220, 220),
      borderRadius: 16,
      imageBytes: imageBytes,
      onPickImage: () async {
        onPressed();
      },
      placeholderLabel: 'Upload image',
      onClearLocalSelection: onClearLocalSelection,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Uint8List>.has('imageBytes', imageBytes));
  }
}
