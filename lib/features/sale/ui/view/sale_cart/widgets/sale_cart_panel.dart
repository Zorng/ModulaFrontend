import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_bottom_bar.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_readonly_banner.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_order_type_selector.dart';

class SaleCartPanel extends ConsumerStatefulWidget {
  const SaleCartPanel({
    super.key,
    this.contentPadding = const EdgeInsets.all(16),
  });

  final EdgeInsets contentPadding;

  @override
  ConsumerState<SaleCartPanel> createState() => _SaleCartPanelState();
}

class _SaleCartPanelState extends ConsumerState<SaleCartPanel> {
  String _orderType = 'take_away';
  String _paymentMethod = 'cash';
  String _tenderCurrency = 'USD';
  final TextEditingController _usdController = TextEditingController();
  final TextEditingController _khrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usdController.addListener(() => setState(() {}));
    _khrController.addListener(() => setState(() {}));
  }

  double _lineTotal(CartLine line, Map<String, ModifierGroup> groupLookup) {
    double addons = 0;
    for (final entry in line.selectedOptionIds.entries) {
      final group = groupLookup[entry.key];
      if (group == null) continue;
      for (final optId in entry.value) {
        final opt = group.options.firstWhere(
          (o) => o.id == optId,
          orElse: () => const ModifierOption(id: '', name: '', price: 0),
        );
        addons += opt.price;
      }
    }
    return (line.item.price + addons) * line.quantity;
  }

  double _subtotal(
    List<CartLine> items,
    Map<String, ModifierGroup> groupLookup,
  ) {
    return items.fold<double>(
      0,
      (sum, line) => sum + _lineTotal(line, groupLookup),
    );
  }

  double _grandTotalUsd(double subtotal) => subtotal;

  double _grandTotalKhr(
    double grandTotalUsd, {
    required double fxRate,
    required bool roundingEnabled,
    required String roundingMode,
    required double roundingGranularity,
  }) {
    final baseKhr = grandTotalUsd * fxRate;
    return _roundKhr(
      baseKhr,
      enabled: roundingEnabled,
      mode: roundingMode,
      granularity: roundingGranularity,
    );
  }

  double _tenderedUsd(double grandTotalUsd, double fxRate) {
    if (_paymentMethod != 'cash') return grandTotalUsd;
    final tender = _tenderCurrency.toLowerCase();
    if (tender == 'usd') {
      return double.tryParse(_usdController.text.trim()) ?? 0;
    } else {
      final khr = double.tryParse(_khrController.text.trim()) ?? 0;
      return fxRate == 0 ? 0 : khr / fxRate;
    }
  }

  double _roundKhr(
    double amount, {
    required bool enabled,
    required String mode,
    required double granularity,
  }) {
    if (!enabled) return amount;
    final step = granularity <= 0 ? 100.0 : granularity;
    final ratio = amount / step;
    switch (mode.toUpperCase()) {
      case 'UP':
        return (ratio).ceil() * step;
      case 'DOWN':
        return (ratio).floor() * step;
      default:
        return ratio.round() * step;
    }
  }

  @override
  void dispose() {
    _usdController.dispose();
    _khrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(saleCartProvider);
    final items = cartState.lines;
    final menuState = ref.watch(menuViewModelProvider);
    final cartNotifier = ref.read(saleCartProvider.notifier);
    final gate = ref.watch(saleAccessGateProvider);
    final readOnly =
        !gate.cashSessionLoading && gate.isBlockedByCashSessionPolicy;
    final cashSessionPath = AppRoute.cashSession.path;
    final policyState = ref.watch(policyNotifierProvider);
    final salesPolicy = policyState.salesPolicy;
    final fxRate = salesPolicy.saleFxRateKhrPerUsd;
    final roundingEnabled = salesPolicy.saleKhrRoundingEnabled;
    final roundingMode = salesPolicy.saleKhrRoundingMode;
    final roundingGranularity =
        double.tryParse(salesPolicy.saleKhrRoundingGranularity) ?? 100;
    final groupLookup = {
      for (final g in menuState.modifierGroups) g.id: g,
      for (final g in menuState.hydratedModifierGroups.entries) g.key: g.value,
    };
    final subtotal = _subtotal(items, groupLookup);
    final grandTotalUsd = _grandTotalUsd(subtotal);
    final grandTotalKhr = _grandTotalKhr(
      grandTotalUsd,
      fxRate: fxRate,
      roundingEnabled: roundingEnabled,
      roundingMode: roundingMode,
      roundingGranularity: roundingGranularity,
    );
    final tenderUsd = _tenderedUsd(grandTotalUsd, fxRate);
    final canCheckout =
        !readOnly &&
        items.isNotEmpty &&
        (_paymentMethod != 'cash' || tenderUsd >= grandTotalUsd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: widget.contentPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (readOnly) ...[
                      SaleCartReadOnlyBanner(
                        message:
                            gate.blockingMessage ??
                            'Read-only: start a cash session to begin selling.',
                        cashSessionPath: cashSessionPath,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Order Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SaleOrderTypeSelector(
                      value: _orderType,
                      enabled: !readOnly,
                      onChanged: (value) {
                        setState(() => _orderType = value);
                        ref.read(saleCartProvider.notifier).setSaleType(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SaleCartContent(
                        items: items,
                        groupLookup: groupLookup,
                        onIncrement: (index, line) => cartNotifier
                            .updateQuantity(index, line.quantity + 1),
                        onDecrement: (index, line) => cartNotifier
                            .updateQuantity(index, line.quantity - 1),
                        paymentMethod: _paymentMethod,
                        tenderCurrency: _tenderCurrency,
                        onPaymentMethodChanged: (value) => setState(() {
                          _paymentMethod = value;
                          ref
                              .read(saleCartProvider.notifier)
                              .setPaymentMethod(value);
                        }),
                        onTenderCurrencyChanged: (value) => setState(() {
                          _tenderCurrency = value;
                          ref
                              .read(saleCartProvider.notifier)
                              .setTenderCurrency(value);
                        }),
                        usdController: _usdController,
                        khrController: _khrController,
                        subtotal: subtotal,
                        grandTotalUsd: grandTotalUsd,
                        grandTotalKhr: grandTotalKhr,
                        fxRate: fxRate,
                        readOnly: readOnly,
                        onAmountsChanged: () => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SaleCartBottomBar(
          grandTotalUsd: grandTotalUsd,
          grandTotalKhr: grandTotalKhr,
          canCheckout: canCheckout,
          onCheckout: () async {
            final ordersNotifier = ref.read(ordersProvider.notifier);
            final menuSnapshot = ref.read(menuViewModelProvider);
            final cartSnapshot = ref.read(saleCartProvider);
            final groupLookup = {
              for (final g in menuSnapshot.modifierGroups) g.id: g,
              for (final g in menuSnapshot.hydratedModifierGroups.entries)
                g.key: g.value,
            };
            final orderLines = cartSnapshot.lines
                .map(
                  (line) => OrderLine(
                    name: line.item.name,
                    modifiers: _modifierNames(line, groupLookup),
                    quantity: line.quantity,
                  ),
                )
                .toList();
            final cartNotifier = ref.read(saleCartProvider.notifier);
            cartNotifier.setTenderCurrency(_tenderCurrency);
            cartNotifier.setPaymentMethod(_paymentMethod);
            cartNotifier.setCashReceived(
              usd: double.tryParse(_usdController.text.trim()) ?? 0,
              khr: double.tryParse(_khrController.text.trim()) ?? 0,
            );
            try {
              final summary = await cartNotifier.checkout();
              final tenderCurrency =
                  (summary.tenderCurrency.isEmpty
                          ? _tenderCurrency
                          : summary.tenderCurrency)
                      .toLowerCase();
              final totalUsd = summary.totalUsdExact;
              final totalKhr = summary.totalKhrExact;
              final cashUsd = summary.cashReceivedUsd;
              final cashKhr = summary.cashReceivedKhr;
              final changeUsd = summary.changeGivenUsd;
              final changeKhr = summary.changeGivenKhr;
              ordersNotifier.createOrder(
                orderType: _orderType,
                paymentMethod: _paymentMethod,
                totalUsd: totalUsd,
                totalKhr: totalKhr,
                tenderCurrency: tenderCurrency,
                tenderAmount: tenderCurrency == 'usd'
                    ? cashUsd.toDouble()
                    : cashKhr.toDouble(),
                changeAmount: tenderCurrency == 'usd'
                    ? changeUsd.toDouble()
                    : changeKhr.toDouble(),
                lines: orderLines,
              );
              await ordersNotifier.load(date: DateTime.now());
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Order created')));
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    UserErrorMessage.build(
                      context: 'Checkout failed',
                      error: e,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

List<String> _modifierNames(
  CartLine item,
  Map<String, ModifierGroup> groupLookup,
) {
  final names = <String>[];
  item.selectedOptionIds.forEach((groupId, optionIds) {
    final group = groupLookup[groupId];
    if (group == null) return;
    for (final id in optionIds) {
      final opt = group.options.firstWhere(
        (o) => o.id == id,
        orElse: () => const ModifierOption(id: '', name: '', price: 0),
      );
      if (opt.name.isNotEmpty) names.add(opt.name);
    }
  });
  return names;
}
