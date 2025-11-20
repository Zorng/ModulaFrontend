import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/portal_action.dart';
import 'package:modular_pos/core/widgets/portal_shell.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class AdminPortal extends ConsumerWidget {
  const AdminPortal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(loginControllerProvider).session;
    final user = session?.user;
    final actions = <PortalAction>[
      PortalAction(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: (context) => _AdminHomeContent(user: user),
      ),
      PortalAction(
        id: 'menu',
        label: 'Menu',
        icon: Icons.fastfood_outlined,
        builder: (context) => _PlaceholderCard(
          title: 'Menu Management',
          content: 'Create/edit menu items, categories, modifiers.',
        ),
      ),
      PortalAction(
        id: 'inventory',
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        builder: (context) => _PlaceholderCard(
          title: 'Inventory',
          content: 'Stock levels, restock, ingredient mapping.',
        ),
      ),
      PortalAction(
        id: 'staff',
        label: 'Staff',
        icon: Icons.group_outlined,
        builder: (context) => _PlaceholderCard(
          title: 'Cashiers & Managers',
          content: 'Manage staff accounts, roles, branches.',
        ),
      ),
      PortalAction(
        id: 'sales',
        label: 'POS',
        icon: Icons.point_of_sale,
        builder: (context) => _PlaceholderCard(
          title: 'POS',
          content: 'Sales entry for admin; mirrors cashier POS with extras.',
        ),
      ),
      PortalAction(
        id: 'cash_sessions',
        label: 'Cash Sessions',
        icon: Icons.attach_money_outlined,
        builder: (context) => _PlaceholderCard(
          title: 'Cash Sessions',
          content: 'Open/close sessions, paid-in/out, reconciliation, Z/X.',
        ),
      ),
      PortalAction(
        id: 'reports',
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        builder: (context) => _PlaceholderCard(
          title: 'Reports',
          content: 'Sales, inventory, cash, activity logs.',
        ),
      ),
      PortalAction(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings_outlined,
        builder: (context) => _PlaceholderCard(
          title: 'Settings',
          content: 'Store policies, branches, capabilities.',
        ),
      ),
    ];

    return PortalShell(
      title: 'Admin Portal',
      subtitle: 'Full access',
      userName: user?.name ?? 'Admin',
      userRole: user?.role ?? 'Admin',
      userInitial: user?.name.isNotEmpty == true
          ? user!.name.characters.first.toUpperCase()
          : 'A',
      actions: actions,
      initialActionId: 'dashboard',
      onProfileTap: () => context.push(AppRoute.account.path),
      onSettingsTap: () => context.push(AppRoute.settings.path),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}

class _AdminHomeContent extends StatelessWidget {
  const _AdminHomeContent({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final branches = user?.branches ?? const [];
    final hasMultipleBranches = branches.length > 1;
    final openPolicy = () => context.push(AppRoute.policy.path);

    final globalFeatures = [
      _FeatureEntry(
        title: 'Branches',
        icon: Icons.store_mall_directory_outlined,
      ),
      _FeatureEntry(
        title: 'Staff',
        icon: Icons.group_outlined,
      ),
      _FeatureEntry(
        title: 'Menu',
        icon: Icons.fastfood_outlined,
      ),
      _FeatureEntry(
        title: 'Inventory',
        icon: Icons.inventory_2_outlined,
        onTap: () => context.push(AppRoute.inventory.path),
      ),
      _FeatureEntry(
        title: 'Discounts',
        icon: Icons.percent_outlined,
      ),
    ];

    final branchFeatures = [
      _FeatureEntry(
        title: 'POS / Sales',
        icon: Icons.point_of_sale,
      ),
      _FeatureEntry(
        title: 'Cash Sessions',
        icon: Icons.attach_money_outlined,
      ),
      _FeatureEntry(
        title: 'Orders',
        icon: Icons.receipt_long_outlined,
      ),
      _FeatureEntry(
        title: 'Policy',
        icon: Icons.policy_outlined,
        onTap: openPolicy,
      ),
    ];

    final mergedGlobalFeatures =
        hasMultipleBranches ? globalFeatures : [...globalFeatures, ...branchFeatures];
    String? selectedBranchId = branches.isNotEmpty ? branches.first.id : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: 'Global',
          subtitle: 'Affects all branches',
          entries: mergedGlobalFeatures,
          isWide: isWide,
        ),
        if (hasMultipleBranches) ...[
          const SizedBox(height: 16),
          _BranchSection(
            branches: branches,
            entries: branchFeatures,
            isWide: isWide,
            initialBranchId: selectedBranchId,
          ),
        ],
      ],
    );
  }
}

class _BranchSection extends StatefulWidget {
  const _BranchSection({
    required this.branches,
    required this.entries,
    required this.isWide,
    this.initialBranchId,
  });

  final List<UserBranch> branches;
  final List<_FeatureEntry> entries;
  final bool isWide;
  final String? initialBranchId;

  @override
  State<_BranchSection> createState() => _BranchSectionState();
}

class _BranchSectionState extends State<_BranchSection> {
  late String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _selectedBranchId =
        widget.initialBranchId ?? (widget.branches.isNotEmpty ? widget.branches.first.id : null);
  }

  @override
  Widget build(BuildContext context) {
    final selectedBranch = widget.branches
        .firstWhere(
          (b) => b.id == _selectedBranchId,
          orElse: () => widget.branches.isNotEmpty
              ? widget.branches.first
              : const UserBranch(id: '', name: 'No branch', role: '', active: false),
        );

    final branchSelector = widget.isWide
        ? DropdownButton<String>(
            value: _selectedBranchId,
            items: widget.branches
                .map(
                  (b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(b.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedBranchId = value;
              });
              // TODO: Trigger branch-scoped data refresh when wired.
            },
          )
        : InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickBranch(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store_mall_directory_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedBranch.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Branch',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Scoped to current branch',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        branchSelector,
        const SizedBox(height: 8),
        _Section(
          title: '',
          subtitle: '',
          entries: widget.entries,
          isWide: widget.isWide,
          compactHeader: true,
        ),
      ],
    );
  }

  Future<void> _pickBranch(BuildContext context) async {
    if (widget.branches.isEmpty) return;
    final selected = await showModalBottomSheet<UserBranch>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.branches.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final branch = widget.branches[index];
                final isSelected = branch.id == _selectedBranchId;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Icon(
                    Icons.store_mall_directory_outlined,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(branch.name),
                  selected: isSelected,
                  onTap: () => Navigator.pop(context, branch),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedBranchId = selected.id;
      });
      // TODO: Trigger branch-scoped data refresh when wired.
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.isWide,
    this.compactHeader = false,
  });

  final String title;
  final String subtitle;
  final List<_FeatureEntry> entries;
  final bool isWide;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compactHeader) ...[
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isWide ? 1.4 : 1.0,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) => _FeatureCard(entry: entries[index]),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.entry});

  final _FeatureEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: entry.onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  entry.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.title,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureEntry {
  const _FeatureEntry({
    required this.title,
    required this.icon,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
}
