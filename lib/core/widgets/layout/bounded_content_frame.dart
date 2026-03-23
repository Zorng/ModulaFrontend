import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/responsive.dart';

class BoundedContentFrame extends StatelessWidget {
  const BoundedContentFrame({
    super.key,
    required this.child,
    this.maxWidth = 960,
    this.topPadding = 16,
    this.bottomPadding = 24,
    this.horizontalPadding,
  });

  final Widget child;
  final double maxWidth;
  final double topPadding;
  final double bottomPadding;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedHorizontalPadding =
            horizontalPadding ??
            _defaultHorizontalPadding(constraints.maxWidth);
        final padding = EdgeInsets.fromLTRB(
          resolvedHorizontalPadding,
          topPadding,
          resolvedHorizontalPadding,
          bottomPadding,
        );
        final availableHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - padding.vertical)
                  .clamp(0.0, double.infinity)
                  .toDouble()
            : null;

        return Padding(
          padding: padding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SizedBox(
                width: double.infinity,
                height: availableHeight,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  double _defaultHorizontalPadding(double width) {
    if (width >= AppBreakpoints.medium) {
      return 24;
    }
    if (width >= AppBreakpoints.small) {
      return 20;
    }
    return 16;
  }
}
