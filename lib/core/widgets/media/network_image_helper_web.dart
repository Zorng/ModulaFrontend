import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as html;

int _viewIdCounter = 0;

Widget buildAdaptiveNetworkImage(
  String url,
  Widget placeholder, {
  double borderRadius = 12,
  BoxFit fit = BoxFit.cover,
}) {
  if (url.isEmpty) return placeholder;
  return _AdaptiveWebNetworkImage(
    url: url,
    placeholder: placeholder,
    borderRadius: borderRadius,
    fit: fit,
  );
}

class _AdaptiveWebNetworkImage extends StatefulWidget {
  const _AdaptiveWebNetworkImage({
    required this.url,
    required this.placeholder,
    required this.borderRadius,
    required this.fit,
  });

  final String url;
  final Widget placeholder;
  final double borderRadius;
  final BoxFit fit;

  @override
  State<_AdaptiveWebNetworkImage> createState() => _AdaptiveWebNetworkImageState();
}

class _AdaptiveWebNetworkImageState extends State<_AdaptiveWebNetworkImage> {
  late String _viewType;
  bool _isReady = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _registerFactory();
  }

  @override
  void didUpdateWidget(covariant _AdaptiveWebNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url &&
        oldWidget.borderRadius == widget.borderRadius &&
        oldWidget.fit == widget.fit) {
      return;
    }
    _isReady = false;
    _hasFailed = false;
    _registerFactory();
  }

  void _registerFactory() {
    _viewType = 'stock-item-img-${_viewIdCounter++}-${widget.url.hashCode}';
    ui.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final element = html.HTMLImageElement()
        ..src = widget.url
        ..style.objectFit = _boxFitToCssObjectFit(widget.fit)
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '${widget.borderRadius}px'
        ..style.overflow = 'hidden';
      element.onLoad.listen((_) {
        if (!mounted) return;
        setState(() {
          _isReady = true;
          _hasFailed = false;
        });
      });
      element.onError.listen((_) {
        if (!mounted) return;
        setState(() {
          _isReady = false;
          _hasFailed = true;
        });
      });
      return element;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.placeholder,
          if (_isReady && !_hasFailed) HtmlElementView(viewType: _viewType),
        ],
      ),
    );
  }
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
