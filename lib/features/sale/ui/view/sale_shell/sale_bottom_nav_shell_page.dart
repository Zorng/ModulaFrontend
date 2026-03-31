import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/branch_workspace_scaffold.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart';
import 'package:modular_pos/features/sale/ui/view/sale_shell/widgets/sale_printer_status_action.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';

class SaleBottomNavShellPage extends ConsumerStatefulWidget {
  const SaleBottomNavShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;
  @override
  ConsumerState<SaleBottomNavShellPage> createState() =>
      _SaleBottomNavShellPageState();
}

class _SaleBottomNavShellPageState
    extends ConsumerState<SaleBottomNavShellPage> {
  static const double _wideBottomTabHorizontalPadding = 210;
  static const double _wideCartMinWidth = 360;
  static const double _wideCartMaxWidth = 460;
  static const double _wideCartWidthFactor = 0.32;

  static const _titles = <String>['Sale', 'Cart', 'Fulfillment'];
  static const _mobileTitles = <String>['Sale', 'Cart', 'Fulfillment'];

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.storefront_outlined),
      label: 'Sale',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart_outlined),
      label: 'Cart',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Fulfillment',
    ),
  ];

  bool _isPreparingBranchContext = false;
  int _lastObservedShellIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSaleBranchContext();
    });
  }

  Future<void> _ensureSaleBranchContext() async {
    final branchId = ref.read(saleAccessBranchIdProvider);
    if (branchId == null || branchId.trim().isEmpty) return;
    if (_isPreparingBranchContext) return;

    final normalizedBranchId = branchId.trim();
    final loginState = ref.read(loginControllerProvider);
    final authBranchId = (ref.read(authActiveBranchIdProvider) ?? '').trim();

    final needsAuthBranchSelection =
        loginState.requiresBranchSelection ||
        authBranchId != normalizedBranchId;

    if (needsAuthBranchSelection) {
      if (mounted) {
        setState(() => _isPreparingBranchContext = true);
      } else {
        _isPreparingBranchContext = true;
      }

      try {
        await ref
            .read(loginControllerProvider.notifier)
            .selectBranch(normalizedBranchId);
        ref
            .read(authActiveBranchOverrideProvider.notifier)
            .setOverride(normalizedBranchId);
      } finally {
        if (mounted) {
          setState(() => _isPreparingBranchContext = false);
        } else {
          _isPreparingBranchContext = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    if (_lastObservedShellIndex != index) {
      final previousIndex = _lastObservedShellIndex;
      _lastObservedShellIndex = index;
      if (index == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(saleCartProvider.notifier).refreshDiscountEligibility();
        });
      }
      if (previousIndex != -1 && index == 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final workspaceTab = ref.read(fulfillmentWorkspaceTabProvider);
          switch (workspaceTab) {
            case FulfillmentWorkspaceTab.kitchen:
              ref.read(ordersProvider.notifier).load(date: DateTime.now());
            case FulfillmentWorkspaceTab.voidRequests:
              break;
            case FulfillmentWorkspaceTab.externalClaims:
              ref
                  .read(ordersProvider.notifier)
                  .load(date: DateTime.now(), view: orderManualClaimReviewView);
          }
        });
      }
    }
    ref.listen<String?>(saleAccessBranchIdProvider, (_, __) {
      _ensureSaleBranchContext();
    });

    final saleBranchId = ref.watch(saleAccessBranchIdProvider);
    final loginState = ref.watch(loginControllerProvider);
    final branchContextReady =
        saleBranchId != null &&
        saleBranchId.trim().isNotEmpty &&
        !_isPreparingBranchContext &&
        !loginState.isLoading;

    if (!branchContextReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.isLarge(constraints.maxWidth);

        if (isWide) {
          final wideItems = <BottomNavigationBarItem>[_items[0], _items[2]];
          final wideIndex = index == 2 ? 1 : 0;
          final showCartPanel = index == 0;
          final cartPanelWidth = (constraints.maxWidth * _wideCartWidthFactor)
              .clamp(_wideCartMinWidth, _wideCartMaxWidth);
          final appBarTitle = index == 2 ? _titles[2] : _titles[0];
          return BranchWorkspaceScaffold(
            title: appBarTitle,
            actions: actionsForIndex(index, context),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Row(
                  children: [
                    Expanded(child: widget.navigationShell),
                    if (showCartPanel) ...[
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: cartPanelWidth,
                        child: SaleCartPanel(
                          key: const ValueKey('wide_cart_panel'),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Material(
              color:
                  Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
                  Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _wideBottomTabHorizontalPadding,
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: wideIndex,
                  items: wideItems,
                  type: BottomNavigationBarType.fixed,
                  onTap: (tabIndex) {
                    widget.navigationShell.goBranch(tabIndex == 0 ? 0 : 2);
                  },
                ),
              ),
            ),
          );
        }

        return BranchWorkspaceScaffold(
          title: _mobileTitles[index],
          actions: actionsForIndex(index, context),
          body: widget.navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            items: _items,
            type: BottomNavigationBarType.fixed,
            onTap: widget.navigationShell.goBranch,
          ),
        );
      },
    );
  }

  List<Widget>? actionsForIndex(int index, BuildContext context) {
    if (index == 0) {
      return const [SalePrinterStatusAction()];
    }
    return null;
  }
}
