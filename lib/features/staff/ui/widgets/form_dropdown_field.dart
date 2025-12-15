import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// A reusable widget for a labeled dropdown field in the form.
class FormDropdownField extends StatelessWidget {
  const FormDropdownField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.value,
    required this.items,
    required this.onSelected,
    this.validator,
  });

  final String label;
  final String placeholder;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onSelected;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        FormField<String>(
          initialValue: value,
          validator: validator,
          builder: (FormFieldState<String> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PopupMenuButton<String>(
                  key: key,
                  color: Colors.white,
                  offset: const Offset(0, 50),
                  onSelected: (String? newValue) {
                    field.didChange(newValue);
                    onSelected(newValue);
                  },
                  itemBuilder: (BuildContext context) {
                    final RenderBox? button = key.currentContext?.findRenderObject() as RenderBox?;
                    final double width = button?.size.width ?? 150;
                    const double horizontalPadding = 32.0;
                    return items.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: SizedBox(
                          width: width - horizontalPadding,
                          child: Text(choice),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: field.hasError ? Border.all(color: Colors.red, width: 1.0) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            field.value ?? placeholder,
                            style: TextStyle(
                              fontSize: 16,
                              color: field.value == null ? CupertinoColors.placeholderText : CupertinoColors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, color: CupertinoColors.placeholderText),
                      ],
                    ),
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, top: 5.0),
                    child: Text(field.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}