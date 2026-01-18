import 'package:flutter/material.dart';

/// Fallback network image for non-web platforms.
///
/// Folder: `lib/core/widgets/media/`
Widget buildAdaptiveNetworkImage(
  String url,
  Widget placeholder, {
  double borderRadius = 12,
  BoxFit fit = BoxFit.cover,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    ),
  );
}
