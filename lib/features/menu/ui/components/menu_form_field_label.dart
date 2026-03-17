import 'package:flutter/material.dart';

class MenuFormFieldLabel extends StatelessWidget {
  const MenuFormFieldLabel({
    super.key,
    required this.text,
    this.isRequired = false,
    this.isOptional = false,
  });

  final String text;
  final bool isRequired;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        isOptional ? '$text (Optional)' : text,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

