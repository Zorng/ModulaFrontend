import 'package:flutter/material.dart';

import 'package:modular_pos/core/theme/app_table_theme.dart';

class AppPaginationBar extends StatelessWidget {
  const AppPaginationBar({
    super.key,
    required this.rangeLabel,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
    this.embedded = false,
  });

  final String rangeLabel;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final rangeTextStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280));

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final previousButton = OutlinedButton(
          onPressed: canGoPrevious && !isLoading ? onPrevious : null,
          child: const Text('Previous'),
        );
        final nextButton = FilledButton(
          onPressed: canGoNext && !isLoading ? onNext : null,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Next'),
        );
        final actions = Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [previousButton, nextButton],
          ),
        );

        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rangeLabel,
                style: rangeTextStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                rangeLabel,
                style: rangeTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(fit: FlexFit.loose, child: actions),
          ],
        );
      },
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: embedded
          ? const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTableTheme.divider)),
            )
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTableTheme.divider),
            ),
      child: content,
    );
  }
}
