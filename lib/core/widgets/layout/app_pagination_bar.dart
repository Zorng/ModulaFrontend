import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
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
    this.currentPage,
    this.totalPages,
    this.onPageSelected,
    this.embedded = false,
  });

  final String rangeLabel;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final int? currentPage;
  final int? totalPages;
  final ValueChanged<int>? onPageSelected;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final rangeTextStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280));

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useNumericPagination =
              _supportsNumericPagination && constraints.maxWidth >= 720;

          final previousButton = FilledButton(
            onPressed: canGoPrevious && !isLoading ? onPrevious : null,
            style: _navigationButtonStyle(context, primary: false),
            child: const Text('Previous'),
          );

          final nextButton = FilledButton(
            onPressed: canGoNext && !isLoading ? onNext : null,
            style: _navigationButtonStyle(context, primary: true),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Next'),
          );

          final controls = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                previousButton,
                if (useNumericPagination) ...[
                  const SizedBox(width: 12),
                  ..._buildPageTokens(
                    currentPage: currentPage!,
                    totalPages: totalPages!,
                  ).expand(
                    (token) => [
                      if (token.isEllipsis)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        )
                      else
                        FilledButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (token.page != currentPage) {
                                    onPageSelected?.call(token.page!);
                                  }
                                },
                          style: _pageButtonStyle(
                            context,
                            isCurrentPage: token.page == currentPage,
                          ),
                          child: Text('${token.page}'),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ] else
                  const SizedBox(width: 12),
                nextButton,
              ],
            ),
          );

          return Row(
            children: [
              Expanded(
                child: Text(
                  rangeLabel,
                  style: rangeTextStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                fit: FlexFit.loose,
                child: Align(alignment: Alignment.centerRight, child: controls),
              ),
            ],
          );
        },
      ),
    );
  }

  bool get _supportsNumericPagination =>
      currentPage != null && totalPages != null && onPageSelected != null;

  ButtonStyle _navigationButtonStyle(
    BuildContext context, {
    required bool primary,
  }) {
    final base = primary
        ? AppButtons.primary(context, compact: true)
        : AppButtons.secondary(context, compact: true);
    return base.copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  ButtonStyle _pageButtonStyle(
    BuildContext context, {
    required bool isCurrentPage,
  }) {
    final base = isCurrentPage
        ? AppButtons.primary(context, compact: true)
        : AppButtons.secondary(context, compact: true);
    return base.copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      maximumSize: const WidgetStatePropertyAll(Size(48, 40)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<_PaginationToken> _buildPageTokens({
    required int currentPage,
    required int totalPages,
  }) {
    if (totalPages <= 0) {
      return const [];
    }

    const windowSize = 5;
    var start = currentPage - 2;
    var end = currentPage + 2;

    if (start < 1) {
      end += 1 - start;
      start = 1;
    }
    if (end > totalPages) {
      start -= end - totalPages;
      end = totalPages;
    }

    start = start.clamp(1, totalPages);
    if (end - start + 1 > windowSize) {
      start = end - windowSize + 1;
    }

    final tokens = <_PaginationToken>[];
    if (start > 1) {
      tokens.add(const _PaginationToken.page(1));
      if (start > 2) {
        tokens.add(const _PaginationToken.ellipsis());
      }
    }

    for (var page = start; page <= end; page++) {
      tokens.add(_PaginationToken.page(page));
    }

    if (end < totalPages) {
      if (end < totalPages - 1) {
        tokens.add(const _PaginationToken.ellipsis());
      }
      tokens.add(_PaginationToken.page(totalPages));
    }

    return tokens;
  }
}

class _PaginationToken {
  const _PaginationToken.page(this.page) : isEllipsis = false;
  const _PaginationToken.ellipsis() : page = null, isEllipsis = true;

  final int? page;
  final bool isEllipsis;
}
