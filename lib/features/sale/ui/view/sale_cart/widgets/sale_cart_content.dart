import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/core/input_formatters/decimal_text_input_formatter.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_item_row.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_payment_card.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_summary_row.dart';

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(items.length, (index) {
          final line = items[index];
          return Column(
            children: [
              if (index > 0) const Divider(height: 1),
              SaleCartItemRow(
                item: line,
                onIncrement: readOnly ? null : () => onIncrement(index, line),
                onDecrement: readOnly ? null : () => onDecrement(index, line),
                groupLookup: groupLookup,
              ),
            ],
          );
        }),
        const Divider(height: 16),
        SaleCartSummaryRow(label: 'Subtotal', value: subtotal),
        const SizedBox(height: 4),
        const SaleCartSummaryRow(label: 'VAT', value: 0),
        const SizedBox(height: 12),
        Text('Payment Methods', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SaleCartPaymentCard(
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
                          DecimalTextInputFormatter(decimalRange: 2),
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
                          FilteringTextInputFormatter.digitsOnly,
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
        SaleCartPaymentCard(
          title: 'QR / Transfer',
          selected: paymentMethod == 'qr',
          onSelected: readOnly ? null : () => onPaymentMethodChanged('qr'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
