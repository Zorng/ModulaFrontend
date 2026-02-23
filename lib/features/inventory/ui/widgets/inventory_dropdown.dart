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
    this.fillColor = Colors.white,
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
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dropdownWidth = constraints.maxWidth;

        final menuStyle = MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          fixedSize: WidgetStatePropertyAll(Size(dropdownWidth, double.nan)),
        );

        return DropdownMenuTheme(
          data: DropdownMenuThemeData(
            menuStyle: menuStyle,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: fillColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownMenu<T>(
                initialSelection: initialValue,
                requestFocusOnTap: requestFocusOnTap,
                width: dropdownWidth,
                label: label,
                dropdownMenuEntries: entries,
                onSelected: onSelected,
                enabled: enabled,
                leadingIcon: leadingIcon,
                trailingIcon: trailingIcon,
                errorText: errorText,
              ),

              /// Helper text (2+ lines supported)
              if (helperText != null && errorText == null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    helperText!,
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),

              /// Error text (shown below helper position)
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    errorText!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
