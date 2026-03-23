import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_card.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_header.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_helpers.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_hero_card.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_message.dart';
import 'package:modular_pos/features/discount/ui/components/discount_detail_sections.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_detail_controller.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_detail_state.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_list_controller.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_support_providers.dart';

class DiscountRuleDetailPage extends ConsumerStatefulWidget {
  const DiscountRuleDetailPage({super.key, required this.ruleId});

  final String ruleId;

  @override
  ConsumerState<DiscountRuleDetailPage> createState() =>
      _DiscountRuleDetailPageState();
}

class _DiscountRuleDetailPageState
    extends ConsumerState<DiscountRuleDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discountDetailControllerProvider.notifier).load(widget.ruleId);
    });
  }

  @override
  void didUpdateWidget(covariant DiscountRuleDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ruleId == widget.ruleId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discountDetailControllerProvider.notifier).load(widget.ruleId);
    });
  }

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoute.discount.path);
  }

  Future<void> _openEdit() async {
    final rule = ref.read(discountDetailControllerProvider).rule;
    final saved = await context.push<DiscountRule>(
      AppRoute.discountRuleForm.path,
      extra: rule?.id,
    );
    if (saved != null && mounted) {
      ref
          .read(discountDetailControllerProvider.notifier)
          .applyUpdatedRule(saved);
      ref.read(discountListControllerProvider.notifier).upsertRule(saved);
    }
  }

  Future<void> _updateStatus(String status) async {
    final updated = await ref
        .read(discountDetailControllerProvider.notifier)
        .updateStatus(status);
    if (updated == null || !mounted) return;
    ref.read(discountListControllerProvider.notifier).upsertRule(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(discountDetailUpdatedStatusMessage(status))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discountDetailControllerProvider);
    final controller = ref.read(discountDetailControllerProvider.notifier);
    final branchesAsync = ref.watch(discountTenantBranchesProvider);
    final width = MediaQuery.of(context).size.width;
    final isMedium = AppBreakpoints.isMedium(width);
    final isLarge = AppBreakpoints.isLarge(width);
    final branchNamesById = <String, String>{
      for (final branch in branchesAsync.asData?.value ?? const [])
        branch.branchId: branch.branchName,
    };
    final horizontalPadding = width >= 1440
        ? 32.0
        : (isLarge ? 24.0 : (isMedium ? 20.0 : 16.0));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isLarge ? 1280 : 960),
              child: Column(
                children: [
                  if (isLarge)
                    DiscountDetailHeader(onBackPressed: _navigateBack)
                  else
                    _MobileDetailHeader(onBackPressed: _navigateBack),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isLarge ? 18 : 12,
                        horizontalPadding,
                        24,
                      ),
                      child: _DiscountDetailBody(
                        state: state,
                        isLarge: isLarge,
                        onBack: _navigateBack,
                        onEdit: _openEdit,
                        onRetry: () => controller.load(widget.ruleId),
                        onActivate: () =>
                            _updateStatus(DiscountStatuses.active),
                        onDeactivate: () =>
                            _updateStatus(DiscountStatuses.inactive),
                        onArchive: () =>
                            _updateStatus(DiscountStatuses.archived),
                        branchNamesById: branchNamesById,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscountDetailBody extends StatelessWidget {
  const _DiscountDetailBody({
    required this.state,
    required this.isLarge,
    required this.onBack,
    required this.onEdit,
    required this.onRetry,
    required this.onActivate,
    required this.onDeactivate,
    required this.onArchive,
    required this.branchNamesById,
  });

  final DiscountDetailState state;
  final bool isLarge;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final Future<void> Function() onRetry;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onArchive;
  final Map<String, String> branchNamesById;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rule = state.rule;
    if (rule == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          DiscountDetailStateCard(
            message: state.error ?? 'Discount rule not found.',
            primaryLabel: 'Back to discounts',
            onPrimary: onBack,
            secondaryLabel: 'Retry',
            onSecondary: onRetry,
          ),
        ],
      );
    }

    final summaryCard = DiscountDetailCard(
      title: 'Summary',
      child: DiscountSummarySection(rule: rule),
    );
    final scheduleCard = DiscountDetailCard(
      title: 'Schedule',
      child: DiscountScheduleSection(rule: rule),
    );
    final targetingCard = DiscountDetailCard(
      title: 'Targeting',
      child: DiscountTargetingSection(
        rule: rule,
        branchName: branchNamesById[rule.branchId] ?? '',
      ),
    );
    final lifecycleCard = DiscountDetailCard(
      title: state.canManage ? 'Lifecycle actions' : 'Access',
      child: DiscountActionSection(
        rule: rule,
        isUpdating: state.isUpdating,
        canManage: state.canManage,
        canEdit: state.canEdit,
        onEdit: onEdit,
        onActivate: onActivate,
        onDeactivate: onDeactivate,
        onArchive: onArchive,
      ),
    );

    final messages = <Widget>[];
    if (state.isReadOnly) {
      messages.add(
        const DiscountDetailInlineMessage(
          message:
              'This view is read-only for manager and cashier roles. Admin or owner can edit or change lifecycle state.',
        ),
      );
    } else if (!state.canEdit) {
      messages.add(
        const DiscountDetailInlineMessage(
          message:
              'This discount is currently eligible, so editing is blocked until it is no longer effective.',
        ),
      );
    }
    if (state.error != null) {
      messages.add(DiscountDetailInlineMessage(message: state.error!));
    }

    if (isLarge) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          DiscountDetailHeroCard(rule: rule),
          const SizedBox(height: 20),
          if (state.isUpdating) const LinearProgressIndicator(minHeight: 2),
          if (state.isUpdating && messages.isNotEmpty)
            const SizedBox(height: 12),
          if (messages.isNotEmpty) ...[
            for (var i = 0; i < messages.length; i++) ...[
              messages[i],
              if (i < messages.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _GroupedDetailCard(
                  title: state.canManage
                      ? 'Lifecycle and targeting'
                      : 'Access and targeting',
                  sections: [
                    _GroupedDetailSection(
                      title: state.canManage ? 'Lifecycle actions' : 'Access',
                      child: DiscountActionSection(
                        rule: rule,
                        isUpdating: state.isUpdating,
                        canManage: state.canManage,
                        canEdit: state.canEdit,
                        onEdit: onEdit,
                        onActivate: onActivate,
                        onDeactivate: onDeactivate,
                        onArchive: onArchive,
                      ),
                    ),
                    _GroupedDetailSection(
                      title: 'Targeting',
                      child: DiscountTargetingSection(
                        rule: rule,
                        branchName: branchNamesById[rule.branchId] ?? '',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GroupedDetailCard(
                  title: 'Summary and schedule',
                  sections: [
                    _GroupedDetailSection(
                      title: 'Summary',
                      child: DiscountSummarySection(rule: rule),
                    ),
                    _GroupedDetailSection(
                      title: 'Schedule',
                      child: DiscountScheduleSection(rule: rule),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        DiscountDetailHeroCard(rule: rule),
        const SizedBox(height: 16),
        if (state.isUpdating) const LinearProgressIndicator(minHeight: 2),
        if (messages.isNotEmpty) ...[
          for (var i = 0; i < messages.length; i++) ...[
            if (state.isUpdating || i > 0) const SizedBox(height: 12),
            messages[i],
          ],
        ],
        const SizedBox(height: 16),
        _TopPrioritySection(
          targetingCard: targetingCard,
          lifecycleCard: lifecycleCard,
        ),
        const SizedBox(height: 16),
        summaryCard,
        const SizedBox(height: 16),
        scheduleCard,
      ],
    );
  }
}

class _TopPrioritySection extends StatelessWidget {
  const _TopPrioritySection({
    required this.targetingCard,
    required this.lifecycleCard,
  });

  final Widget targetingCard;
  final Widget lifecycleCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [lifecycleCard, const SizedBox(height: 16), targetingCard],
    );
  }
}

class _GroupedDetailCard extends StatelessWidget {
  const _GroupedDetailCard({required this.title, required this.sections});

  final String title;
  final List<_GroupedDetailSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DiscountDetailCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            Text(
              sections[i].title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            sections[i].child,
            if (i < sections.length - 1) ...[
              const SizedBox(height: 16),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

class _GroupedDetailSection {
  const _GroupedDetailSection({required this.title, required this.child});

  final String title;
  final Widget child;
}

class _MobileDetailHeader extends StatelessWidget {
  const _MobileDetailHeader({required this.onBackPressed});

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
              icon: Icons.arrow_back,
              tooltip: 'Back',
            ),
            const SizedBox(width: 12),
            Text(
              'Discount details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
