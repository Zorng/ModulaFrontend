import 'package:flutter/material.dart';

class InventoryFieldLabel extends StatelessWidget {
  const InventoryFieldLabel({
    super.key,
    required this.text,
    required this.child,
    this.isRequired = false,
    this.isOptional = false,
  });

  final String text;
  final Widget child;
  final bool isRequired;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    final label = isOptional ? '$text (optional)' : text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              text: label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
