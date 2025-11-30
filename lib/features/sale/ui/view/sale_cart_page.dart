import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/network_image_helper_stub.dart'
    if (dart.library.html) 'package:modular_pos/core/widgets/network_image_helper_web.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';

class SaleCartPage extends ConsumerStatefulWidget {
  const SaleCartPage({super.key});

  @override
  ConsumerState<SaleCartPage> createState() => _SaleCartPageState();
}

class _SaleCartPageState extends ConsumerState<SaleCartPage> {
  String _orderType = 'walk_in';
  String _paymentMethod = 'cash';
  String _tenderCurrency = 'usd';
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

  double _grandTotalUsd(double subtotal) => subtotal * 1.10;

  double _grandTotalKhr(double grandTotalUsd) {
    final baseKhr = grandTotalUsd * 4000;
    // Round up to the nearest 100 riel bill.
    return (baseKhr / 100).ceil() * 100.0;
  }

  double _tenderedUsd(double grandTotalUsd) {
    if (_paymentMethod != 'cash') return grandTotalUsd;
    if (_tenderCurrency == 'usd') {
      return double.tryParse(_usdController.text.trim()) ?? 0;
    } else {
      final khr = double.tryParse(_khrController.text.trim()) ?? 0;
      return khr / 4000;
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
    final items = ref.watch(saleCartProvider);
    final menuState = ref.watch(menuViewModelProvider);
    final cartNotifier = ref.read(saleCartProvider.notifier);
    final groupLookup = {
      for (final g in menuState.hydratedModifierGroups.entries) g.key: g.value,
      for (final g in menuState.modifierGroups) g.id: g,
    };
    final subtotal = _subtotal(items, groupLookup);
    final grandTotalUsd = _grandTotalUsd(subtotal);
    final grandTotalKhr = _grandTotalKhr(grandTotalUsd);
    final tenderUsd = _tenderedUsd(grandTotalUsd);
    final canCheckout =
        items.isNotEmpty && (_paymentMethod != 'cash' || tenderUsd >= grandTotalUsd);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _orderType == 'walk_in'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.6),
                    ),
                    onPressed: () => setState(() => _orderType = 'walk_in'),
                    child: Text(
                      'Walk-in',
                      style: TextStyle(
                        color: _orderType == 'walk_in'
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _orderType == 'delivery'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.6),
                    ),
                    onPressed: () => setState(() => _orderType = 'delivery'),
                    child: Text(
                      'Delivery',
                      style: TextStyle(
                        color: _orderType == 'delivery'
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
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
                setState(() => _paymentMethod = value),
            onTenderCurrencyChanged: (value) =>
                setState(() => _tenderCurrency = value),
            usdController: _usdController,
            khrController: _khrController,
            subtotal: subtotal,
            grandTotalUsd: grandTotalUsd,
            grandTotalKhr: grandTotalKhr,
            onAmountsChanged: () => setState(() {}),
          ),
        ),
      ],
    ),
  ),
      bottomNavigationBar:
          _buildBottomBar(context, grandTotalUsd, grandTotalKhr, canCheckout),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    double grandTotalUsd,
    double grandTotalKhr,
    bool canCheckout,
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
              onPressed: canCheckout ? () {} : null,
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
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
  final VoidCallback onAmountsChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Cart is empty'));
    }

    final tenderUsd = tenderCurrency == 'usd'
        ? double.tryParse(usdController.text.trim()) ?? 0
        : (double.tryParse(khrController.text.trim()) ?? 0) / 4000;
    final tenderKhr = tenderCurrency == 'usd'
        ? tenderUsd * 4000
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
                onIncrement: () => onIncrement(index, line),
                onDecrement: () => onDecrement(index, line),
                groupLookup: groupLookup,
              ),
            ],
          );
        }),
        const Divider(height: 16),
        _SummaryRow(
          label: 'Sub total',
          value: subtotal,
        ),
        const SizedBox(height: 4),
        _SummaryRow(
          label: 'VAT (10%)',
          value: subtotal * 0.10,
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
          onSelected: () => onPaymentMethodChanged('cash'),
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
                          onChanged: paymentMethod == 'cash'
                              ? (value) => onTenderCurrencyChanged(value ?? 'usd')
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: usdController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: paymentMethod == 'cash' && tenderCurrency == 'usd',
                      onChanged: (_) => onAmountsChanged(),
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
                          onChanged: paymentMethod == 'cash'
                              ? (value) => onTenderCurrencyChanged(value ?? 'khr')
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: khrController,
                      keyboardType: TextInputType.number,
                      enabled: paymentMethod == 'cash' && tenderCurrency == 'khr',
                      onChanged: (_) => onAmountsChanged(),
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
          onSelected: () => onPaymentMethodChanged('qr'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.groupLookup,
  });

  final CartLine item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
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
  final VoidCallback onSelected;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
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
                  onChanged: (_) => onSelected(),
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
    );
  }
}
