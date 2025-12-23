import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/widgets/network_image_helper_stub.dart'
    if (dart.library.html) 'package:modular_pos/core/widgets/network_image_helper_web.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/view/view_carts_page.dart';

class SaleCartPage extends ConsumerStatefulWidget {
  const SaleCartPage({super.key});

  @override
  ConsumerState<SaleCartPage> createState() => _SaleCartPageState();
}

class _SaleCartPageState extends ConsumerState<SaleCartPage> {
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
        !gate.policiesLoading && gate.isBlockedByCashSessionPolicy;
    final role = (ref.watch(loginControllerProvider).user?.role ?? 'cashier')
        .trim()
        .toLowerCase();
    final cashSessionPath = role == 'admin'
        ? AppRoute.adminCashSession.path
        : AppRoute.cashierCashSession.path;
    final policyState = ref.watch(policyNotifierProvider);
    final salesPolicy = policyState.salesPolicy;
    final fxRate = salesPolicy.saleFxRateKhrPerUsd;
    final roundingEnabled = salesPolicy.saleKhrRoundingEnabled;
    final roundingMode = salesPolicy.saleKhrRoundingMode;
    final roundingGranularity =
        double.tryParse(salesPolicy.saleKhrRoundingGranularity) ?? 100;
    final groupLookup = {
      // Base modifier metadata first, then override with hydrated groups that include options/pricing.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'view_carts') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewCartsPage()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'view_carts',
                child: Text('View carts'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (readOnly) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        gate.blockingMessage ??
                            'Read-only: start a cash session to begin selling.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => context.push(
                        cashSessionPath,
                      ),
                      child: const Text('Cash session'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Order Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                _OrderTypeChip(
                  label: 'Dine in',
                  value: 'dine_in',
                  selected: _orderType == 'dine_in',
                  onSelected: readOnly
                      ? null
                      : () {
                    setState(() => _orderType = 'dine_in');
                    ref.read(saleCartProvider.notifier).setSaleType('dine_in');
                  },
                ),
                _OrderTypeChip(
                  label: 'Take away',
                  value: 'take_away',
                  selected: _orderType == 'take_away',
                  onSelected: readOnly
                      ? null
                      : () {
                    setState(() => _orderType = 'take_away');
                    ref.read(saleCartProvider.notifier).setSaleType('take_away');
                  },
                ),
                _OrderTypeChip(
                  label: 'Delivery',
                  value: 'delivery',
                  selected: _orderType == 'delivery',
                  onSelected: readOnly
                      ? null
                      : () {
                    setState(() => _orderType = 'delivery');
                    ref.read(saleCartProvider.notifier).setSaleType('delivery');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: _CartContent(
                items: items,
                groupLookup: groupLookup,
                onIncrement: (index, line) =>
                    cartNotifier.updateQuantity(index, line.quantity + 1),
                onDecrement: (index, line) =>
                    cartNotifier.updateQuantity(index, line.quantity - 1),
                paymentMethod: _paymentMethod,
                tenderCurrency: _tenderCurrency,
                onPaymentMethodChanged: (value) =>
                    setState(() {
                      _paymentMethod = value;
                      ref.read(saleCartProvider.notifier).setPaymentMethod(value);
                    }),
                onTenderCurrencyChanged: (value) =>
                    setState(() {
                      _tenderCurrency = value;
                      ref.read(saleCartProvider.notifier).setTenderCurrency(value);
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
      bottomNavigationBar: _buildBottomBar(
        context,
        grandTotalUsd,
        grandTotalKhr,
        canCheckout,
        onCheckout: () async {
          final ordersNotifier = ref.read(ordersProvider.notifier);
          final menuSnapshot = ref.read(menuViewModelProvider);
          final cartSnapshot = ref.read(saleCartProvider);
          final groupLookup = {
            for (final g in menuSnapshot.modifierGroups) g.id: g,
            for (final g in menuSnapshot.hydratedModifierGroups.entries) g.key: g.value,
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
            final result = await cartNotifier.checkout();
            final saleData = _extractSaleData(result);
            final tenderCurrency =
                (saleData['tenderCurrency']?.toString() ?? _tenderCurrency).toLowerCase();
            final totalUsd =
                (saleData['totalUsdExact'] ?? saleData['totalUsd'] ?? 0).toDouble();
            final totalKhr =
                (saleData['totalKhrExact'] ?? saleData['totalKhr'] ?? 0).toDouble();
            final cashUsd = (saleData['cashReceivedUsd'] ?? cartSnapshot.cashUsd) as num? ?? 0;
            final cashKhr = (saleData['cashReceivedKhr'] ?? cartSnapshot.cashKhr) as num? ?? 0;
            final changeUsd = (saleData['changeGivenUsd'] ?? 0) as num? ?? 0;
            final changeKhr = (saleData['changeGivenKhr'] ?? 0) as num? ?? 0;
            ordersNotifier.createOrder(
              orderType: _orderType,
              paymentMethod: _paymentMethod,
              totalUsd: totalUsd,
              totalKhr: totalKhr,
              tenderCurrency: tenderCurrency,
              tenderAmount: tenderCurrency == 'usd' ? cashUsd.toDouble() : cashKhr.toDouble(),
              changeAmount: tenderCurrency == 'usd' ? changeUsd.toDouble() : changeKhr.toDouble(),
              lines: orderLines,
            );
            // Refresh orders from backend to persist.
            await ordersNotifier.load(date: DateTime.now());
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order created')),
            );
          } catch (e) {
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Checkout failed: $e')),
            );
          }
        },
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    double grandTotalUsd,
    double grandTotalKhr,
    bool canCheckout, {
    required VoidCallback onCheckout,
  }
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Grand Total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '\$${grandTotalUsd.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '៛ ${grandTotalKhr.toStringAsFixed(0)}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: canCheckout ? onCheckout : null,
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
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

Map<String, dynamic> _extractSaleData(Map<String, dynamic> payload) {
  final finalize = payload['finalize'];
  final pre = payload['preCheckout'];
  Map<String, dynamic> pick(dynamic value) {
    if (value is Map<String, dynamic>) {
      if (value['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(value['data'] as Map);
      }
      return value;
    }
    return {};
  }

  final fromFinalize = pick(finalize);
  if (fromFinalize.isNotEmpty) return fromFinalize;
  return pick(pre);
}

class _CartContent extends StatelessWidget {
  const _CartContent({
    required this.items,
    required this.groupLookup,
    required this.onIncrement,
    required this.onDecrement,
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.onPaymentMethodChanged,
    required this.onTenderCurrencyChanged,
    required this.usdController,
    required this.khrController,
    required this.subtotal,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
    required this.fxRate,
    required this.readOnly,
    required this.onAmountsChanged,
  });

  final List<CartLine> items;
  final Map<String, ModifierGroup> groupLookup;
  final void Function(int, CartLine) onIncrement;
  final void Function(int, CartLine) onDecrement;
  final String paymentMethod;
  final String tenderCurrency;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<String> onTenderCurrencyChanged;
  final TextEditingController usdController;
  final TextEditingController khrController;
  final double subtotal;
  final double grandTotalUsd;
  final double grandTotalKhr;
  final double fxRate;
  final bool readOnly;
  final VoidCallback onAmountsChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Cart is empty'));
    }

    void selectTender(String currency) {
      if (readOnly) return;
      onTenderCurrencyChanged(currency);
      if (currency == 'usd') {
        khrController.clear();
      } else {
        usdController.clear();
      }
      onAmountsChanged();
    }

    final tender = tenderCurrency.toLowerCase();
    final tenderUsd = tender == 'usd'
        ? double.tryParse(usdController.text.trim()) ?? 0
        : (double.tryParse(khrController.text.trim()) ?? 0) /
            (fxRate == 0 ? 1 : fxRate);
    final tenderKhr = tender == 'usd'
        ? tenderUsd * fxRate
        : double.tryParse(khrController.text.trim()) ?? 0;
    final changeKhr = (tenderKhr - grandTotalKhr);
    final changeKhrDisplay = changeKhr > 0 ? changeKhr : 0;
    return ListView(
      children: [
        ...List.generate(items.length, (index) {
          final line = items[index];
          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              _CartItemRow(
                item: line,
                onIncrement:
                    readOnly ? null : () => onIncrement(index, line),
                onDecrement:
                    readOnly ? null : () => onDecrement(index, line),
                groupLookup: groupLookup,
              ),
            ],
          );
        }),
        const Divider(height: 16),
        _SummaryRow(
          label: 'Subtotal',
          value: subtotal,
        ),
        const SizedBox(height: 4),
        _SummaryRow(
          label: 'VAT',
          value: 0,
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 8),
        Text(
          'Payment Methods',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _PaymentMethodCard(
          title: 'Cash',
          selected: paymentMethod == 'cash',
          onSelected:
              readOnly ? null : () => onPaymentMethodChanged('cash'),
          body: paymentMethod == 'cash'
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'USD Received',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Radio<String>(
                          value: 'usd',
                          groupValue: tenderCurrency,
                          onChanged: paymentMethod == 'cash' && !readOnly
                              ? (value) => selectTender(value ?? 'usd')
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: usdController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: paymentMethod == 'cash' && !readOnly,
                      onTap: paymentMethod == 'cash' && !readOnly
                          ? () => selectTender('usd')
                          : null,
                      onChanged: paymentMethod == 'cash' && !readOnly
                          ? (_) => onAmountsChanged()
                          : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 4),
                          child: Text(
                            '\$',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: '0.00',
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'KHR Received',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Radio<String>(
                          value: 'khr',
                          groupValue: tenderCurrency,
                          onChanged: paymentMethod == 'cash' && !readOnly
                              ? (value) => selectTender(value ?? 'khr')
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: khrController,
                      keyboardType: TextInputType.number,
                      enabled: paymentMethod == 'cash' && !readOnly,
                      onTap: paymentMethod == 'cash' && !readOnly
                          ? () => selectTender('khr')
                          : null,
                      onChanged: paymentMethod == 'cash' && !readOnly
                          ? (_) => onAmountsChanged()
                          : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 4),
                          child: Text(
                            '៛',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: '0',
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Change (៛)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          'KHR ${changeKhrDisplay.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                )
              : null,
        ),
        const SizedBox(height: 8),
        _PaymentMethodCard(
          title: 'QR / Transfer',
          selected: paymentMethod == 'qr',
          onSelected: readOnly ? null : () => onPaymentMethodChanged('qr'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    this.onIncrement,
    this.onDecrement,
    required this.groupLookup,
  });

  final CartLine item;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final Map<String, ModifierGroup> groupLookup;

  double _lineTotal() {
    double addons = 0;
    item.selectedOptionIds.forEach((groupId, optionIds) {
      final group = groupLookup[groupId];
      if (group == null) return;
      for (final id in optionIds) {
        final opt = group.options.firstWhere(
          (o) => o.id == id,
          orElse: () => const ModifierOption(id: '', name: '', price: 0),
        );
        addons += opt.price;
      }
    });
    return (item.item.price + addons) * item.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final optionNames = <String>[];
    item.selectedOptionIds.forEach((groupId, optionIds) {
      final group = groupLookup[groupId];
      if (group == null) return;
      for (final id in optionIds) {
        final opt = group.options.firstWhere(
          (o) => o.id == id,
          orElse: () => const ModifierOption(id: '', name: '', price: 0),
        );
        if (opt.id.isNotEmpty) optionNames.add(opt.name);
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: () {
                final imageUrl = item.item.imageUrl ?? '';
                final placeholder = Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  alignment: Alignment.center,
                  child: const Icon(Icons.fastfood_outlined),
                );
                if (imageUrl.isEmpty) return placeholder;
                return buildAdaptiveNetworkImage(imageUrl, placeholder);
              }(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  optionNames.isNotEmpty ? optionNames.join(', ') : 'No modifiers',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onDecrement,
                    icon: const Icon(Icons.remove_circle_outline),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  Text(
                    '${item.quantity}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add_circle_outline),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '\$${_lineTotal().toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.title,
    required this.selected,
    required this.onSelected,
    this.body,
  });

  final String title;
  final bool selected;
  final VoidCallback? onSelected;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final enabled = onSelected != null;
    return GestureDetector(
      onTap: onSelected,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Radio<bool>(
                  value: true,
                  groupValue: selected,
                  onChanged: enabled ? (_) => onSelected!() : null,
                ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              body!,
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _OrderTypeChip extends StatelessWidget {
  const _OrderTypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
    );
  }
}
