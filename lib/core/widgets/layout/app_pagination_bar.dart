import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';

class AppPaginationBar extends StatelessWidget {
  static const double _itemGap = 8;

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
    if (totalPages != null && totalPages! <= 1) {
      return const SizedBox.shrink();
    }

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
          final useNumericPagination = _supportsNumericPagination;

          final previousButton = FilledButton(
            onPressed: canGoPrevious && !isLoading ? onPrevious : null,
            style: _paginationButtonStyle(context),
            child: const Icon(Icons.chevron_left, size: 18),
          );

          final nextButton = FilledButton(
            onPressed: canGoNext && !isLoading ? onNext : null,
            style: _paginationButtonStyle(context),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right, size: 18),
          );

          final tokenWidgets = useNumericPagination
              ? _buildPageTokens(
                  currentPage: currentPage!,
                  totalPages: totalPages!,
                ).map((token) => _buildToken(context, token)).toList()
              : const <Widget>[];

          final controls = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                previousButton,
                if (useNumericPagination) ...[
                  const SizedBox(width: _itemGap),
                  ..._separated(tokenWidgets),
                  const SizedBox(width: _itemGap),
                ] else
                  const SizedBox(width: _itemGap),
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
      currentPage != null &&
      totalPages != null &&
      totalPages! > 0 &&
      onPageSelected != null;

  Widget _buildToken(BuildContext context, _PaginationToken token) {
    if (token.isEllipsis) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            '...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return FilledButton(
      onPressed: isLoading
          ? null
          : () {
              if (token.page != currentPage) {
                onPageSelected?.call(token.page!);
              }
            },
      style: _paginationButtonStyle(
        context,
        isCurrentPage: token.page == currentPage,
      ),
      child: Text('${token.page}'),
    );
  }

  List<Widget> _separated(List<Widget> children) {
    if (children.isEmpty) return const <Widget>[];
    final widgets = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        widgets.add(const SizedBox(width: _itemGap));
      }
      widgets.add(children[index]);
    }
    return widgets;
  }

  ButtonStyle _paginationButtonStyle(
    BuildContext context, {
    bool isCurrentPage = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = isCurrentPage ? scheme.primary : AppTableTheme.divider;
    final backgroundColor = isCurrentPage ? scheme.primary : Colors.white;
    final foregroundColor = isCurrentPage ? scheme.onPrimary : scheme.onSurface;

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.white;
        }
        return backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return foregroundColor;
      }),
      textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge),
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      maximumSize: const WidgetStatePropertyAll(Size(40, 40)),
      fixedSize: const WidgetStatePropertyAll(Size(40, 40)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.disabled)
            ? borderColor.withValues(alpha: 0.45)
            : borderColor;
        return BorderSide(color: color);
      }),
    );
  }

  List<_PaginationToken> _buildPageTokens({
    required int currentPage,
    required int totalPages,
  }) {
    if (totalPages <= 0) {
      return const [];
    }

    if (totalPages <= 7) {
      return List<_PaginationToken>.generate(
        totalPages,
        (index) => _PaginationToken.page(index + 1),
      );
    }

    final tokens = <_PaginationToken>[];

    void addPage(int page) {
      if (tokens.any((token) => token.page == page && !token.isEllipsis)) {
        return;
      }
      tokens.add(_PaginationToken.page(page));
    }

    void addEllipsisIfNeeded() {
      if (tokens.isEmpty || tokens.last.isEllipsis) return;
      tokens.add(const _PaginationToken.ellipsis());
    }

    if (currentPage <= 3) {
      for (var page = 1; page <= 5; page++) {
        addPage(page);
      }
      addEllipsisIfNeeded();
      addPage(totalPages);
      return tokens;
    }

    if (currentPage >= totalPages - 2) {
      addPage(1);
      addEllipsisIfNeeded();
      for (var page = totalPages - 3; page <= totalPages; page++) {
        addPage(page);
      }
      return tokens;
    }

    addPage(1);
    addEllipsisIfNeeded();
    for (var page = currentPage - 2; page <= currentPage + 2; page++) {
      addPage(page);
    }
    addEllipsisIfNeeded();
    addPage(totalPages);
    return tokens;
  }
}

class _PaginationToken {
  const _PaginationToken.page(this.page) : isEllipsis = false;
  const _PaginationToken.ellipsis() : page = null, isEllipsis = true;

  final int? page;
  final bool isEllipsis;
}
