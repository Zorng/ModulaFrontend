import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/layout/app_pagination_bar.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_workspace_app_bar_actions.dart';
import 'package:modular_pos/features/audit/domain/models/audit_event.dart';
import 'package:modular_pos/features/audit/ui/viewmodels/audit_log_controller.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';

class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  static const String _allBranchesValue = '__all_branches__';
  static const String _allOutcomesValue = '__all_outcomes__';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(loginControllerProvider).session;
      final sessionBranches = _sessionBranchOptions(session);
      final branchState = ref.read(branchControllerProvider);
      if (sessionBranches.isNotEmpty ||
          branchState.branches.isNotEmpty ||
          branchState.isLoading) {
        return;
      }
      ref.read(branchControllerProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditLogControllerProvider);
    final session = ref.watch(loginControllerProvider.select((s) => s.session));
    final branchState = ref.watch(branchControllerProvider);
    final branchOptions = _resolveBranchOptions(session, branchState.branches);
    final branchLookup = {
      for (final option in branchOptions) option.id: option.name,
    };
    final isWide = AppBreakpoints.isLarge(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: isWide
            ? null
            : AppBackButton(
                icon: Icons.home_outlined,
                tooltip: 'Home',
                onPressed: () {
                  final router = GoRouter.maybeOf(context);
                  if (router != null) {
                    context.go(AppRoute.portal.path);
                    return;
                  }
                  Navigator.of(context).maybePop();
                },
              ),
        title: const Text('Audit Log'),
        actions: const [TenantWorkspaceAppBarActions()],
      ),
      body: auditState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AuditLogStatusView(
          icon: Icons.history_toggle_off_outlined,
          title: 'Audit log unavailable',
          message: error.toString(),
          actionLabel: 'Retry',
          onAction: () =>
              ref.read(auditLogControllerProvider.notifier).refresh(),
        ),
        data: (state) {
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () =>
                    ref.read(auditLogControllerProvider.notifier).refresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final useStackedLayout = constraints.maxWidth < 920;
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildScopeBanner(
                          context,
                          selectedBranchId: state.selectedBranchId,
                          branchLookup: branchLookup,
                        ),
                        const SizedBox(height: 16),
                        _AuditFilterBar(
                          state: state,
                          branchLookup: branchLookup,
                          useStackedLayout: useStackedLayout,
                          onFilterPressed: () => _openFilterModal(
                            context,
                            state: state,
                            branchOptions: branchOptions,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state.inlineError != null) ...[
                          _InlineErrorBanner(message: state.inlineError!),
                          const SizedBox(height: 16),
                        ],
                        _buildCountSummary(context, state),
                        const SizedBox(height: 16),
                        if (_visibleItems(state, isWide: isWide).isEmpty)
                          const _AuditLogStatusView(
                            icon: Icons.history_outlined,
                            title: 'No audit events',
                            message:
                                'No audit events matched the current filters.',
                          )
                        else if (isWide)
                          _buildDesktopTable(
                            context,
                            state: state,
                            branchLookup: branchLookup,
                          )
                        else ...[
                          for (final event in _visibleItems(
                            state,
                            isWide: false,
                          )) ...[
                            _AuditEventCard(
                              event: event,
                              branchLabel: _resolveBranchLabel(
                                event.branchId,
                                branchLookup,
                              ),
                              actorLabel: _resolveActorLabel(event),
                              onViewDetails: () => _showEventDetails(
                                context,
                                event: event,
                                branchLabel: _resolveBranchLabel(
                                  event.branchId,
                                  branchLookup,
                                ),
                                actorLabel: _resolveActorLabel(event),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (state.hasMore)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: state.isLoadingMore
                                    ? null
                                    : () => ref
                                          .read(
                                            auditLogControllerProvider.notifier,
                                          )
                                          .loadMore(),
                                icon: state.isLoadingMore
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.expand_more),
                                label: Text(
                                  state.isLoadingMore
                                      ? 'Loading...'
                                      : 'Load more',
                                ),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              if (state.isRefreshing)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: 0.68),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScopeBanner(
    BuildContext context, {
    required String? selectedBranchId,
    required Map<String, String> branchLookup,
  }) {
    final branchId = (selectedBranchId ?? '').trim();
    final branchName = branchLookup[branchId];
    final message = branchId.isEmpty
        ? TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: const [
              TextSpan(text: 'Review tenant audit events across '),
              TextSpan(
                text: 'all branches',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: '. Use filters to narrow action and outcome.'),
            ],
          )
        : TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Review tenant audit events for '),
              TextSpan(
                text: branchName ?? branchId,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '.'),
            ],
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text.rich(message)),
        ],
      ),
    );
  }

  Widget _buildCountSummary(BuildContext context, AuditLogState state) {
    final theme = Theme.of(context);
    return Text(
      state.total == 0
          ? '0 events'
          : 'Showing ${state.items.length} of ${state.total} events',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Future<void> _openFilterModal(
    BuildContext context, {
    required AuditLogState state,
    required List<_AuditBranchOption> branchOptions,
  }) async {
    final result = await _showFilterModal(
      context,
      branchOptions: branchOptions,
      initialDraft: _AuditFilterDraft(
        branchId: state.selectedBranchId ?? '',
        outcome: state.selectedOutcome,
        actionKey: state.actionKeyQuery ?? '',
      ),
    );
    if (!mounted || result == null) return;

    if (result.clearRequested) {
      await ref.read(auditLogControllerProvider.notifier).clearFilters();
      return;
    }

    await ref
        .read(auditLogControllerProvider.notifier)
        .applyFilters(
          branchId: result.branchId,
          actionKey: result.actionKey,
          outcome: result.outcome,
        );
  }

  Future<_AuditFilterDraft?> _showFilterModal(
    BuildContext context, {
    required List<_AuditBranchOption> branchOptions,
    required _AuditFilterDraft initialDraft,
  }) async {
    final isWide = AppBreakpoints.isLarge(MediaQuery.sizeOf(context).width);
    if (isWide) {
      return showDialog<_AuditFilterDraft>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _AuditFilterEditor(
              branchOptions: branchOptions,
              initialDraft: initialDraft,
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<_AuditFilterDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: _AuditFilterEditor(
            branchOptions: branchOptions,
            initialDraft: initialDraft,
          ),
        ),
      ),
    );
  }

  List<AuditEvent> _visibleItems(AuditLogState state, {required bool isWide}) {
    if (!isWide) return state.items;
    if (state.items.length <= state.limit || state.limit <= 0) {
      return state.items;
    }
    final start = state.offset.clamp(0, state.items.length);
    final end = (start + state.limit).clamp(0, state.items.length);
    return state.items.sublist(start, end);
  }

  Widget _buildDesktopTable(
    BuildContext context, {
    required AuditLogState state,
    required Map<String, String> branchLookup,
  }) {
    final visibleItems = _visibleItems(state, isWide: true);
    final totalPages = state.total <= 0 || state.limit <= 0
        ? 1
        : ((state.total - 1) ~/ state.limit) + 1;
    final currentPage = state.limit <= 0
        ? 1
        : (state.offset ~/ state.limit) + 1;
    final rangeStart = state.total == 0 ? 0 : state.offset + 1;
    final rangeEnd = state.offset + visibleItems.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableContentWidth = constraints.maxWidth < 1240
            ? 1240.0
            : constraints.maxWidth;
        final table = Container(
          decoration: BoxDecoration(
            color: AppTableTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTableTheme.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: DataTable(
                horizontalMargin: 16,
                columnSpacing: 20,
                dataRowMinHeight: 62,
                dataRowMaxHeight: 72,
                headingRowColor: WidgetStateProperty.all(
                  AppTableTheme.headerBackground,
                ),
                dataRowColor: const WidgetStatePropertyAll(
                  AppTableTheme.background,
                ),
                dividerThickness: AppTableTheme.dataTableDividerThickness,
                border: AppTableTheme.dataTableBorder,
                columns: const [
                  DataColumn(
                    label: SizedBox(
                      width: 32,
                      child: Text('No.', style: AppTableTheme.headerText),
                    ),
                  ),
                  DataColumn(
                    label: Text('Time', style: AppTableTheme.headerText),
                  ),
                  DataColumn(
                    label: Text('Action', style: AppTableTheme.headerText),
                  ),
                  DataColumn(
                    label: Text('Outcome', style: AppTableTheme.headerText),
                  ),
                  DataColumn(
                    label: Text('Branch', style: AppTableTheme.headerText),
                  ),
                  DataColumn(
                    label: Text('Actor', style: AppTableTheme.headerText),
                  ),
                  DataColumn(
                    label: Text('Action', style: AppTableTheme.headerText),
                  ),
                ],
                rows: List<DataRow>.generate(visibleItems.length, (index) {
                  final event = visibleItems[index];
                  final branchLabel = _resolveBranchLabel(
                    event.branchId,
                    branchLookup,
                  );
                  final actorLabel = _resolveActorLabel(event);
                  final meta = _AuditEventCardMeta.fromEvent(
                    event,
                    branchLabel: branchLabel,
                    actorLabel: actorLabel,
                  );

                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${state.offset + index + 1}',
                            style: AppTableTheme.cellText,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 138,
                          child: Text(
                            meta.formattedTimestamp,
                            style: AppTableTheme.cellText,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            event.actionKey,
                            style: AppTableTheme.cellText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(_AuditOutcomeChip(outcome: event.outcome)),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            branchLabel,
                            style: AppTableTheme.cellText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 160,
                          child: Text(
                            actorLabel,
                            style: AppTableTheme.cellText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: () => _showEventDetails(
                              context,
                              event: event,
                              branchLabel: branchLabel,
                              actorLabel: actorLabel,
                            ),
                            child: const Text('View details'),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableContentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                table,
                if (totalPages > 1) ...[
                  const SizedBox(height: 16),
                  AppPaginationBar(
                    rangeLabel: 'Showing $rangeStart-$rangeEnd entries',
                    currentPage: currentPage,
                    totalPages: totalPages,
                    canGoPrevious: currentPage > 1,
                    canGoNext: currentPage < totalPages,
                    isLoading: state.isRefreshing,
                    onPageSelected: (page) => ref
                        .read(auditLogControllerProvider.notifier)
                        .goToPage(page),
                    onPrevious: () => ref
                        .read(auditLogControllerProvider.notifier)
                        .goToPreviousPage(),
                    onNext: () => ref
                        .read(auditLogControllerProvider.notifier)
                        .goToNextPage(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<_AuditBranchOption> _resolveBranchOptions(
    AuthSession? session,
    List<BranchListItem> loadedBranches,
  ) {
    final sessionBranches = _sessionBranchOptions(session);
    if (sessionBranches.isNotEmpty) return sessionBranches;

    final options = <_AuditBranchOption>[];
    final seen = <String>{};
    for (final branch in loadedBranches) {
      final branchId = branch.branchId.trim();
      final branchName = branch.branchName.trim();
      if (branchId.isEmpty || branchName.isEmpty || !seen.add(branchId)) {
        continue;
      }
      options.add(_AuditBranchOption(id: branchId, name: branchName));
    }
    return options;
  }

  List<_AuditBranchOption> _sessionBranchOptions(AuthSession? session) {
    if (session == null) return const [];
    final activeTenantId = session.establishedTenantId;
    final memberships = session.memberships;
    if (memberships.isEmpty) return const [];

    final membership = memberships.firstWhere(
      (item) => item.tenantId.trim() == activeTenantId,
      orElse: () => memberships.first,
    );
    return _branchOptionsFromMembership(membership);
  }

  List<_AuditBranchOption> _branchOptionsFromMembership(
    TenantMembership membership,
  ) {
    final options = <_AuditBranchOption>[];
    final seen = <String>{};
    for (final branch in membership.branches) {
      final branchId = branch.branchId.trim().isNotEmpty
          ? branch.branchId.trim()
          : branch.id.trim();
      final branchName = branch.name.trim();
      if (branchId.isEmpty || branchName.isEmpty || !seen.add(branchId)) {
        continue;
      }
      options.add(_AuditBranchOption(id: branchId, name: branchName));
    }
    return options;
  }

  String _resolveBranchLabel(
    String? branchId,
    Map<String, String> branchLookup,
  ) {
    final normalized = (branchId ?? '').trim();
    if (normalized.isEmpty) return 'Tenant level';
    return branchLookup[normalized] ?? normalized;
  }

  String _resolveActorLabel(AuditEvent event) {
    final actorId = (event.actorAccountId ?? '').trim();
    final resolved = (event.actorDisplayName ?? '').trim();
    if (resolved.isNotEmpty) return resolved;
    if (actorId.isEmpty) return 'System';
    return 'Account unavailable';
  }

  Future<void> _showEventDetails(
    BuildContext context, {
    required AuditEvent event,
    required String branchLabel,
    required String actorLabel,
  }) async {
    final details = _AuditEventDetailsView(
      event: event,
      branchLabel: branchLabel,
      actorLabel: actorLabel,
    );
    final isWide = MediaQuery.of(context).size.width >= 920;
    if (isWide) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
            child: details,
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, controller) =>
              SingleChildScrollView(controller: controller, child: details),
        ),
      ),
    );
  }
}

class _AuditFilterBar extends StatelessWidget {
  const _AuditFilterBar({
    required this.state,
    required this.branchLookup,
    required this.useStackedLayout,
    required this.onFilterPressed,
  });

  final AuditLogState state;
  final Map<String, String> branchLookup;
  final bool useStackedLayout;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final selectedBranchId = (state.selectedBranchId ?? '').trim();
    final selectedActionKey = (state.actionKeyQuery ?? '').trim();
    final filterStatusItems = [
      _AuditFilterStatusItem(
        label: 'Branch',
        value: selectedBranchId.isEmpty
            ? 'All branches'
            : (branchLookup[selectedBranchId] ?? selectedBranchId),
        isEmphasized: selectedBranchId.isNotEmpty,
      ),
      _AuditFilterStatusItem(
        label: 'Outcome',
        value: state.selectedOutcome?.label ?? 'All outcomes',
        isEmphasized: state.selectedOutcome != null,
      ),
      _AuditFilterStatusItem(
        label: 'Action',
        value: selectedActionKey.isEmpty ? 'All actions' : selectedActionKey,
        isEmphasized: selectedActionKey.isNotEmpty,
      ),
    ];

    return _AuditFilterSummary(
      filterStatusItems: filterStatusItems,
      hasFiltersApplied:
          selectedBranchId.isNotEmpty ||
          state.selectedOutcome != null ||
          selectedActionKey.isNotEmpty,
      onFilterPressed: onFilterPressed,
      compact: useStackedLayout,
    );
  }
}

class _AuditFilterSummary extends StatelessWidget {
  const _AuditFilterSummary({
    required this.filterStatusItems,
    required this.hasFiltersApplied,
    required this.onFilterPressed,
    required this.compact,
  });

  final List<_AuditFilterStatusItem> filterStatusItems;
  final bool hasFiltersApplied;
  final VoidCallback onFilterPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTableTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTableTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Current filter',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _AuditFilterActionButton(
                hasFiltersApplied: hasFiltersApplied,
                onPressed: onFilterPressed,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: compact ? 8 : 10,
            runSpacing: 8,
            children: [
              for (final item in filterStatusItems)
                _AuditFilterInfoCard(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuditFilterInfoCard extends StatelessWidget {
  const _AuditFilterInfoCard({required this.item});

  final _AuditFilterStatusItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = item.isEmphasized
        ? colorScheme.primary.withValues(alpha: 0.08)
        : AppTableTheme.headerBackground;
    final borderColor = item.isEmphasized
        ? colorScheme.primary.withValues(alpha: 0.35)
        : AppTableTheme.divider;
    final labelColor = item.isEmphasized
        ? colorScheme.primary
        : const Color(0xFF6B7280);
    final valueColor = item.isEmphasized
        ? const Color(0xFF1F2937)
        : const Color(0xFF2B2B2B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${item.label}: ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
            TextSpan(
              text: item.value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: item.isEmphasized
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditFilterActionButton extends StatelessWidget {
  const _AuditFilterActionButton({
    required this.hasFiltersApplied,
    required this.onPressed,
  });

  final bool hasFiltersApplied;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: onPressed,
          child: const Text('Filter'),
        ),
        if (hasFiltersApplied)
          const Positioned(top: 4, right: 4, child: _AuditFilterAppliedDot()),
      ],
    );
  }
}

class _AuditFilterAppliedDot extends StatelessWidget {
  const _AuditFilterAppliedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFFD14343),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _AuditFilterEditor extends StatefulWidget {
  const _AuditFilterEditor({
    required this.branchOptions,
    required this.initialDraft,
  });

  final List<_AuditBranchOption> branchOptions;
  final _AuditFilterDraft initialDraft;

  @override
  State<_AuditFilterEditor> createState() => _AuditFilterEditorState();
}

class _AuditFilterEditorState extends State<_AuditFilterEditor> {
  late final TextEditingController _actionKeyController;
  late String _selectedBranchId;
  AuditOutcome? _selectedOutcome;

  @override
  void initState() {
    super.initState();
    _actionKeyController = TextEditingController(
      text: widget.initialDraft.actionKey,
    );
    _selectedBranchId = widget.initialDraft.branchId.trim();
    _selectedOutcome = widget.initialDraft.outcome;
  }

  @override
  void dispose() {
    _actionKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedOutcomeValue =
        _selectedOutcome?.wireValue ?? _AuditLogPageState._allOutcomesValue;
    final branchEntries = [
      const DropdownMenuItem<String>(
        value: _AuditLogPageState._allBranchesValue,
        child: Text('All branches'),
      ),
      ...widget.branchOptions.map(
        (option) => DropdownMenuItem<String>(
          value: option.id,
          child: Text(option.name),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter Audit Log',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedBranchId.isEmpty
                ? _AuditLogPageState._allBranchesValue
                : _selectedBranchId,
            decoration: const InputDecoration(
              labelText: 'Branch',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: branchEntries,
            onChanged: (value) {
              setState(() {
                _selectedBranchId =
                    value == null ||
                        value == _AuditLogPageState._allBranchesValue
                    ? ''
                    : value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedOutcomeValue,
            decoration: const InputDecoration(
              labelText: 'Outcome',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: _AuditLogPageState._allOutcomesValue,
                child: Text('All outcomes'),
              ),
              ...AuditOutcome.values.map(
                (value) => DropdownMenuItem<String>(
                  value: value.wireValue,
                  child: Text(value.label),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedOutcome =
                    value == null ||
                        value == _AuditLogPageState._allOutcomesValue
                    ? null
                    : AuditOutcome.tryParse(value);
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actionKeyController,
            decoration: const InputDecoration(
              labelText: 'Action key',
              hintText: 'attendance.checkIn',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _apply(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(onPressed: _clear, child: const Text('Clear')),
              const Spacer(),
              FilledButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.search),
                label: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clear() {
    Navigator.of(context).pop(const _AuditFilterDraft.clear());
  }

  void _apply() {
    Navigator.of(context).pop(
      _AuditFilterDraft(
        branchId: _selectedBranchId,
        outcome: _selectedOutcome,
        actionKey: _actionKeyController.text,
      ),
    );
  }
}

class _AuditFilterDraft {
  const _AuditFilterDraft({
    required this.branchId,
    required this.outcome,
    required this.actionKey,
  }) : clearRequested = false;

  const _AuditFilterDraft.clear()
    : branchId = '',
      outcome = null,
      actionKey = '',
      clearRequested = true;

  final String branchId;
  final AuditOutcome? outcome;
  final String actionKey;
  final bool clearRequested;
}

class _AuditFilterStatusItem {
  const _AuditFilterStatusItem({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;
}

class _AuditEventCard extends StatelessWidget {
  const _AuditEventCard({
    required this.event,
    required this.branchLabel,
    required this.actorLabel,
    required this.onViewDetails,
  });

  final AuditEvent event;
  final String branchLabel;
  final String actorLabel;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _AuditEventCardMeta.fromEvent(
      event,
      branchLabel: branchLabel,
      actorLabel: actorLabel,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _AuditOutcomeChip(outcome: event.outcome),
                Text(
                  meta.formattedTimestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.actionKey,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _AuditInfoPill(label: 'Branch', value: meta.branchLabel),
                _AuditInfoPill(label: 'Actor', value: meta.actorLabel),
                _AuditInfoPill(label: 'Entity', value: meta.entityLabel),
                if (meta.reasonLabel != null)
                  _AuditInfoPill(label: 'Reason', value: meta.reasonLabel!),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditEventDetailsView extends StatelessWidget {
  const _AuditEventDetailsView({
    required this.event,
    required this.branchLabel,
    required this.actorLabel,
  });

  final AuditEvent event;
  final String branchLabel;
  final String actorLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _AuditEventCardMeta.fromEvent(
      event,
      branchLabel: branchLabel,
      actorLabel: actorLabel,
    );
    final metadataText = const JsonEncoder.withIndent('  ').convert(
      event.metadata.isEmpty
          ? const {'message': 'No metadata'}
          : event.metadata,
    );
    final rawActorAccountId = (event.actorAccountId ?? '').trim();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Audit Event',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AuditOutcomeChip(outcome: event.outcome),
          const SizedBox(height: 16),
          _AuditDetailRow(label: 'Action key', value: event.actionKey),
          _AuditDetailRow(label: 'Created at', value: meta.formattedTimestamp),
          _AuditDetailRow(label: 'Branch', value: meta.branchLabel),
          _AuditDetailRow(label: 'Actor', value: meta.actorLabel),
          if (rawActorAccountId.isNotEmpty)
            _AuditDetailRow(
              label: 'Actor account ID',
              value: rawActorAccountId,
            ),
          _AuditDetailRow(label: 'Entity', value: meta.entityLabel),
          if (meta.reasonLabel != null)
            _AuditDetailRow(label: 'Reason code', value: meta.reasonLabel!),
          _AuditDetailRow(label: 'Event ID', value: event.id),
          _AuditDetailRow(label: 'Tenant ID', value: event.tenantId),
          const SizedBox(height: 16),
          Text(
            'Metadata',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: SelectableText(
              metadataText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditOutcomeChip extends StatelessWidget {
  const _AuditOutcomeChip({required this.outcome});

  final AuditOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final color = switch (outcome) {
      AuditOutcome.success => Colors.green.shade700,
      AuditOutcome.rejected => Colors.orange.shade800,
      AuditOutcome.failed => Colors.red.shade700,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        outcome.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _AuditInfoPill extends StatelessWidget {
  const _AuditInfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _AuditDetailRow extends StatelessWidget {
  const _AuditDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _AuditLogStatusView extends StatelessWidget {
  const _AuditLogStatusView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _AuditBranchOption {
  const _AuditBranchOption({required this.id, required this.name});

  final String id;
  final String name;
}

class _AuditEventCardMeta {
  const _AuditEventCardMeta({
    required this.formattedTimestamp,
    required this.branchLabel,
    required this.actorLabel,
    required this.entityLabel,
    required this.reasonLabel,
  });

  final String formattedTimestamp;
  final String branchLabel;
  final String actorLabel;
  final String entityLabel;
  final String? reasonLabel;

  factory _AuditEventCardMeta.fromEvent(
    AuditEvent event, {
    required String branchLabel,
    required String actorLabel,
  }) {
    final entityType = (event.entityType ?? '').trim();
    final entityId = (event.entityId ?? '').trim();
    final entityLabel = switch ((entityType.isNotEmpty, entityId.isNotEmpty)) {
      (true, true) => '$entityType • $entityId',
      (true, false) => entityType,
      (false, true) => entityId,
      (false, false) => 'Not provided',
    };

    return _AuditEventCardMeta(
      formattedTimestamp: DateFormat(
        'dd MMM yyyy, HH:mm',
      ).format(event.createdAt.toLocal()),
      branchLabel: branchLabel,
      actorLabel: actorLabel,
      entityLabel: entityLabel,
      reasonLabel: (event.reasonCode ?? '').trim().isEmpty
          ? null
          : event.reasonCode!.trim(),
    );
  }
}
