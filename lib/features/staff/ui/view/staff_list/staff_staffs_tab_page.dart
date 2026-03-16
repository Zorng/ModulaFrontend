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

  static const MenuStyle _whiteDropdownMenuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
    surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
  );
  static const double _topControlHeight = 56;
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownMenu<StaffListStatusFilter>(
                        width: isWide ? 220 : null,
                        initialSelection: state.statusFilter,
                        requestFocusOnTap: false,
                        menuStyle: _whiteDropdownMenuStyle,
                        label: const Text('Status'),
                        onSelected: (value) {
                          if (value != null) {
                            controller.setStatusFilter(value);
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
                    ),
                    const SizedBox(width: 12),
                    Tooltip(
                      message: 'Refresh',
                      child: IconButton.filledTonal(
                        onPressed: state.isRefreshing
                            ? null
                            : controller.refresh,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(
                            _topControlHeight,
                            _topControlHeight,
                          ),
                          maximumSize: const Size(
                            _topControlHeight,
                            _topControlHeight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: state.isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.memberships.isEmpty)
                  const _EmptyState()
                else if (isWide)
                  StaffMembershipDataTable(
                    memberships: state.memberships,
                    branchNameById: state.branchNameById,
                    onView: (membership) => _openDetail(context, membership),
                  )
                else
                  Column(
                    children: [
                      for (final membership in state.memberships)
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
                if (state.memberships.isNotEmpty) ...[
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
