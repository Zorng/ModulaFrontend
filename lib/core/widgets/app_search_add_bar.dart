import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/app_add_new_button.dart';
import 'package:modular_pos/core/widgets/app_search_bar.dart';

/// A horizontal bar combining search and add-new actions.
///
/// - On mobile, the search takes most of the width with the add button trailing.
/// - Exposes callbacks for search changes and add action.
class AppSearchAddBar extends StatelessWidget {
  const AppSearchAddBar({
    super.key,
    this.searchHint,
    this.onSearchChanged,
    this.searchController,
    this.onAddPressed,
    this.addButtonLabel = '+ Add new',
  });

  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final VoidCallback? onAddPressed;
  final String addButtonLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < AppBreakpoints.compact;

        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: AppSearchBar(
                hintText: searchHint,
                onChanged: onSearchChanged,
                controller: searchController,
              ),
            ),
            SizedBox(width: isTight ? 8 : 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: IntrinsicWidth(
                child: AppAddNewButton(
                  onPressed: onAddPressed,
                  label: addButtonLabel,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
