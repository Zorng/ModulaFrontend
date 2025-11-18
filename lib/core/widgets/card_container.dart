import 'package:flutter/material.dart';

/// A responsive container that arranges child widgets in a grid.
///
/// This widget calculates the optimal number of columns based on the available
/// width and arranges the children provided by the [itemBuilder]. It's designed
/// to house widgets like [MenuItemCard].
class CardContainer extends StatelessWidget {
  const CardContainer({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine column count based on width. A smaller divisor (e.g., 160)
        // is needed to ensure two columns appear on mobile.
        final crossAxisCount = (constraints.maxWidth / 160).floor();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount < 1 ? 1 : crossAxisCount,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            childAspectRatio: 0.75,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
