import 'package:flutter/material.dart';
import 'package:web/web.dart' as html;
import 'dart:ui_web' as ui;

int _viewIdCounter = 0;

/// Render a network image using a platform view to bypass CanvasKit CORS texture issues.
///
/// Folder: `lib/core/widgets/media/`
Widget buildAdaptiveNetworkImage(
  String url,
  Widget placeholder, {
  double borderRadius = 12,
  BoxFit fit = BoxFit.cover,
}) {
  if (url.isEmpty) return placeholder;
  final viewType = 'menu-img-${_viewIdCounter++}-${url.hashCode}';
  ui.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final element = html.HTMLImageElement()
      ..src = url
      ..style.objectFit = _boxFitToCssObjectFit(fit)
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.borderRadius = '${borderRadius}px'
      ..style.overflow = 'hidden';
    element.onError.listen((_) {
      element.style.display = 'none';
    });
    return element;
  });

  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Stack(
      fit: StackFit.expand,
      children: [
        placeholder,
        HtmlElementView(viewType: viewType),
      ],
    ),
  );
}

String _boxFitToCssObjectFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
    case BoxFit.cover:
    case BoxFit.fitHeight:
    case BoxFit.fitWidth:
      return 'cover';
  }
}
