import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modular_pos/core/widgets/media/network_image_helper_stub.dart'
    if (dart.library.html) 'package:modular_pos/core/widgets/media/network_image_helper_web.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/components/quantity_stepper.dart';

class SaleCartContent extends StatelessWidget {
  const SaleCartContent({
    super.key,
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
                onIncrement: readOnly ? null : () => onIncrement(index, line),
                onDecrement: readOnly ? null : () => onDecrement(index, line),
                groupLookup: groupLookup,
              ),
            ],
          );
        }),
        const Divider(height: 16),
        _SummaryRow(label: 'Subtotal', value: subtotal),
        const SizedBox(height: 4),
        const _SummaryRow(label: 'VAT', value: 0),
        const SizedBox(height: 12),
        Text('Payment Methods', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _PaymentMethodCard(
          title: 'Cash',
          selected: paymentMethod == 'cash',
          onSelected: readOnly ? null : () => onPaymentMethodChanged('cash'),
          body: paymentMethod == 'cash'
              ? RadioGroup<String>(
                  groupValue: tenderCurrency,
                  onChanged: (value) {
                    if (paymentMethod != 'cash' || readOnly) return;
                    if (value == null) return;
                    selectTender(value);
                  },
                  child: Column(
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
                            enabled: paymentMethod == 'cash' && !readOnly,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: usdController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                        decoration: const InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 12, right: 4),
                            child: Text(
                              '\$',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
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
                            enabled: paymentMethod == 'cash' && !readOnly,
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
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        decoration: const InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 12, right: 4),
                            child: Text(
                              '៛',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
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
                  ),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                  optionNames.isNotEmpty
                      ? optionNames.join(', ')
                      : 'No modifiers',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              QuantityStepper(
                label: null,
                dense: true,
                quantity: item.quantity,
                onDecrement: onDecrement,
                onIncrement: onIncrement,
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
              RadioGroup<bool>(
                groupValue: selected ? true : null,
                onChanged: (_) {
                  if (enabled) {
                    onSelected!();
                  }
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Radio<bool>(value: true, enabled: enabled),
                  ],
                ),
              ),
              if (body != null) ...[const SizedBox(height: 8), body!],
            ],
          ),
        ),
      ),
    );
  }
}
