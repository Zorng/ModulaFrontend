import 'package:flutter/material.dart';
import 'package:web/web.dart' as html;
import 'dart:ui_web' as ui;

int _viewIdCounter = 0;

/// Render a network image using a platform view to bypass CanvasKit CORS texture issues.
///
/// Folder: `lib/core/widgets/media/`
Widget buildAdaptiveNetworkImage(String url, Widget placeholder) {
  if (url.isEmpty) return placeholder;
  final viewType = 'menu-img-${_viewIdCounter++}-${url.hashCode}';
  ui.platformViewRegistry.registerViewFactory(viewType, (int _) {
    final element = html.HTMLImageElement()
      ..src = url
      ..style.objectFit = 'cover'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.borderRadius = '12px'
      ..style.overflow = 'hidden';
    element.onError.listen((_) {});
    return element;
  });

  return HtmlElementView(viewType: viewType);
}
