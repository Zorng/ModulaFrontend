import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/app_back_button.dart';
import 'package:modular_pos/core/widgets/app_search_bar.dart';
import 'package:modular_pos/features/policy/ui/models/policy_models.dart';
import 'package:modular_pos/features/policy/ui/view/early_check_in_detail_page.dart';
import 'package:modular_pos/features/policy/ui/view/inventory_policy_detail_page.dart';
import 'package:modular_pos/features/policy/ui/view/policy_detail_page.dart';
import 'package:modular_pos/features/policy/ui/view/vat_policy_detail_page.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_section.dart';

/// Mobile-first Policy screen that mimics iOS Settings.
/// Uses static data placeholders for now; hook up viewmodels later.
class PolicyPage extends StatefulWidget {
  const PolicyPage({super.key});

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  String _search = '';

  // Demo state holders; replace with real policy data when wiring backend.
  final Map<String, bool> _toggleValues = {
    'apply_vat': true,
    'subtract_stock': true,
    'use_recipes': false,
    'expiry_tracking': false,
    'cash_session_attendance': false,
    'out_of_shift_approval': false,
    'early_check_in_buffer': false,
    'require_session': true,
    'allow_paid_out': true,
    'cash_refund_approval': false,
    'manual_cash_adjustment': false,
  };

  final Map<String, String> _selectorValues = {
    'vat_rate': '10%',
    'usd_to_khr': '4100',
    'rounding_mode': 'Nearest',
    'early_check_in_duration': '15 min',
  };

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
              type: PolicyItemType.toggle,
            ),
            PolicyItem(
              id: 'expiry_tracking',
              title: 'Expiry tracking',
              icon: Icons.event_available_outlined,
              type: PolicyItemType.toggle,
            ),
          ],
        ),
        PolicySectionData(
          title: 'Attendance & Shifts',
          items: [
            PolicyItem(
              id: 'cash_session_attendance',
              title: 'Cash Session Attendance',
              icon: Icons.access_time,
              subtitle: 'Start/close session will check-in/out staff',
              type: PolicyItemType.toggle,
            ),
            PolicyItem(
              id: 'out_of_shift_approval',
              title: 'Out of shift approval',
              icon: Icons.verified_outlined,
              subtitle: 'Require approval when outside scheduled shift',
              type: PolicyItemType.toggle,
            ),
            PolicyItem(
              id: 'early_check_in_buffer',
              title: 'Early check-in buffer',
              icon: Icons.timer_outlined,
              subtitle: 'Allow early punch-in within configured buffer',
              type: PolicyItemType.toggle,
            ),
            PolicyItem(
              id: 'manager_edit_permission',
              title: 'Manager edit permission',
              icon: Icons.build_outlined,
              subtitle: 'Coming soon',
              type: PolicyItemType.info,
            ),
          ],
        ),
        PolicySectionData(
          title: 'Cash Sessions Control',
          items: [
            PolicyItem(
              id: 'require_session',
              title: 'Require cash session to sell',
              icon: Icons.lock_clock,
              subtitle: 'Cash sale blocked until a session starts',
              type: PolicyItemType.toggle,
            ),
            PolicyItem(
              id: 'allow_paid_out',
              title: 'Allow paid-out',
              icon: Icons.payments_outlined,
              subtitle: 'Enable paid-out during session',
              type: PolicyItemType.toggle,
            ),
            PolicyItem(
              id: 'cash_refund_approval',
              title: 'Cash refund approval',
              icon: Icons.assignment_turned_in_outlined,
              subtitle: 'Require approval before cash refunds',
              type: PolicyItemType.toggle,
            ),
            PolicyItem(
              id: 'manual_cash_adjustment',
              title: 'Manual cash adjustment',
              icon: Icons.tune_outlined,
              subtitle: 'Allow manual drawer adjustments',
              type: PolicyItemType.toggle,
            ),
          ],
        ),
      ];

  void _openPolicyDetail(
    BuildContext context,
    PolicyItem item,
    dynamic currentValue,
  ) {
    if (item.id == 'apply_vat') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VatPolicyDetailPage(
            enabled: _toggleValues[item.id] ?? false,
            currentRate: _selectorValues['vat_rate'] ?? '10%',
            onSaved: (enabled, rate) {
              setState(() {
                _toggleValues[item.id] = enabled;
                _selectorValues['vat_rate'] = rate;
              });
            },
          ),
        ),
      );
      return;
    }

    if (item.id == 'subtract_stock') {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InventoryPolicyDetailPage(
          subtractStock: _toggleValues['subtract_stock'] ?? false,
          useRecipes: _toggleValues['use_recipes'] ?? false,
          onSaved: (subtractStock, useRecipes) {
              setState(() {
                _toggleValues['subtract_stock'] = subtractStock;
                _toggleValues['use_recipes'] = useRecipes;
              });
            },
          ),
        ),
      );
      return;
    }

    if (item.id == 'early_check_in_buffer') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EarlyCheckInDetailPage(
            enabled: _toggleValues['early_check_in_buffer'] ?? false,
            duration: _selectorValues['early_check_in_duration'] ?? '15 min',
            onSaved: (enabled, duration) {
              setState(() {
                _toggleValues['early_check_in_buffer'] = enabled;
                _selectorValues['early_check_in_duration'] = duration;
              });
            },
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PolicyDetailPage(
          item: item,
          value: currentValue,
          onSaved: (newValue) {
            setState(() {
              if (item.type == PolicyItemType.toggle) {
                _toggleValues[item.id] = newValue as bool;
              } else {
                _selectorValues[item.id] = newValue as String;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            leading: AppBackButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoute.adminPortal.path);
                }
              },
            ),
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
                    const SizedBox(height: 16),
                    ...filteredSections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PolicySection(
                          title: section.title,
                          items: section.items,
                          isCompact: isSmall,
                          toggleValues: _toggleValues,
                          selectorValues: _selectorValues,
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
}
