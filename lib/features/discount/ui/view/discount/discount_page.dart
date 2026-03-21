import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/buttons/app_add_new_button.dart';
import 'package:modular_pos/core/widgets/forms/app_search_bar.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/ui/components/discount_filter_panel.dart';
import 'package:modular_pos/features/discount/ui/components/discount_page_header.dart';
import 'package:modular_pos/features/discount/ui/components/discount_rule_collection.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_list_controller.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_support_providers.dart';
import 'package:modular_pos/features/inventory/ui/widgets/inventory_dropdown.dart';

class DiscountPage extends ConsumerStatefulWidget {
  const DiscountPage({super.key});

  @override
  ConsumerState<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends ConsumerState<DiscountPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discountListControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discountListControllerProvider);
    final controller = ref.read(discountListControllerProvider.notifier);
    final branchesAsync = ref.watch(discountTenantBranchesProvider);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < AppBreakpoints.compact;
    final isMedium = AppBreakpoints.isMedium(width);
    final isLarge = AppBreakpoints.isLarge(width);
    final Map<String, String> branchNamesById = {
      for (final branch in branchesAsync.asData?.value ?? const [])
        branch.branchId: branch.branchName,
    };

    _syncSearchController(state.searchQuery);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: _DiscountPageLayout(
            width: width,
            isCompact: isCompact,
            isMedium: isMedium,
            isLarge: isLarge,
            subtitle: state.subtitle,
            canManage: state.canManage,
            searchController: _searchController,
            statusFilter: state.statusFilter,
            scopeFilter: state.scopeFilter,
            rules: state.filteredRules,
            isLoading: state.isLoading,
            error: state.error,
            onBackPressed: _navigateBack,
            onAddPressed: state.canManage ? _openCreate : null,
            onSearchChanged: controller.setSearchQuery,
            onStatusChanged: controller.setStatusFilter,
            onScopeChanged: controller.setScopeFilter,
            onRetry: controller.refresh,
            onOpenRule: _openDetail,
            branchNamesById: branchNamesById,
          ),
        ),
      ),
    );
  }

  void _syncSearchController(String value) {
    if (_searchController.text == value) return;
    _searchController.value = _searchController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  Future<void> _openCreate() async {
    final saved = await context.push<DiscountRule>(
      AppRoute.discountRuleForm.path,
    );
    if (saved != null && mounted) {
      await ref.read(discountListControllerProvider.notifier).refresh();
    }
  }

  Future<void> _openDetail(DiscountRule rule) async {
    await context.push(
      AppRoute.discountRuleDetail.path.replaceFirst(':ruleId', rule.id),
    );
    if (!mounted) return;
    await ref.read(discountListControllerProvider.notifier).refresh();
  }

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final isWide = AppBreakpoints.isLarge(MediaQuery.of(context).size.width);
    context.go(isWide ? AppRoute.branch.path : AppRoute.portal.path);
  }
}

class _DiscountPageLayout extends StatelessWidget {
  const _DiscountPageLayout({
    required this.width,
    required this.isCompact,
    required this.isMedium,
    required this.isLarge,
    required this.subtitle,
    required this.canManage,
    required this.searchController,
    required this.statusFilter,
    required this.scopeFilter,
    required this.rules,
    required this.isLoading,
    required this.error,
    required this.onBackPressed,
    required this.onAddPressed,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onScopeChanged,
    required this.onRetry,
    required this.onOpenRule,
    required this.branchNamesById,
  });

  final double width;
  final bool isCompact;
  final bool isMedium;
  final bool isLarge;
  final String subtitle;
  final bool canManage;
  final TextEditingController searchController;
  final String statusFilter;
  final String scopeFilter;
  final List<DiscountRule> rules;
  final bool isLoading;
  final String? error;
  final VoidCallback onBackPressed;
  final Future<void> Function()? onAddPressed;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onScopeChanged;
  final Future<void> Function() onRetry;
  final Future<void> Function(DiscountRule rule) onOpenRule;
  final Map<String, String> branchNamesById;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _horizontalPadding(width);
    final contentMaxWidth = isLarge ? 1520.0 : 960.0;
    final isMobile = !isMedium && !isLarge;

    final controls = DiscountFilterPanel(
      statusFilter: statusFilter,
      scopeFilter: scopeFilter,
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      onStatusChanged: onStatusChanged,
      onScopeChanged: onScopeChanged,
      isCompact: isCompact,
      onAddPressed: isMobile && canManage ? onAddPressed : null,
    );

    final collection = DiscountRuleCollection(
      isLoading: isLoading,
      error: error,
      rules: rules,
      width: width,
      onRetry: onRetry,
      onOpenCreate: onAddPressed,
      onOpenRule: onOpenRule,
      branchNamesById: branchNamesById,
    );

    if (isLarge) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(color: Colors.white),
                child: Text(
                  'Discounts',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WideDiscountToolbar(
                        searchController: searchController,
                        statusFilter: statusFilter,
                        scopeFilter: scopeFilter,
                        canManage: canManage,
                        onSearchChanged: onSearchChanged,
                        onStatusChanged: onStatusChanged,
                        onScopeChanged: onScopeChanged,
                        onAddPressed: onAddPressed,
                      ),
                      const SizedBox(height: 16),
                      _WideInfoBanner(canManage: canManage),
                      const SizedBox(height: 16),
                      Expanded(child: collection),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) _MobileDiscountHeader(onBackPressed: onBackPressed),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isMobile ? 8 : 12,
                  horizontalPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile) ...[
                      const SizedBox(height: 8),
                    ] else if (isMedium) ...[
                      DiscountPageHeader(
                        subtitle: subtitle,
                        onAddPressed: onAddPressed,
                        onBackPressed: onBackPressed,
                        compact: true,
                      ),
                      const SizedBox(height: 16),
                    ] else if (!canManage) ...[
                      const SizedBox(height: 4),
                    ],
                    if (!canManage) ...[
                      const _ReadOnlyBanner(),
                      const SizedBox(height: 10),
                    ],
                    controls,
                    const SizedBox(height: 10),
                    Expanded(child: collection),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _horizontalPadding(double width) {
    if (width >= 1440) return 24;
    if (width >= AppBreakpoints.medium) return 24;
    if (width >= AppBreakpoints.small) return 20;
    return 16;
  }
}

class _WideDiscountToolbar extends StatelessWidget {
  const _WideDiscountToolbar({
    required this.searchController,
    required this.statusFilter,
    required this.scopeFilter,
    required this.canManage,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onScopeChanged,
    required this.onAddPressed,
  });

  final TextEditingController searchController;
  final String statusFilter;
  final String scopeFilter;
  final bool canManage;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onScopeChanged;
  final Future<void> Function()? onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: AppSearchBar(
            hintText: 'Search discount rules',
            fillColor: Colors.white,
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: InventoryDropdown<String>(
            initialValue: statusFilter,
            entries: const [
              DropdownMenuEntry(value: 'ALL', label: 'All statuses'),
              DropdownMenuEntry(value: 'ACTIVE', label: 'Active'),
              DropdownMenuEntry(value: 'INACTIVE', label: 'Inactive'),
              DropdownMenuEntry(value: 'ARCHIVED', label: 'Archived'),
            ],
            onSelected: (value) => onStatusChanged(value ?? 'ALL'),
            hintText: 'All statuses',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: InventoryDropdown<String>(
            initialValue: scopeFilter,
            entries: const [
              DropdownMenuEntry(value: 'ALL', label: 'All scopes'),
              DropdownMenuEntry(value: 'ITEM', label: 'Item-level'),
              DropdownMenuEntry(value: 'BRANCH_WIDE', label: 'Branch-wide'),
            ],
            onSelected: (value) => onScopeChanged(value ?? 'ALL'),
            hintText: 'All scopes',
          ),
        ),
        if (canManage && onAddPressed != null) ...[
          const SizedBox(width: 16),
          SizedBox(
            width: 168,
            child: AppAddNewButton(
              label: 'Add discount',
              onPressed: () => onAddPressed!(),
            ),
          ),
        ],
      ],
    );
  }
}

class _WideInfoBanner extends StatelessWidget {
  const _WideInfoBanner({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: borderColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              canManage
                  ? 'Each discount rule is assigned to exactly one branch. Configure the rule here, then sales resolve it only within that assigned branch.'
                  : 'Discount rules are assigned to one branch and applied only in that branch. Managers and cashiers can view rules but cannot change them.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Managers and cashiers can view discount rules, but only admin or owner can create or edit them.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _MobileDiscountHeader extends StatelessWidget {
  const _MobileDiscountHeader({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: kToolbarHeight,
        child: Row(
          children: [
            AppBackButton(
              onPressed: onBackPressed,
              icon: Icons.home_outlined,
              tooltip: 'Home',
            ),
            Text('Discounts', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
