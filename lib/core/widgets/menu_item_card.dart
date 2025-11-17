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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AspectRatio(
                aspectRatio: 1 / 1, // Keeps the 1:1 ratio
                child: imagePath != null
                    ? Image.asset(
                        imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(context),
                      )
                    // Use placeholder if imagePath is null
                    : _buildPlaceholder(context),
              ),
            ),
            // REMOVED Expanded widget to fix the overflow
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8), // Added space for consistency
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Chip(
                          label: Text(category),
                          labelStyle: textTheme.bodySmall,
                          backgroundColor: Colors.grey[200],
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          ],
        ),
      ),
    );
  }

  /// A private helper widget to show a consistent placeholder.
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      width: double.infinity,
      height: double.infinity,
      child: Icon(
        Icons.local_cafe_outlined, // Example icon
        color: Theme.of(context).colorScheme.surfaceVariant,
        size: 48,
      ),
    );
  }
}