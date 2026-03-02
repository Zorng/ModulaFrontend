import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/workspace_route_guard.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/workspace_context_provider.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_selection/widgets/branch_selection_tile.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_selection/widgets/create_branch_dialog.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_selection/widgets/global_management_entry_tile.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';

class BranchSelectionPage extends ConsumerStatefulWidget {
  const BranchSelectionPage({super.key});

  @override
  ConsumerState<BranchSelectionPage> createState() =>
      _BranchSelectionPageState();
}

class _BranchSelectionPageState extends ConsumerState<BranchSelectionPage> {
  final _searchController = TextEditingController();
  ProviderSubscription<BranchState>? _branchSubscription;

  @override
  void initState() {
    super.initState();
    Future<void>(() {
      if (!mounted) return;
      ref.read(workspaceContextProvider.notifier).clear();
      ref.read(authActiveBranchOverrideProvider.notifier).clear();
      ref.read(authActiveBranchNameOverrideProvider.notifier).clear();
    });

    _branchSubscription = ref.listenManual<BranchState>(
      branchControllerProvider,
      (_, next) {
        if (!mounted) return;

        final intent = next.navigationIntent;
        if (intent == BranchNavigationIntent.none) return;

        ref.read(branchControllerProvider.notifier).consumeNavigationIntent();
        if (intent == BranchNavigationIntent.globalManagement ||
            intent == BranchNavigationIntent.branchWorkspace) {
          context.go(AppRoute.portal.path);
        }
      },
    );

    Future<void>(() async {
      if (!mounted) return;
      await ref.read(branchControllerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _branchSubscription?.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchControllerProvider);
    final controller = ref.read(branchControllerProvider.notifier);
    final routeState = GoRouterState.of(context);
    final redirectReason =
        routeState.uri.queryParameters[branchSelectionReasonQueryParam];
    final showBranchContextMessage =
        redirectReason == branchContextRequiredReasonCode;
    final tenantTitle = state.tenantName.trim().isEmpty
        ? 'Select Branch'
        : state.tenantName.trim();
    final branches = state.visibleBranches;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go(AppRoute.tenantSelection.path),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(tenantTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = AppBreakpoints.isSmall(constraints.maxWidth);
                final searchField = TextField(
                  controller: _searchController,
                  onChanged: controller.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search branch',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: state.searchQuery.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              controller.clearSearchQuery();
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                );
                final createButton = FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          controller.clearCreateFlow();
                          showCreateBranchDialog(context);
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Branch'),
                );

                if (isSmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      if (state.canManageTenant) ...[
                        const SizedBox(height: 12),
                        createButton,
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    if (state.canManageTenant) ...[
                      const SizedBox(width: 12),
                      SizedBox(width: 180, child: createButton),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (showBranchContextMessage) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  branchContextRequiredUserMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (state.error != null && state.error!.trim().isNotEmpty) ...[
              Text(
                state.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: state.isLoading && branches.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : branches.isEmpty
                  ? const Center(child: Text('No branch found.'))
                  : state.canManageTenant
                  ? ListView(
                      children: [
                        GlobalManagementEntryTile(
                          enabled: !state.isLoading,
                          onTap: controller.onGlobalManagementTap,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Branches',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...branches.map(
                          (branch) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: BranchSelectionTile(
                              branch: branch,
                              enabled: !state.isLoading,
                              onTap: () => controller.onBranchTileTap(
                                branchId: branch.branchId,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: branches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        return BranchSelectionTile(
                          branch: branch,
                          enabled: !state.isLoading,
                          onTap: () => controller.onBranchTileTap(
                            branchId: branch.branchId,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
