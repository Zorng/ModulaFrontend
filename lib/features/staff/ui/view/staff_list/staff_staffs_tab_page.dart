import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/ui/view/staff_list/widgets/staff_membership_data_table.dart';
import 'package:modular_pos/features/staff/ui/view/staff_list/widgets/staff_membership_list_card.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_membership_list_controller.dart';

class StaffStaffsTabPage extends ConsumerWidget {
  const StaffStaffsTabPage({super.key});

  static const double _dialogMaxWidth = 480;

  static const MenuStyle _whiteDropdownMenuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
    surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
  );

  Future<void> _openFiltersDialog(
    BuildContext context,
    WidgetRef ref,
    StaffMembershipListState state,
  ) async {
    final controller = ref.read(staffMembershipListControllerProvider.notifier);

    StaffListStatusFilter draftStatus = state.statusFilter;
    String? draftBranchId = state.selectedBranchId;
    String? draftRoleKey = state.selectedRoleKey;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final branchEntries = state.branchNameById.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));
          final roleKeys = state.availableRoleKeys.toList()..sort();

          return AlertDialog(
            constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            backgroundColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Filters'),
                TextButton(
                  onPressed: () => setDialogState(() {
                    draftStatus = StaffListStatusFilter.all;
                    draftBranchId = null;
                    draftRoleKey = null;
                  }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear filter'),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fieldWidth = constraints.maxWidth;
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Status ──────────────────────────────────────
                        DropdownMenu<StaffListStatusFilter>(
                          key: ValueKey('filter_status_$draftStatus'),
                          width: fieldWidth,
                          requestFocusOnTap: false,
                          menuHeight: 220,
                          initialSelection: draftStatus,
                          label: const Text('Status'),
                          leadingIcon: const Icon(Icons.badge_outlined),
                          menuStyle: _whiteDropdownMenuStyle,
                          onSelected: (v) {
                            if (v != null) {
                              setDialogState(() => draftStatus = v);
                            }
                          },
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(
                              value: StaffListStatusFilter.all,
                              label: 'All',
                            ),
                            DropdownMenuEntry(
                              value: StaffListStatusFilter.active,
                              label: 'Active',
                            ),
                            DropdownMenuEntry(
                              value: StaffListStatusFilter.invited,
                              label: 'Invited',
                            ),
                            DropdownMenuEntry(
                              value: StaffListStatusFilter.revoked,
                              label: 'Revoked',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ── Branch ──────────────────────────────────────
                        DropdownMenu<String?>(
                          key: ValueKey('filter_branch_$draftBranchId'),
                          width: fieldWidth,
                          requestFocusOnTap: true,
                          enableFilter: true,
                          menuHeight: 220,
                          initialSelection: draftBranchId,
                          label: const Text('Branch'),
                          leadingIcon: const Icon(Icons.store_outlined),
                          menuStyle: _whiteDropdownMenuStyle,
                          onSelected: (v) =>
                              setDialogState(() => draftBranchId = v),
                          dropdownMenuEntries: [
                            const DropdownMenuEntry<String?>(
                              value: null,
                              label: 'All branches',
                            ),
                            for (final e in branchEntries)
                              DropdownMenuEntry<String?>(
                                value: e.key,
                                label: e.value,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ── Role ─────────────────────────────────────────
                        DropdownMenu<String?>(
                          key: ValueKey('filter_role_$draftRoleKey'),
                          width: fieldWidth,
                          requestFocusOnTap: true,
                          enableFilter: true,
                          menuHeight: 220,
                          initialSelection: draftRoleKey,
                          label: const Text('Role'),
                          leadingIcon: const Icon(Icons.work_outline),
                          menuStyle: _whiteDropdownMenuStyle,
                          onSelected: (v) =>
                              setDialogState(() => draftRoleKey = v),
                          dropdownMenuEntries: [
                            const DropdownMenuEntry<String?>(
                              value: null,
                              label: 'All roles',
                            ),
                            for (final rk in roleKeys)
                              DropdownMenuEntry<String?>(
                                value: rk,
                                label: formatRoleKey(rk),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              SizedBox(
                width: double.maxFinite,
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.setFilters(
                            statusFilter: draftStatus,
                            branchId: draftBranchId,
                            roleKey: draftRoleKey,
                          );
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(staffMembershipListControllerProvider);
    final controller = ref.read(staffMembershipListControllerProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _FatalErrorState(
            message: UserErrorMessage.build(
              context: 'Failed to load staff memberships',
              error: error,
            ),
            onRetry: controller.refresh,
          ),
          data: (state) {
            final isWide = AppBreakpoints.isLarge(
              MediaQuery.of(context).size.width,
            );
            final displayed = state.displayedMemberships;
            return ListView(
              children: [
                AppSearchAddBar(
                  searchHint: 'Search by name or phone',
                  onSearchChanged: controller.setSearchQuery,
                  addButtonLabel: 'Invite member',
                  onAddPressed: () => context.push(AppRoute.staffInvite.path),
                ),
                const SizedBox(height: 12),
                if (state.inlineError != null) ...[
                  _InlineMessageCard(
                    message: UserErrorMessage.build(error: state.inlineError),
                  ),
                  const SizedBox(height: 12),
                ],
                _FilterBar(
                  statusFilter: state.statusFilter,
                  selectedBranchName: state.selectedBranchId == null
                      ? null
                      : state.branchNameById[state.selectedBranchId],
                  selectedRoleKey: state.selectedRoleKey,
                  hasActiveFilter: state.hasActiveFilter,
                  isRefreshing: state.isRefreshing,
                  onOpenFilters: () => _openFiltersDialog(context, ref, state),
                  onRefresh: state.isRefreshing ? null : controller.refresh,
                ),
                const SizedBox(height: 16),
                if (displayed.isEmpty)
                  const _EmptyState()
                else if (isWide)
                  StaffMembershipDataTable(
                    memberships: displayed,
                    branchNameById: state.branchNameById,
                    onView: (membership) => _openDetail(context, membership),
                  )
                else
                  Column(
                    children: [
                      for (final membership in displayed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StaffMembershipListCard(
                            membership: membership,
                            branchNameById: state.branchNameById,
                            onTap: () => _openDetail(context, membership),
                          ),
                        ),
                    ],
                  ),
                if (displayed.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton(
                      onPressed: state.canLoadMore && !state.isLoadingMore
                          ? controller.loadMore
                          : null,
                      child: state.isLoadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              state.canLoadMore
                                  ? 'Load more'
                                  : 'All staff loaded',
                            ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, StaffMembershipSummary membership) {
    context.pushNamed(
      AppRoute.staffDetail.name,
      pathParameters: {'membershipId': membership.membershipId},
    );
  }
}

// ── Filter bar ─────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.statusFilter,
    required this.hasActiveFilter,
    required this.isRefreshing,
    required this.onOpenFilters,
    this.selectedBranchName,
    this.selectedRoleKey,
    this.onRefresh,
  });

  final StaffListStatusFilter statusFilter;
  final String? selectedBranchName;
  final String? selectedRoleKey;
  final bool hasActiveFilter;
  final bool isRefreshing;
  final VoidCallback onOpenFilters;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Current filter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: onOpenFilters,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Text('Filter'),
                    if (hasActiveFilter)
                      Positioned(
                        top: -3,
                        right: -7,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChipPill(
                        label: 'Status: ${_statusLabel(statusFilter)}',
                      ),
                      const SizedBox(width: 6),
                      _FilterChipPill(
                        label:
                            'Branch: ${selectedBranchName ?? 'All branches'}',
                      ),
                      const SizedBox(width: 6),
                      _FilterChipPill(
                        label: selectedRoleKey != null
                            ? 'Role: ${formatRoleKey(selectedRoleKey!)}'
                            : 'Role: All roles',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: onRefresh,
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  maximumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isRefreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(StaffListStatusFilter f) => switch (f) {
    StaffListStatusFilter.all => 'All',
    StaffListStatusFilter.active => 'Active',
    StaffListStatusFilter.invited => 'Invited',
    StaffListStatusFilter.revoked => 'Revoked',
  };
}

// ── Pill-style filter chip ─────────────────────────────────────────────────

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _FatalErrorState extends StatelessWidget {
  const _FatalErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.group_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'No staff memberships yet. Invite a team member to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
