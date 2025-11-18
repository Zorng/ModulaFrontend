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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AspectRatio(
                aspectRatio: 160 / 142, // Keeps the 1:1 ratio
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