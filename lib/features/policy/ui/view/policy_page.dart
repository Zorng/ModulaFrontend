import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/app_back_button.dart';
import 'package:modular_pos/core/widgets/app_search_bar.dart';
import 'package:modular_pos/features/policy/ui/models/policy_models.dart';
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
    'deduct_inventory': true,
    'auto_attendance': false,
    'require_session': true,
    'allow_paid_out': true,
    'require_paid_out_approval': true,
  };

  final Map<String, String> _selectorValues = {
    'vat_rate': '10%',
    'usd_to_khr': '4100',
    'rounding_mode': 'Nearest',
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
              id: 'deduct_inventory',
              title: 'Subtract inventory on sale finalize',
              icon: Icons.inventory_2_outlined,
              subtitle: 'Finalize sale reduces stock for mapped items',
              type: PolicyItemType.toggle,
            ),
          ],
        ),
        PolicySectionData(
          title: 'Attendance & Shifts',
          items: [
            PolicyItem(
              id: 'auto_attendance',
              title: 'Auto-attendance from cash session',
              icon: Icons.access_time,
              subtitle: 'Start/close session will check-in/out staff',
              type: PolicyItemType.toggle,
            ),
          ],
        ),
        PolicySectionData(
          title: 'Cash Sessions & Drawer',
          items: [
            PolicyItem(
              id: 'require_session',
              title: 'Require session before cash sale',
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
              id: 'require_paid_out_approval',
              title: 'Manager approval for over-limit paid-out',
              icon: Icons.verified_user_outlined,
              subtitle: 'Protect large paid-out transactions',
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
              onPressed: () => context.go(AppRoute.adminPortal.path),
            ),
            title: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Settings'),
            ),
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
