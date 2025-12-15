import 'package:flutter/material.dart';

/// Fallback network image for non-web platforms.
Widget buildAdaptiveNetworkImage(String url, Widget placeholder) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    ),
  );
}
