import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/display/dashed_border_painter.dart';
import 'package:modular_pos/core/widgets/media/network_image_helper_stub.dart'
    if (dart.library.html) 'package:modular_pos/core/widgets/media/network_image_helper_web.dart';

class ProductImagePicker extends StatelessWidget {
  const ProductImagePicker({
    super.key,
    required this.onPickImage,
    this.imageBytes,
    this.imageUrl,
    this.onClearLocalSelection,
    this.readOnly = false,
    this.size = const Size(160, 149),
    this.borderRadius = 12,
    this.placeholderLabel = 'Upload image',
    this.placeholderIcon = Icons.image_outlined,
    this.showTapToChangeHint = true,
  });

  final Future<void> Function() onPickImage;
  final Uint8List? imageBytes;
  final String? imageUrl;

  /// Clears only the local (in-memory) selection; this does not delete the
  /// previously uploaded remote image.
  final VoidCallback? onClearLocalSelection;

  final bool readOnly;
  final Size size;
  final double borderRadius;
  final String placeholderLabel;
  final IconData placeholderIcon;
  final bool showTapToChangeHint;

  bool get _hasLocal => imageBytes != null;

  bool get _hasRemote => imageUrl != null && imageUrl!.trim().isNotEmpty;

  bool get _hasAnyImage => _hasLocal || _hasRemote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outlineVariant;
    final placeholder = _buildPlaceholder(outline);

    final Widget imageContent;
    if (_hasLocal) {
      imageContent = Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else if (_hasRemote) {
      imageContent = buildAdaptiveNetworkImage(
        imageUrl!.trim(),
        placeholder,
        borderRadius: borderRadius,
        fit: BoxFit.cover,
      );
    } else {
      imageContent = placeholder;
    }

    final bool canInteract = !readOnly;
    final bool showClear =
        canInteract && _hasLocal && onClearLocalSelection != null;

    final Widget body = _hasAnyImage
        ? Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: imageContent),
              if (showClear)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onClearLocalSelection,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (canInteract && showTapToChangeHint)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tap to change',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          )
        : imageContent;

    return Center(
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: outline,
          strokeWidth: 1,
          dashWidth: 4,
          dashSpace: 4,
          borderRadius: borderRadius,
        ),
        child: InkWell(
          onTap: canInteract ? onPickImage : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: body,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color outline) {
    final labelColor = const Color(0xFFCBCBCB);
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(placeholderIcon, size: 40, color: labelColor),
          const SizedBox(height: 8),
          Text(
            placeholderLabel,
            style: const TextStyle(fontSize: 12, color: Color(0xFFCBCBCB)),
          ),
        ],
      ),
    );
  }
}
