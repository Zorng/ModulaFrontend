import 'package:flutter/material.dart';

class InventoryDropdown<T> extends StatelessWidget {
  const InventoryDropdown({
    super.key,
    required this.entries,
    this.initialValue,
    this.onSelected,
    this.label,
    this.requestFocusOnTap = false,
    this.enabled = true,
    this.leadingIcon,
    this.trailingIcon,
    this.helperText,
    this.errorText,
  });

  final List<DropdownMenuEntry<T>> entries;
  final T? initialValue;
  final ValueChanged<T?>? onSelected;
  final Widget? label;
  final bool requestFocusOnTap;
  final bool enabled;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final String? helperText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dropdownWidth = constraints.maxWidth;
        final menuStyle = MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          fixedSize: WidgetStatePropertyAll(Size(dropdownWidth, double.nan)),
        );
        return DropdownMenuTheme(
          data: DropdownMenuThemeData(menuStyle: menuStyle),
          child: DropdownMenu<T>(
            initialSelection: initialValue,
            requestFocusOnTap: requestFocusOnTap,
            width: dropdownWidth,
            label: label,
            dropdownMenuEntries: entries,
            onSelected: onSelected,
            enabled: enabled,
            leadingIcon: leadingIcon,
            trailingIcon: trailingIcon,
            helperText: helperText,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
