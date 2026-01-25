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
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

/// Mobile-first Policy screen backed by policy API.
class PolicyPage extends ConsumerStatefulWidget {
  const PolicyPage({super.key});

  @override
  ConsumerState<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends ConsumerState<PolicyPage> {
  String _search = '';

  // Local-only settings not yet backed by the API.
  final Map<String, bool> _localToggleValues = {'use_recipes': false};

  final Map<String, String> _localSelectorValues = {};

  List<PolicySectionData> get _sections => const [
    PolicySectionData(
      title: 'Tax & Currency',
      items: [
        PolicyItem(
          id: 'apply_vat',
          title: 'Apply VAT',
          icon: Icons.receipt_long_outlined,
          subtitle: 'Show VAT line on sales and receipts',
          type: PolicyItemType.toggle,
        ),
        PolicyItem(
          id: 'usd_to_khr',
          title: 'KHR per USD',
          icon: Icons.attach_money_outlined,
          subtitle: 'Used to show KHR equivalent',
          type: PolicyItemType.selector,
          options: ['4000', '4100', '4150', '4200'],
          defaultValue: '4100',
        ),
        PolicyItem(
          id: 'rounding_mode',
          title: 'Rounding mode',
          icon: Icons.swap_vert,
          subtitle: 'Nearest, up, or down',
          type: PolicyItemType.selector,
          options: ['Nearest', 'Up', 'Down'],
          defaultValue: 'Nearest',
        ),
      ],
    ),
    PolicySectionData(
      title: 'Inventory Behavior',
      items: [
        PolicyItem(
          id: 'subtract_stock',
          title: 'Subtract stock on sale',
          icon: Icons.inventory_2_outlined,
          subtitle: 'Coming soon',
          type: PolicyItemType.info,
        ),
        PolicyItem(
          id: 'expiry_tracking',
          title: 'Expiry tracking',
          icon: Icons.event_available_outlined,
          subtitle: 'Coming soon',
          type: PolicyItemType.info,
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
    final role = (state.user?.role ?? 'cashier').trim().toLowerCase();
    return role != 'admin';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = AppBreakpoints.isSmall(constraints.maxWidth);
        final horizontalPadding = isSmall ? 16.0 : 24.0;
        final maxWidth = isSmall ? double.infinity : 720.0;

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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: isSmall
                ? AppBackButton(
                    icon: Icons.home_outlined,
                    tooltip: 'Home',
                    onPressed: () => context.go(portalPath),
                  )
                : null,
            titleSpacing: 0,
            centerTitle: false,
            title: const Text('Settings'),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    24,
                  ),
                  children: [
                    AppSearchBar(
                      hintText: 'Search settings',
                      onChanged: (value) =>
                          setState(() => _search = value.toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    if (isLoading) const LinearProgressIndicator(minHeight: 2),
                    if (isReadOnly)
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
                          isCompact: isSmall,
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
          ),
        );
      },
    );
  }

  Map<String, bool> _composeToggleValues(PolicyState state) {
    return {
      ..._localToggleValues,
      'apply_vat': state.salesPolicy.saleVatEnabled,
      'subtract_stock': state.inventoryPolicy.inventoryAutoSubtractOnSale,
      'expiry_tracking': state.inventoryPolicy.inventoryExpiryTrackingEnabled,
      'cash_session_attendance':
          state.attendancePolicy.attendanceAutoFromCashSession,
      'out_of_shift_approval':
          state.attendancePolicy.attendanceRequireOutOfShiftApproval,
      'early_check_in_buffer':
          state.attendancePolicy.attendanceEarlyCheckinBufferEnabled,
      'allow_paid_out': state.cashSessionPolicy.cashAllowPaidOut,
      'cash_refund_approval': state.cashSessionPolicy.cashRequireRefundApproval,
      'manual_cash_adjustment':
          state.cashSessionPolicy.cashAllowManualAdjustment,
    };
  }

  Map<String, String> _composeSelectorValues(PolicyState state) {
    return {
      ..._localSelectorValues,
      'vat_rate': _formatPercent(state.salesPolicy.saleVatRatePercent),
      'usd_to_khr': state.salesPolicy.saleFxRateKhrPerUsd.toStringAsFixed(0),
      'rounding_mode': _roundingLabel(state.salesPolicy.saleKhrRoundingMode),
      'early_check_in_duration': _durationLabel(
        state.attendancePolicy.attendanceCheckinBufferMinutes,
      ),
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

  String _durationLabel(int minutes) {
    switch (minutes) {
      case 30:
        return '30 min';
      case 60:
        return '1 hour';
      default:
        return '15 min';
    }
  }
}
