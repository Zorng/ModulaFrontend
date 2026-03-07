import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/routing/workspace_route_guard.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_selection/widgets/branch_selection_tile.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_selection/widgets/create_branch_dialog.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';

enum BranchPageMode { selection, destination }

final _tenantSwitchPath = '${AppRoute.tenantSelection.path}?switch=1';

class BranchSelectionPage extends ConsumerStatefulWidget {
  const BranchSelectionPage({super.key, this.mode = BranchPageMode.selection});

  final BranchPageMode mode;

  @override
  ConsumerState<BranchSelectionPage> createState() =>
      _BranchSelectionPageState();
}

class _BranchSelectionPageState extends ConsumerState<BranchSelectionPage> {
  final _searchController = TextEditingController();
  ProviderSubscription<BranchState>? _branchSubscription;
  String _selectionSearchQuery = '';

  @override
  void initState() {
    super.initState();
    Future<void>(() {
      if (!mounted) return;
      if (widget.mode == BranchPageMode.selection) {
        ref.read(authActiveBranchOverrideProvider.notifier).clear();
        ref.read(authActiveBranchNameOverrideProvider.notifier).clear();
      }
    });

    _branchSubscription = ref.listenManual<BranchState>(
      branchControllerProvider,
      (_, next) {
        if (!mounted) return;

        final intent = next.navigationIntent;
        if (intent == BranchNavigationIntent.none) return;

        ref.read(branchControllerProvider.notifier).consumeNavigationIntent();
        if (intent == BranchNavigationIntent.tenantSelection) {
          context.go(_tenantSwitchPath);
        }
      },
    );

    Future<void>(() async {
      if (!mounted) return;
      if (widget.mode == BranchPageMode.selection) {
        final loginState = ref.read(loginControllerProvider);
        if (loginState.branchOptions.isEmpty) {
          await ref.read(loginControllerProvider.notifier).loadBranchContexts();
        }
        return;
      }
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
    final branchController = ref.read(branchControllerProvider.notifier);
    final loginState = ref.watch(loginControllerProvider);
    final loginController = ref.read(loginControllerProvider.notifier);
    final isSelectionMode = widget.mode == BranchPageMode.selection;

    final routeState = GoRouterState.of(context);
    final redirectReason =
        routeState.uri.queryParameters[branchSelectionReasonQueryParam];
    final continuePath = readContinuePath(routeState.uri);
    final showBranchContextMessage =
        redirectReason == branchContextRequiredReasonCode;
    final activeBranchId = (ref.watch(authActiveBranchIdProvider) ?? '').trim();
    final tenantTitle = state.tenantName.trim().isEmpty
        ? 'Select Branch'
        : state.tenantName.trim();
    final branches = isSelectionMode
        ? _filterSelectionBranches(
            _selectionBranches(
              loginState.branchOptions,
              tenantId:
                  (loginState.session?.activeTenantId ??
                          loginState.session?.user.tenantId)
                      ?.trim() ??
                  '',
            ),
            query: _selectionSearchQuery,
          )
        : state.visibleBranches;
    final userName = (loginState.user?.name ?? '').trim();
    final friendlyError = isSelectionMode
        ? _friendlySelectionError(loginState)
        : _friendlyBranchError(state);
    final isWide = AppBreakpoints.isLarge(MediaQuery.of(context).size.width);
    final isLoading = isSelectionMode ? loginState.isLoading : state.isLoading;

    Future<void> signOut() async {
      await loginController.logout();
      if (!context.mounted) return;
      context.go(AppRoute.login.path);
    }

    Future<void> onBranchTap(String branchId) async {
      final result = await branchController.onBranchTileTap(branchId: branchId);
      if (!context.mounted) return;
      switch (result) {
        case BranchSelectionResult.tenantSelectionRequired:
          context.go(_tenantSwitchPath);
          return;
        case BranchSelectionResult.failed:
          return;
        case BranchSelectionResult.success:
          final target =
              continuePath ??
              (isWide ? AppRoute.cashSession.path : AppRoute.branchPortal.path);
          context.go(target);
          return;
      }
    }

    Future<void> onSelectionBranchTap(BranchListItem branch) async {
      await loginController.selectBranch(branch.branchId);
      if (!context.mounted) return;

      final nextState = ref.read(loginControllerProvider);
      if (nextState.error != null && nextState.error!.trim().isNotEmpty) {
        final errorCode = (nextState.errorCode ?? '').trim().toUpperCase();
        if (errorCode == 'TENANT_CONTEXT_REQUIRED') {
          context.go(_tenantSwitchPath);
        }
        return;
      }

      ref
          .read(authActiveBranchOverrideProvider.notifier)
          .setOverride(branch.branchId);
      ref
          .read(authActiveBranchNameOverrideProvider.notifier)
          .setName(branch.branchName);

      final target =
          continuePath ??
          (isWide ? AppRoute.cashSession.path : AppRoute.branchPortal.path);
      context.go(target);
    }

    final appBarTitle = isSelectionMode ? tenantTitle : 'Branches';
    final headerMessage = isSelectionMode
        ? (userName.isEmpty
              ? 'Choose a branch workspace to continue.'
              : '$userName, choose a branch workspace to continue.')
        : 'Manage branches and choose the branch you want to work in.';

    return Scaffold(
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(
                tooltip: 'Back',
                onPressed: () => context.go(_tenantSwitchPath),
                icon: const Icon(Icons.arrow_back),
              )
            : (!isWide
                  ? IconButton(
                      tooltip: 'Home',
                      onPressed: () => context.go(AppRoute.portal.path),
                      icon: const Icon(Icons.home_outlined),
                    )
                  : null),
        title: isSelectionMode
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(appBarTitle),
                  Text(
                    'Step 2 of 2 • Select branch',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Text(appBarTitle),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: isLoading ? null : signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                headerMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = AppBreakpoints.isSmall(constraints.maxWidth);
                final searchQuery = isSelectionMode
                    ? _selectionSearchQuery
                    : state.searchQuery;
                final searchField = TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    if (isSelectionMode) {
                      setState(() => _selectionSearchQuery = value);
                      return;
                    }
                    branchController.setSearchQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search branch',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              if (isSelectionMode) {
                                setState(() => _selectionSearchQuery = '');
                                return;
                              }
                              branchController.clearSearchQuery();
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                );
                final createButton = FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          branchController.clearCreateFlow();
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
                      if (!isSelectionMode && state.canManageTenant) ...[
                        const SizedBox(height: 12),
                        createButton,
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    if (!isSelectionMode && state.canManageTenant) ...[
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
            if (friendlyError != null) ...[
              Text(
                friendlyError,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: isLoading && branches.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : branches.isEmpty
                  ? const Center(child: Text('No branch found.'))
                  : ListView.separated(
                      itemCount: branches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        final displayBranch =
                            !isSelectionMode &&
                                activeBranchId.isNotEmpty &&
                                branch.branchId == activeBranchId
                            ? branch.copyWith(shouldHighlight: true)
                            : branch;
                        return BranchSelectionTile(
                          branch: displayBranch,
                          enabled: !isLoading,
                          onTap: () => isSelectionMode
                              ? onSelectionBranchTap(branch)
                              : onBranchTap(branch.branchId),
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

List<BranchListItem> _selectionBranches(
  List<AuthBranchContextOption> options, {
  required String tenantId,
}) {
  return options
      .where((option) => option.branchId.trim().isNotEmpty)
      .map(
        (option) => BranchListItem(
          branchId: option.branchId.trim(),
          tenantId: tenantId,
          branchName: option.branchName.trim(),
          status: 'ACTIVE',
        ),
      )
      .toList(growable: false);
}

List<BranchListItem> _filterSelectionBranches(
  List<BranchListItem> branches, {
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return branches;

  return branches
      .where((branch) {
        final haystack = [
          branch.branchName,
          branch.branchId,
          branch.branchAddress ?? '',
          branch.contactNumber ?? '',
        ].join('|').toLowerCase();
        return haystack.contains(normalizedQuery);
      })
      .toList(growable: false);
}

String? _friendlyBranchError(BranchState state) {
  final raw = (state.error ?? '').trim();
  if (raw.isEmpty) return null;

  final code = (state.errorCode ?? '').trim().toUpperCase();
  if (code == 'TENANT_CONTEXT_REQUIRED') {
    return 'Please select a tenant first.';
  }
  if (code == 'BRANCH_CONTEXT_REQUIRED') {
    return 'Please select a branch to continue.';
  }
  if (code == 'NO_BRANCH_ACCESS') {
    return 'You are not assigned to this branch.';
  }
  if (code == 'PERMISSION_DENIED') {
    return 'You do not have permission for this action.';
  }

  return raw;
}

String? _friendlySelectionError(LoginState state) {
  final raw = (state.error ?? '').trim();
  if (raw.isEmpty) return null;

  final code = (state.errorCode ?? '').trim().toUpperCase();
  if (code == 'TENANT_CONTEXT_REQUIRED') {
    return 'Please select a tenant first.';
  }
  if (code == 'BRANCH_CONTEXT_REQUIRED') {
    return 'Please select a branch to continue.';
  }
  if (code == 'NO_BRANCH_ACCESS') {
    return 'You are not assigned to this branch.';
  }
  if (code == 'PERMISSION_DENIED') {
    return 'You do not have permission for this action.';
  }

  return raw;
}
