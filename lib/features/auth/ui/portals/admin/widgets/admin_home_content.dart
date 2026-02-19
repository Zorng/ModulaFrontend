import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/portal_feature_card.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

class AdminHomeContent extends StatelessWidget {
  const AdminHomeContent({super.key, this.user, this.onOpenSale});

  final User? user;
  final VoidCallback? onOpenSale;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final branches = user?.branches ?? const [];
    final hasMultipleBranches = branches.length > 1;
    void openPolicy() => context.push(AppRoute.policy.path);

    final globalFeatures = [
      FeatureEntry(
        title: 'Branches',
        icon: Icons.store_mall_directory_outlined,
        onTap: () => context.push(AppRoute.branch.path),
      ),
      FeatureEntry(
        title: 'Staff',
        icon: Icons.group_outlined,
        onTap: () => context.push(AppRoute.staff.path),
      ),
      FeatureEntry(
        title: 'Menu',
        icon: Icons.fastfood_outlined,
        onTap: () => context.push(AppRoute.adminMenu.path),
      ),
      FeatureEntry(
        title: 'Inventory',
        icon: Icons.inventory_2_outlined,
        onTap: () => context.push(AppRoute.inventory.path),
      ),
      FeatureEntry(
        title: 'Discounts',
        icon: Icons.percent_outlined,
        comingSoon: true,
      ),
      FeatureEntry(
        title: 'Account',
        icon: Icons.person_outline,
        onTap: () => context.push(AppRoute.account.path),
      ),
    ];

    final branchFeatures = [
      FeatureEntry(
        title: 'POS / Sales',
        icon: Icons.point_of_sale,
        onTap: onOpenSale,
      ),
      FeatureEntry(
        title: 'Cash Sessions',
        icon: Icons.attach_money_outlined,
        onTap: () => context.push(AppRoute.cashSession.path),
      ),
      FeatureEntry(
        title: 'X Report',
        icon: Icons.description_outlined,
        onTap: () => context.push(AppRoute.xReport.path),
      ),
      FeatureEntry(
        title: 'Z Report',
        icon: Icons.summarize_outlined,
        onTap: () => context.push(AppRoute.zReport.path),
      ),
      FeatureEntry(
        title: 'Policy',
        icon: Icons.policy_outlined,
        onTap: openPolicy,
      ),
    ];

    final mergedGlobalFeatures = hasMultipleBranches
        ? globalFeatures
        : [...globalFeatures, ...branchFeatures];
    final String? selectedBranchId = branches.isNotEmpty
        ? (branches.first.branchId.isNotEmpty
              ? branches.first.branchId
              : branches.first.id)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSection(
          title: 'Global',
          subtitle: 'Affects all branches',
          entries: mergedGlobalFeatures,
          isWide: isWide,
        ),
        if (hasMultipleBranches) ...[
          const SizedBox(height: 16),
          AdminBranchSection(
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

class AdminBranchSection extends ConsumerStatefulWidget {
  const AdminBranchSection({
    super.key,
    required this.branches,
    required this.entries,
    required this.isWide,
    this.initialBranchId,
  });

  final List<UserBranch> branches;
  final List<FeatureEntry> entries;
  final bool isWide;
  final String? initialBranchId;

  @override
  ConsumerState<AdminBranchSection> createState() => _AdminBranchSectionState();
}

class _AdminBranchSectionState extends ConsumerState<AdminBranchSection> {
  late String? _selectedBranchId;

  String _branchKey(UserBranch branch) =>
      branch.branchId.isNotEmpty ? branch.branchId : branch.id;

  @override
  void initState() {
    super.initState();
    _selectedBranchId =
        widget.initialBranchId ??
        (widget.branches.isNotEmpty ? _branchKey(widget.branches.first) : null);
  }

  @override
  Widget build(BuildContext context) {
    final selectedBranch = widget.branches.firstWhere(
      (b) => _branchKey(b) == _selectedBranchId,
      orElse: () => widget.branches.isNotEmpty
          ? widget.branches.first
          : const UserBranch(
              id: '',
              name: 'No branch',
              role: '',
              active: false,
            ),
    );

    final branchSelector = widget.isWide
        ? DropdownButton<String>(
            value: _selectedBranchId,
            items: widget.branches
                .map(
                  (b) => DropdownMenuItem(
                    value: _branchKey(b),
                    child: Text(b.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedBranchId = value;
              });
              ref
                  .read(authActiveBranchOverrideProvider.notifier)
                  .setOverride(value);
            },
          )
        : InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickBranch(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        Text('Branch', style: Theme.of(context).textTheme.titleLarge),
        Text(
          'Scoped to current branch',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        branchSelector,
        const SizedBox(height: 8),
        AdminSection(
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
                final isSelected = _branchKey(branch) == _selectedBranchId;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
        _selectedBranchId = _branchKey(selected);
      });
      ref
          .read(authActiveBranchOverrideProvider.notifier)
          .setOverride(_branchKey(selected));
    }
  }
}

class AdminSection extends StatelessWidget {
  const AdminSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.isWide,
    this.compactHeader = false,
  });

  final String title;
  final String subtitle;
  final List<FeatureEntry> entries;
  final bool isWide;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compactHeader) ...[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
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
          itemBuilder: (context, index) {
            final entry = entries[index];
            return PortalFeatureCard(
              title: entry.title,
              icon: entry.icon,
              onTap: entry.comingSoon ? null : entry.onTap,
              badgeText: entry.comingSoon ? 'Coming soon' : null,
            );
          },
        ),
      ],
    );
  }
}

class FeatureEntry {
  const FeatureEntry({
    required this.title,
    required this.icon,
    this.onTap,
    this.comingSoon = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool comingSoon;
}
