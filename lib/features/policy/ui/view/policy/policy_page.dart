import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/sync/sync_freshness.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/core/widgets/layout/bounded_content_frame.dart';
import 'package:modular_pos/core/widgets/navigation/branch_workspace_scaffold.dart';
import 'package:modular_pos/core/widgets/sync/sync_freshness_banner.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/data/policy_error_codes.dart';
import 'package:modular_pos/features/policy/ui/models/policy_models.dart';
import 'package:modular_pos/features/policy/ui/view/policy/policy_route_args.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_section.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_branch_banner.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';

/// Mobile-first Policy screen backed by policy API.
class PolicyPage extends ConsumerStatefulWidget {
  const PolicyPage({super.key});

  @override
  ConsumerState<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends ConsumerState<PolicyPage> {
  String _search = '';

  List<PolicySectionData> get _sections => const [
    PolicySectionData(
      title: 'Branch Sales Policy',
      items: [
        PolicyItem(
          id: 'apply_vat',
          title: 'Apply VAT',
          icon: Icons.receipt_long_outlined,
          subtitle:
              'Vat is a tax added to the prices. When enabled, VAT is calculated and shown as a separate line on every sale and printed receipt.',
          type: PolicyItemType.toggle,
        ),
        PolicyItem(
          id: 'usd_to_khr',
          title: 'Currency Exchange Rate',
          icon: Icons.attach_money_outlined,
          subtitle:
              'Sets the exchange rate used to convert US Dollar amounts into Cambodian Riel.',
          type: PolicyItemType.selector,
          options: ['4000', '4100', '4150', '4200'],
          defaultValue: '4100',
        ),
        PolicyItem(
          id: 'khr_rounding_enabled',
          title: 'KHR Rounding',
          icon: Icons.calculate_outlined,
          subtitle:
              'Turns Cambodian Riel rounding on or off for branch pricing and payment display.',
          type: PolicyItemType.toggle,
        ),
        PolicyItem(
          id: 'allow_pay_later',
          title: 'Allow Pay Later',
          icon: Icons.receipt_outlined,
          subtitle:
              'Controls whether this branch can place open tickets before payment is collected.',
          type: PolicyItemType.toggle,
        ),
      ],
    ),
  ];

  Future<void> _openPolicyDetail(
    BuildContext context,
    PolicyItem item,
    dynamic currentValue,
  ) async {
    if (item.type == PolicyItemType.info) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(item.subtitle ?? 'Coming soon')));
      return;
    }
    if (_isReadOnly(ref.read(loginControllerProvider))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Read-only: policy editing is disabled.')),
      );
      return;
    }
    final policyNotifier = ref.read(policyNotifierProvider.notifier);
    final policyState = ref.read(policyNotifierProvider);
    if (policyState.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Policy editing is unavailable while offline. Reconnect and try again.',
          ),
        ),
      );
      return;
    }

    if (item.id == 'apply_vat') {
      final result = await context.push<VatPolicySaveResult>(
        AppRoute.policyVatDetail.path,
        extra: VatPolicyDetailArgs(
          enabled: policyState.branchPolicy.saleVatEnabled,
          ratePercent: policyState.branchPolicy.saleVatRatePercent,
        ),
      );
      if (result == null) return;
      await policyNotifier.updateVat(
        enabled: result.enabled,
        ratePercent: result.ratePercent,
      );
      return;
    }

    if (item.id == 'khr_rounding_enabled') {
      final result = await context.push<KhrRoundingPolicySaveResult>(
        AppRoute.policyRoundingDetail.path,
        extra: KhrRoundingPolicyDetailArgs(
          enabled: policyState.branchPolicy.saleKhrRoundingEnabled,
          mode: policyState.branchPolicy.saleKhrRoundingMode,
          granularity: policyState.branchPolicy.saleKhrRoundingGranularity,
        ),
      );
      if (result == null) return;
      await policyNotifier.updateRounding(
        roundingEnabled: result.enabled,
        roundingMode: result.mode,
        roundingGranularity: result.granularity,
      );
      return;
    }

    final newValue = await context.push<dynamic>(
      AppRoute.policyItemDetail.path,
      extra: PolicyItemDetailArgs(item: item, value: currentValue),
    );
    if (newValue == null) return;

    if (item.id == 'usd_to_khr') {
      final rate = double.tryParse(newValue.toString()) ?? 0;
      await policyNotifier.updateCurrency(rate);
      return;
    }

    if (item.id == 'allow_pay_later') {
      await policyNotifier.updatePayLater(enabled: newValue as bool);
      return;
    }
  }

  bool _isReadOnly(LoginState state) {
    final role = resolveSessionAuthRole(state.session);
    return role != AuthRole.admin && role != AuthRole.owner;
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final policyState = ref.watch(policyNotifierProvider);
    final workspaceFreshness = ref.watch(branchWorkspaceSyncFreshnessProvider);
    final isLoading = policyState.isLoading;
    final toggleValues = _composeToggleValues(policyState);

    final selectorValues = _composeSelectorValues(policyState);
    final isReadOnly = _isReadOnly(loginState);
    final branchName = _resolveBranchName(ref);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < AppBreakpoints.compact;
        final isSmall = AppBreakpoints.isSmall(width);
        final isMedium = AppBreakpoints.isMedium(width);
        final isLarge = AppBreakpoints.isLarge(width);

        // Responsive values based on breakpoints
        final horizontalPadding = isLarge ? 32.0 : (isMedium ? 24.0 : 16.0);
        final freshness = workspaceFreshness.asData?.value;

        final filteredSections = _sections
            .map(
              (section) => PolicySectionData(
                title: section.title,
                items: section.items
                    .where(
                      (item) =>
                          _search.isEmpty ||
                          item.title.toLowerCase().contains(_search) ||
                          (item.subtitle?.toLowerCase().contains(_search) ??
                              false),
                    )
                    .toList(),
              ),
            )
            .where((section) => section.items.isNotEmpty)
            .toList();

        return BranchWorkspaceScaffold(
          title: 'Policy',
          body: BoundedContentFrame(
            maxWidth: 960,
            topPadding: isLarge ? 16 : 0,
            bottomPadding: 24,
            horizontalPadding: horizontalPadding,
            child: ListView(
              children: [
                if (isLarge) ...[
                  PolicyBranchBanner(branchName: branchName, isSubtle: false),
                  const SizedBox(height: 16),
                ],
                if (!isLarge) ...[
                  const SizedBox(height: 8),
                  PolicyBranchBanner(branchName: branchName, isSubtle: true),
                  const SizedBox(height: 16),
                ],
                AppSearchBar(
                  hintText: 'Search',
                  onChanged: (value) =>
                      setState(() => _search = value.toLowerCase()),
                ),
                const SizedBox(height: 16),
                if (isLoading) const LinearProgressIndicator(minHeight: 2),
                if (freshness != null) ...[
                  const SizedBox(height: 8),
                  SyncFreshnessBanner(freshness: freshness),
                ],
                if (isReadOnly)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      'Read-only: contact an admin to update policies.',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (_shouldShowFeatureStatusMessage(policyState, freshness))
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      _statusMessage(policyState),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                ...filteredSections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PolicySection(
                      title: section.title,
                      items: section.items,
                      isCompact: isCompact || isSmall,
                      toggleValues: toggleValues,
                      selectorValues: selectorValues,
                      readOnly: isReadOnly,
                      onItemTap: (item, value) =>
                          _openPolicyDetail(context, item, value),
                    ),
                  ),
                ),
                if (filteredSections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      'No settings match "$_search".',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, bool> _composeToggleValues(PolicyState state) {
    return {
      'apply_vat': state.branchPolicy.saleVatEnabled,
      'khr_rounding_enabled': state.branchPolicy.saleKhrRoundingEnabled,
      'allow_pay_later': state.branchPolicy.saleAllowPayLater,
    };
  }

  Map<String, String> _composeSelectorValues(PolicyState state) {
    return {
      'vat_rate': _formatPercent(state.branchPolicy.saleVatRatePercent),
      'usd_to_khr': state.branchPolicy.saleFxRateKhrPerUsd.toStringAsFixed(0),
      'rounding_mode': _roundingLabel(state.branchPolicy.saleKhrRoundingMode),
      'rounding_granularity': state.branchPolicy.saleKhrRoundingGranularity,
    };
  }

  String _formatPercent(double value) => '${value.toStringAsFixed(0)}%';

  String _roundingLabel(String backendValue) {
    switch (BranchPolicyRoundingModes.normalize(backendValue)) {
      case BranchPolicyRoundingModes.up:
        return 'Up';
      case BranchPolicyRoundingModes.down:
        return 'Down';
      default:
        return 'Nearest';
    }
  }

  String _statusMessage(PolicyState state) {
    if (state.isOffline && state.isStale) {
      return 'Offline: showing last known branch policy. Editing is unavailable until you reconnect.';
    }
    if (state.isOffline) {
      return 'Offline: unable to load branch policy. Reconnect and try again.';
    }
    final reasonMessage = _reasonCodeMessage(state.errorCode);
    if (reasonMessage != null) {
      return reasonMessage;
    }
    if (state.error != null && state.error!.trim().isNotEmpty) {
      return state.error!.trim();
    }
    return '';
  }

  bool _shouldShowFeatureStatusMessage(
    PolicyState state,
    SyncWorkspaceFreshness? freshness,
  ) {
    final hasMessage =
        state.isOffline ||
        (state.error != null && state.error!.trim().isNotEmpty);
    if (!hasMessage) return false;
    if (freshness == null) return true;

    final normalizedCode = (state.errorCode ?? '').trim().toUpperCase();
    final isGenericOfflineState =
        state.isOffline &&
        (state.isStale ||
            normalizedCode == PolicyErrorCodes.offlineUnreachable);
    return !isGenericOfflineState;
  }

  String? _reasonCodeMessage(String? code) {
    switch ((code ?? '').trim()) {
      case PolicyErrorCodes.tenantContextRequired:
      case PolicyErrorCodes.branchContextRequired:
        return 'Select a branch context to load this policy.';
      case PolicyErrorCodes.noMembership:
      case PolicyErrorCodes.noBranchAccess:
        return 'You do not have access to this branch policy.';
      case PolicyErrorCodes.permissionDenied:
        return 'You do not have permission to update this branch policy.';
      case PolicyErrorCodes.branchFrozen:
        return 'This branch is frozen. Policy updates are unavailable.';
      case PolicyErrorCodes.subscriptionFrozen:
        return 'This tenant subscription is frozen. Policy updates are unavailable.';
      case PolicyErrorCodes.idempotencyConflict:
      case PolicyErrorCodes.idempotencyInProgress:
        return 'Another policy update is already being processed. Try again.';
      case PolicyErrorCodes.policyPatchEmpty:
        return 'No policy changes were submitted.';
      case PolicyErrorCodes.policyValidationFailed:
        return 'One or more policy values are invalid. Review the form and try again.';
      default:
        return null;
    }
  }

  String _resolveBranchName(WidgetRef ref) {
    final activeBranch = ref.watch(authActiveBranchProvider);
    final activeBranchId = ref.watch(activeBranchContextIdProvider);
    final activeBranchNameOverride = ref.watch(
      authActiveBranchNameOverrideProvider,
    );
    final knownBranches = ref.watch(
      branchControllerProvider.select((state) => state.branches),
    );
    final session = ref.watch(loginControllerProvider).session;

    final overriddenName = (activeBranchNameOverride ?? '').trim();
    if (overriddenName.isNotEmpty) return overriddenName;

    final activeName = activeBranch?.name.trim() ?? '';
    if (activeName.isNotEmpty) return activeName;

    final normalizedActiveId = (activeBranchId ?? '').trim();
    if (normalizedActiveId.isNotEmpty) {
      for (final branch in knownBranches) {
        if (branch.branchId == normalizedActiveId &&
            branch.branchName.trim().isNotEmpty) {
          return branch.branchName.trim();
        }
      }

      final sessionBranches = session?.user.branches ?? const <UserBranch>[];
      for (final branch in sessionBranches) {
        final matchesId =
            branch.branchId.trim() == normalizedActiveId ||
            branch.id.trim() == normalizedActiveId;
        if (matchesId && branch.name.trim().isNotEmpty) {
          return branch.name.trim();
        }
      }
    }

    for (final branch in session?.user.branches ?? const <UserBranch>[]) {
      if (branch.name.trim().isNotEmpty) return branch.name.trim();
    }

    return 'Branch';
  }
}
