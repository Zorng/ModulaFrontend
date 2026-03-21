import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/media/network_image_view_type.dart';
import 'package:web/web.dart' as html;

final Set<String> _registeredViewTypes = <String>{};

Widget buildAdaptiveNetworkImage(
  String url,
  Widget placeholder, {
  double borderRadius = 12,
  BoxFit fit = BoxFit.cover,
}) {
  if (url.isEmpty) return placeholder;
  final normalizedUrl = url.trim();
  final viewType = buildNetworkImageViewType(
    url: normalizedUrl,
    borderRadius: borderRadius,
    fit: fit,
  );
  if (_registeredViewTypes.add(viewType)) {
    ui.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final element = html.HTMLImageElement()
        ..src = normalizedUrl
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
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Stack(
      fit: StackFit.expand,
      children: [
        placeholder,
        HtmlElementView(key: ValueKey(viewType), viewType: viewType),
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
