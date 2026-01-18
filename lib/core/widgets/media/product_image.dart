import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/display/dashed_border_painter.dart';
import 'package:modular_pos/core/widgets/media/network_image_helper_stub.dart'
    if (dart.library.html) 'package:modular_pos/core/widgets/media/network_image_helper_web.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imagePath,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.placeholderColor,
    this.showPlaceholderLabel = true,
    this.placeholderLabel = 'No image',
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderIconSize = 32,
  });

  final String? imagePath;
  final double borderRadius;
  final BoxFit fit;

  final Color? placeholderColor;
  final bool showPlaceholderLabel;
  final String placeholderLabel;
  final IconData placeholderIcon;
  final double placeholderIconSize;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final placeholder = _buildPlaceholder(context);

    if (path == null || path.isEmpty) return placeholder;

    if (path.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          path,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    return buildAdaptiveNetworkImage(
      path,
      placeholder,
      borderRadius: borderRadius,
      fit: fit,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final color = placeholderColor ?? theme.colorScheme.primary;
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: color,
          strokeWidth: 1.4,
          dashWidth: 6,
          dashSpace: 4,
          borderRadius: borderRadius,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(placeholderIcon, color: color, size: placeholderIconSize),
              if (showPlaceholderLabel) ...[
                const SizedBox(height: 6),
                Text(placeholderLabel, style: textStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
