import 'package:flutter/material.dart';

class DefaultSelectorButton extends StatelessWidget {
  const DefaultSelectorButton({
    super.key,
    required this.isSelected,
    required this.onPressed,
  });

  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      color: isSelected ? Theme.of(context).primaryColor : null,
      tooltip: 'Set as default',
    );
  }
}

