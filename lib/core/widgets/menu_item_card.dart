import 'package:flutter/material.dart';

/// A card widget to display a menu item with an image, title, category, and price.
///
/// This is a core component for the sales and menu management screens.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    this.imagePath,
    required this.title,
    required this.category,
    required this.price,
    this.onTap,
  });

  // Made imagePath optional for placeholder
  final String? imagePath;
  final String title;
  final String category;
  final double price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The vertical padding was removed here (top/bottom) to prevent overflow.
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: AspectRatio(
                aspectRatio: 160 / 142, // Keeps the 1:1 ratio
                child: _buildImage(context),
              ),
            ),
            // Use Expanded to allow the text section to fill remaining space,
            // preventing vertical overflow.
            Expanded(
              child: Padding(
                // Reduce vertical padding to finally eliminate the overflow.
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          // Replace Chip with a more lightweight Container to prevent overflow.
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(category, style: textTheme.bodySmall),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: textTheme.titleSmall?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    } else {
      return _buildPlaceholder(context);
    }
  }

  /// A private helper widget to show a consistent placeholder.
  Widget _buildPlaceholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: scheme.primary),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_outlined,
                color: scheme.outline,
                size: 36,
              ),
              const SizedBox(height: 6),
              Text(
                'No image',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    Path createPath(Rect rect) {
      return Path()
        ..addRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        );
    }

    final path = createPath(Offset.zero & size);
    double distance = 0.0;
    final totalLength = path.computeMetrics().fold<double>(0.0, (sum, metric) => sum + metric.length);

    while (distance < totalLength) {
      for (final metric in path.computeMetrics()) {
        final start = metric.getTangentForOffset(distance)?.position;
        final end = metric.getTangentForOffset(
          (distance + dashWidth).clamp(0.0, metric.length),
        )?.position;
        if (start != null && end != null) {
          canvas.drawLine(start, end, paint);
        }
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
