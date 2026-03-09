import 'package:flutter/material.dart';
import 'package:modular_pos/core/formatters/khr_currency_formatter.dart';
import 'package:modular_pos/core/input_formatters/khr_text_input_formatter.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';
import 'package:modular_pos/core/input_formatters/decimal_text_input_formatter.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_item_row.dart';
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
    required this.khqrStatus,
    required this.onOpenKhqrPopup,
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
  final String khqrStatus;
  final VoidCallback? onOpenKhqrPopup;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Cart is empty'));
    }

    void selectTender(String currency) {
      if (readOnly) return;
      onTenderCurrencyChanged(currency);
      onAmountsChanged();
    }

    double parseAmount(String raw) =>
        double.tryParse(raw.replaceAll(',', '').trim()) ?? 0;

    final tender = tenderCurrency.toLowerCase();
    final tenderUsd = tender == 'usd'
        ? parseAmount(usdController.text)
        : parseAmount(khrController.text) / (fxRate == 0 ? 1 : fxRate);
    final tenderKhr = tender == 'usd'
        ? tenderUsd * fxRate
        : parseAmount(khrController.text);
    final changeKhr = (tenderKhr - grandTotalKhr);
    final changeKhrDisplay = changeKhr > 0 ? changeKhr : 0;
    final usdHasInput = usdController.text
        .replaceAll(',', '')
        .trim()
        .isNotEmpty;
    final khrHasInput = khrController.text
        .replaceAll(',', '')
        .trim()
        .isNotEmpty;
    final bothFilled = usdHasInput && khrHasInput;
    final usdEnabled =
        !readOnly && (!khrHasInput || (bothFilled && tender == 'usd'));
    final khrEnabled =
        !readOnly && (!usdHasInput || (bothFilled && tender == 'khr'));
    final khqrConfirmed =
        SaleKhqrUiStates.normalize(khqrStatus) ==
        SaleKhqrUiStates.paidConfirmed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 20),
        Text(
          'Payment Methods',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: readOnly ? 0.6 : 1,
          child: Row(
            children: [
              Expanded(
                child: _PaymentTab(
                  label: 'Cash',
                  selected: paymentMethod == 'cash',
                  onTap: readOnly ? null : () => onPaymentMethodChanged('cash'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PaymentTab(
                  label: 'QR Code',
                  selected: paymentMethod == 'qr',
                  onTap: readOnly ? null : () => onPaymentMethodChanged('qr'),
                ),
              ),
            ],
          ),
        ),
        if (paymentMethod == 'cash') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'USD Received',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: usdController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      enabled: usdEnabled,
                      onTap: usdEnabled ? () => selectTender('usd') : null,
                      onChanged: usdEnabled
                          ? (value) {
                              if (value.trim().isNotEmpty &&
                                  khrController.text
                                      .replaceAll(',', '')
                                      .trim()
                                      .isNotEmpty) {
                                khrController.clear();
                              }
                              selectTender('usd');
                            }
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KHR Received',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: khrController,
                      keyboardType: TextInputType.number,
                      enabled: khrEnabled,
                      onTap: khrEnabled ? () => selectTender('khr') : null,
                      onChanged: khrEnabled
                          ? (value) {
                              if (value.trim().isNotEmpty &&
                                  usdController.text
                                      .replaceAll(',', '')
                                      .trim()
                                      .isNotEmpty) {
                                usdController.clear();
                              }
                              selectTender('khr');
                            }
                          : null,
                      inputFormatters: [KhrTextInputFormatter()],
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Change (៛)', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'KHR ${formatKhrAmount(changeKhrDisplay)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (paymentMethod == 'qr') ...[
          const SizedBox(height: 12),
          Text('KHQR Currency', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Opacity(
            opacity: readOnly ? 0.6 : 1,
            child: Row(
              children: [
                Expanded(
                  child: _PaymentTab(
                    label: 'USD',
                    selected: tender == 'usd',
                    onTap: readOnly ? null : () => selectTender('usd'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PaymentTab(
                    label: 'KHR',
                    selected: tender == 'khr',
                    onTap: readOnly ? null : () => selectTender('khr'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KHQR will be generated and shown in a popup.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use the popup to scan, check status, cancel, or regenerate the payment QR.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: readOnly || khqrConfirmed
                        ? null
                        : onOpenKhqrPopup,
                    child: Text(
                      khqrConfirmed
                          ? 'KHQR Payment Confirmed'
                          : 'Open KHQR Popup',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _PaymentTab extends StatelessWidget {
  const _PaymentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBg = theme.colorScheme.primary.withValues(alpha: 0.1);
    final unselectedBg = Colors.grey.shade100;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.35)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? theme.colorScheme.primary : Colors.black87,
          ),
        ),
      ),
    );
  }
}
