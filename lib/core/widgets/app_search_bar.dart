import 'package:flutter/material.dart';

/// A styled search input field with a clear button.
///
/// This widget is self-contained and manages the visibility of the clear
/// button based on whether the input field has text.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.controller,
  });

  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _showClearButton = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _showClearButton = _controller.text.isNotEmpty;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Search...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _showClearButton
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: _controller.clear,
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    // Only dispose the controller if it was created internally.
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}
