import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/policy/ui/models/policy_models.dart';
import 'package:modular_pos/features/policy/ui/view/policy/policy_route_args.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_section.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_branch_banner.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';

/// Mobile-first Policy screen backed by policy API.
class PolicyPage extends ConsumerStatefulWidget {
  const PolicyPage({super.key});

  @override
  ConsumerState<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends ConsumerState<PolicyPage> {
  String _search = '';

  // Local-only settings not yet backed by the API.
  final Map<String, bool> _localToggleValues = {};

  final Map<String, String> _localSelectorValues = {};

  List<PolicySectionData> get _sections => const [
    PolicySectionData(
      title: 'Sales and Tax',
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
          id: 'rounding_mode',
          title: 'KHR Rounding Mode',
          icon: Icons.swap_vert,
          subtitle:
              'Controls how Cambodian Riel amounts are rounded when calculating totals. Ex: 4160 to 4200',
          type: PolicyItemType.selector,
          options: ['Nearest', 'Up', 'Down'],
          defaultValue: 'Nearest',
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

    if (item.id == 'apply_vat') {
      final result = await context.push<VatPolicySaveResult>(
        AppRoute.policyVatDetail.path,
        extra: VatPolicyDetailArgs(
          enabled: policyState.salesPolicy.saleVatEnabled,
          ratePercent: policyState.salesPolicy.saleVatRatePercent,
        ),
      );
      if (result == null) return;
      await policyNotifier.updateVat(
        enabled: result.enabled,
        ratePercent: result.ratePercent,
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

    if (item.id == 'rounding_mode') {
      final backendValue = _roundingToBackend(newValue.toString());
      await policyNotifier.updateRounding(roundingMode: backendValue);
      return;
    }

    if (item.type == PolicyItemType.toggle) {
      _localToggleValues[item.id] = newValue as bool;
    } else {
      _localSelectorValues[item.id] = newValue.toString();
    }
    setState(() {});
  }

  bool _isReadOnly(LoginState state) {
    final role = resolveSessionAuthRole(state.session);
    return role != AuthRole.admin && role != AuthRole.owner;
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final policyState = ref.watch(policyNotifierProvider);
    final isLoading = policyState.isLoading;
    final toggleValues = _composeToggleValues(policyState);

    final selectorValues = _composeSelectorValues(policyState);
    final isReadOnly = _isReadOnly(loginState);
    final portalPath = AppRoute.portal.path;
    final activeBranch = ref.watch(authActiveBranchProvider);
    final branchName = activeBranch?.name ?? 'Branch';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < AppBreakpoints.compact;
        final isSmall = AppBreakpoints.isSmall(width);
        final isMedium = AppBreakpoints.isMedium(width);
        final isLarge = AppBreakpoints.isLarge(width);

        // Responsive values based on breakpoints
        final horizontalPadding = isLarge ? 32.0 : (isMedium ? 24.0 : 16.0);
        final showAppBar = !isLarge;
        final showBackButton = isSmall;

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

        return Scaffold(
          appBar: showAppBar
              ? AppBar(
                  automaticallyImplyLeading: false,
                  leading: showBackButton
                      ? AppBackButton(
                          icon: Icons.home_outlined,
                          tooltip: 'Home',
                          onPressed: () => context.go(portalPath),
                        )
                      : null,
                  titleSpacing: 0,
                  centerTitle: false,
                  title: const Text('Policy'),
                )
              : null,
          body: Column(
            children: [
              if (isLarge)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    24,
                  ),
                  child: Text(
                    'Policy',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isLarge ? 16 : 0,
                    horizontalPadding,
                    24,
                  ),
                  child: ListView(
                    children: [
                      if (isLarge) ...[
                        PolicyBranchBanner(
                          branchName: branchName,
                          isSubtle: false,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!isLarge) ...[
                        PolicyBranchBanner(
                          branchName: branchName,
                          isSubtle: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      AppSearchBar(
                        hintText: 'Search',
                        onChanged: (value) =>
                            setState(() => _search = value.toLowerCase()),
                      ),
                      const SizedBox(height: 16),
                      if (isLoading)
                        const LinearProgressIndicator(minHeight: 2),
                      if (isReadOnly && showAppBar)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            'Read-only: contact an admin to update policies.',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, bool> _composeToggleValues(PolicyState state) {
    return {
      ..._localToggleValues,
      'apply_vat': state.salesPolicy.saleVatEnabled,
    };
  }

  Map<String, String> _composeSelectorValues(PolicyState state) {
    return {
      ..._localSelectorValues,
      'vat_rate': _formatPercent(state.salesPolicy.saleVatRatePercent),
      'usd_to_khr': state.salesPolicy.saleFxRateKhrPerUsd.toStringAsFixed(0),
      'rounding_mode': _roundingLabel(state.salesPolicy.saleKhrRoundingMode),
    };
  }

  String _formatPercent(double value) => '${value.toStringAsFixed(0)}%';

  String _roundingLabel(String backendValue) {
    switch (backendValue.toUpperCase()) {
      case 'UP':
        return 'Up';
      case 'DOWN':
        return 'Down';
      default:
        return 'Nearest';
    }
  }

  String _roundingToBackend(String label) {
    switch (label.toLowerCase()) {
      case 'up':
        return 'UP';
      case 'down':
        return 'DOWN';
      default:
        return 'NEAREST';
    }
  }
}
