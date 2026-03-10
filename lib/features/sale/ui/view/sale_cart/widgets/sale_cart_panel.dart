import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/printing/thermal_printer_controller.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/formatters/khr_currency_formatter.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_checkout_error_message.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_bottom_bar.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_khqr_popup.dart';
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
  final TextEditingController _usdController = TextEditingController();
  final TextEditingController _khrController = TextEditingController();
  Timer? _khqrPollTimer;

  @override
  void initState() {
    super.initState();
    _usdController.addListener(() => setState(() {}));
    _khrController.addListener(() => setState(() {}));
  }

  Future<void> _showReceiptDialog({
    required SaleCartNotifier cartNotifier,
    required String saleId,
  }) async {
    try {
      final receipt = await cartNotifier.getReceipt(saleId: saleId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          return AlertDialog(
            title: const Text('Receipt'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Receipt #: ${receipt.receiptNumber}'),
                    const SizedBox(height: 4),
                    Text('Sale ID: ${receipt.saleId}'),
                    const SizedBox(height: 4),
                    Text('Payment: ${receipt.paymentMethod.toUpperCase()}'),
                    const SizedBox(height: 12),
                    Text(
                      'Items',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final line in receipt.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${line.quantity}x ${line.name} - \$${line.lineTotalUsdExact.toStringAsFixed(2)}',
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Total: \$${receipt.totalUsdExact.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('KHR ${formatKhrAmount(receipt.totalKhrExact)}'),
                  ],
                ),
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(context: 'Failed to load receipt', error: e),
          ),
        ),
      );
    }
  }

  Future<void> _handlePrintReceipt({
    required SaleCartNotifier cartNotifier,
    required String saleId,
  }) async {
    try {
      await cartNotifier.printReceipt(saleId: saleId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to print receipt',
              error: e,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showOpenTicketDialog({
    required SaleCartNotifier cartNotifier,
    required String saleId,
  }) async {
    try {
      final detail = await cartNotifier.getOpenTicketDetail(saleId: saleId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          return AlertDialog(
            title: const Text('Open Ticket'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ticket #: ${detail.openTicketId}'),
                  const SizedBox(height: 4),
                  Text('Sale ID: ${detail.saleId}'),
                  const SizedBox(height: 4),
                  Text('Status: ${detail.status}'),
                  const SizedBox(height: 12),
                  Text(
                    'Payable',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('\$${detail.payableUsdExact.toStringAsFixed(2)}'),
                  Text('KHR ${formatKhrAmount(detail.payableKhrExact)}'),
                  const SizedBox(height: 12),
                  Text('Batches: ${detail.batches.length}'),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(
              context: 'Failed to load open ticket',
              error: e,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showClearCartConfirmation(SaleCartNotifier cartNotifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text(
            'Are you sure you want to clear the current cart? '
            'All items will be removed and this action cannot be undone.',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.surface,
                      foregroundColor: scheme.onSurface,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear Cart'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      cartNotifier.clear();
      // Show confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showKhqrPopup({
    required bool readOnly,
    required double grandTotalUsd,
    required double grandTotalKhr,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => SaleKhqrPopup(
        readOnly: readOnly,
        grandTotalUsd: grandTotalUsd,
        grandTotalKhr: grandTotalKhr,
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('KHQR payment confirmed.')));
    }
  }

  Future<void> _handlePaymentMethodChanged({
    required String value,
    required SaleCartNotifier cartNotifier,
    required bool readOnly,
    required double grandTotalUsd,
    required double grandTotalKhr,
  }) async {
    await cartNotifier.setPaymentMethod(value);
    if (!mounted || value.toLowerCase() != 'qr') return;
    await _showKhqrPopup(
      readOnly: readOnly,
      grandTotalUsd: grandTotalUsd,
      grandTotalKhr: grandTotalKhr,
    );
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

  double _taxUsd(double subtotal, BranchPolicy branchPolicy) {
    if (!branchPolicy.saleVatEnabled) {
      return 0;
    }
    final ratePercent = branchPolicy.saleVatRatePercent;
    if (ratePercent <= 0) {
      return 0;
    }
    return subtotal * (ratePercent / 100);
  }

  double _grandTotalUsd(double subtotal, {required double taxUsd}) =>
      subtotal + taxUsd;

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

  double _tenderedUsd(
    double grandTotalUsd,
    double fxRate, {
    required String paymentMethod,
    required String tenderCurrency,
  }) {
    if (paymentMethod != 'cash') return grandTotalUsd;
    final tender = tenderCurrency.toLowerCase();
    if (tender == 'usd') {
      return _parseAmount(_usdController.text);
    } else {
      final khr = _parseAmount(_khrController.text);
      return fxRate == 0 ? 0 : khr / fxRate;
    }
  }

  double _parseAmount(String raw) {
    return double.tryParse(raw.replaceAll(',', '').trim()) ?? 0;
  }

  void _syncCashAmounts(SaleCartNotifier cartNotifier) {
    cartNotifier.setCashReceived(
      usd: _parseAmount(_usdController.text),
      khr: _parseAmount(_khrController.text),
    );
  }

  String _finalizeSuccessMessage(SaleCheckoutResult result) {
    final hasReceipt =
        (result.receiptId?.trim().isNotEmpty ?? false) ||
        (result.receipt?.receiptId.trim().isNotEmpty ?? false);
    if (result.idempotentReplay) {
      return hasReceipt
          ? 'Sale already finalized (replayed). Receipt is ready.'
          : 'Sale already finalized (replayed).';
    }
    return hasReceipt
        ? 'Sale finalized. Receipt is ready.'
        : 'Sale finalized successfully.';
  }

  String _actionErrorMessage({required String context, required Object error}) {
    if (error is SaleCheckoutRepositoryException) {
      return SaleCheckoutErrorMessage.build(
        reasonCode: error.reasonCode,
        fallback: error.message,
      );
    }
    return UserErrorMessage.build(context: context, error: error);
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
    _khqrPollTimer?.cancel();
    _usdController.dispose();
    _khrController.dispose();
    super.dispose();
  }

  void _syncKhqrPolling({
    required String paymentMethod,
    required String khqrStatus,
  }) {
    final normalized = SaleKhqrUiStates.normalize(khqrStatus);
    final shouldPoll =
        paymentMethod == 'qr' &&
        (normalized == SaleKhqrUiStates.waitingForPayment ||
            normalized == SaleKhqrUiStates.pendingConfirmation);

    if (!shouldPoll) {
      _khqrPollTimer?.cancel();
      _khqrPollTimer = null;
      return;
    }

    if (_khqrPollTimer != null && _khqrPollTimer!.isActive) return;

    _khqrPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(saleCartProvider.notifier)
            .checkKhqrStatus(silent: true)
            .catchError((_) {}),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<(int, String?, bool)>(
      thermalPrinterControllerProvider.select(
        (state) =>
            (state.lastEventId, state.lastEventMessage, state.lastEventIsError),
      ),
      (previous, next) {
        if (next.$1 == 0 || previous?.$1 == next.$1 || next.$2 == null) {
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.$2!),
            backgroundColor: next.$3 ? Colors.red : null,
          ),
        );
      },
    );
    final cartState = ref.watch(saleCartProvider);
    final items = cartState.lines;
    final paymentMethod = cartState.paymentMethod.toLowerCase();
    final tenderCurrency = cartState.tenderCurrency.toUpperCase();
    final menuState = ref.watch(menuViewModelProvider);
    final cartNotifier = ref.read(saleCartProvider.notifier);
    final gate = ref.watch(saleAccessGateProvider);
    final readOnly = !gate.canAddToCart || cartState.isFinalizing;
    final policyState = ref.watch(policyNotifierProvider);
    final branchPolicy = policyState.branchPolicy;
    final fxRate = branchPolicy.saleFxRateKhrPerUsd;
    final roundingEnabled = branchPolicy.saleKhrRoundingEnabled;
    final roundingMode = BranchPolicyRoundingModes.normalize(
      branchPolicy.saleKhrRoundingMode,
    );
    final roundingGranularity = BranchPolicyRoundingGranularities.asAmount(
      branchPolicy.saleKhrRoundingGranularity,
    );
    final groupLookup = {
      for (final g in menuState.modifierGroups) g.id: g,
      for (final g in menuState.hydratedModifierGroups.entries) g.key: g.value,
    };
    final subtotal = _subtotal(items, groupLookup);
    final taxUsd = _taxUsd(subtotal, branchPolicy);
    final grandTotalUsd = _grandTotalUsd(subtotal, taxUsd: taxUsd);
    final grandTotalKhr = _grandTotalKhr(
      grandTotalUsd,
      fxRate: fxRate,
      roundingEnabled: roundingEnabled,
      roundingMode: roundingMode,
      roundingGranularity: roundingGranularity,
    );
    final tenderUsd = _tenderedUsd(
      grandTotalUsd,
      fxRate,
      paymentMethod: paymentMethod,
      tenderCurrency: tenderCurrency,
    );
    final isSmall = AppBreakpoints.isSmall(MediaQuery.sizeOf(context).width);
    final khqrReady = saleKhqrCanFinalize(cartState.khqrStatus);
    _syncKhqrPolling(
      paymentMethod: paymentMethod,
      khqrStatus: cartState.khqrStatus,
    );
    final orderType = cartState.saleType;
    final isPayLaterMode = orderType == 'dine_in';
    final payLaterEnabled = branchPolicy.saleAllowPayLater;
    final canCheckout =
        gate.canCheckout &&
        !cartState.isFinalizing &&
        items.isNotEmpty &&
        ((paymentMethod == 'cash' && tenderUsd >= grandTotalUsd) ||
            (paymentMethod == 'qr' && khqrReady));
    final canPlaceOrder =
        gate.canPlacePayLater &&
        payLaterEnabled &&
        !cartState.isFinalizing &&
        items.isNotEmpty;
    final canPrimaryAction = isPayLaterMode ? canPlaceOrder : canCheckout;
    final primaryActionLabel = isPayLaterMode ? 'Place Order' : 'Checkout';
    final payLaterDisabledMessage = !payLaterEnabled && isPayLaterMode
        ? 'Pay-later is disabled by branch policy. Switch order type to continue.'
        : null;
    final checkoutBannerMessage = SaleCheckoutErrorMessage.build(
      reasonCode: cartState.checkoutErrorCode,
      fallback: cartState.checkoutErrorMessage,
    );
    final checkoutBannerColor = cartState.isCheckoutOffline
        ? Colors.orange
        : cartState.isCheckoutIdempotencyIssue
        ? Colors.blue
        : cartState.isCheckoutDenied
        ? Colors.amber.shade800
        : Colors.red;
    final checkoutBannerIcon = cartState.isCheckoutOffline
        ? Icons.cloud_off_outlined
        : cartState.isCheckoutIdempotencyIssue
        ? Icons.hourglass_top_rounded
        : cartState.isCheckoutDenied
        ? Icons.info_outline
        : Icons.error_outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isSmall) ...[
          // Cart Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cart',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        if (readOnly && gate.blockingMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gate.blockingMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (cartState.lastFinalizedSaleId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sale finalized successfully.'),
                        if (cartState.lastReceiptId != null)
                          Text('Receipt #: ${cartState.lastReceiptId}'),
                        if (cartState.lastReceipt != null &&
                            cartState.lastReceipt!.statusDisplay
                                .trim()
                                .isNotEmpty)
                          Text(
                            'Receipt status: ${cartState.lastReceipt!.statusDisplay}',
                          ),
                      ],
                    ),
                  ),
                  if (cartState.lastFinalizedSaleId != null)
                    TextButton(
                      onPressed: cartState.isFinalizing
                          ? null
                          : () => _handlePrintReceipt(
                              cartNotifier: cartNotifier,
                              saleId: cartState.lastFinalizedSaleId!,
                            ),
                      child: const Text('Print'),
                    ),
                  if (cartState.lastFinalizedSaleId != null)
                    TextButton(
                      onPressed: cartState.isFinalizing
                          ? null
                          : () => _showReceiptDialog(
                              cartNotifier: cartNotifier,
                              saleId: cartState.lastFinalizedSaleId!,
                            ),
                      child: const Text('Receipt'),
                    ),
                  IconButton(
                    onPressed: cartNotifier.clearCheckoutFeedback,
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
            ),
          ),
        if (cartState.lastPlacedOpenTicketId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Open ticket placed successfully.'),
                        Text('Ticket #: ${cartState.lastPlacedOpenTicketId}'),
                        if (cartState.lastPlacedSaleId != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: cartState.isFinalizing
                                  ? null
                                  : () => _showOpenTicketDialog(
                                      cartNotifier: cartNotifier,
                                      saleId: cartState.lastPlacedSaleId!,
                                    ),
                              child: const Text('View Ticket'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: cartNotifier.clearCheckoutFeedback,
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
            ),
          ),
        if (!cartState.isFinalizing && checkoutBannerMessage.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: checkoutBannerColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(checkoutBannerIcon, color: checkoutBannerColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkoutBannerMessage,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    onPressed: cartNotifier.clearCheckoutFeedback,
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: widget.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order Type Section
                Text(
                  'Order Type',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SaleOrderTypeSelector(
                  value: orderType,
                  enabled: !readOnly,
                  dineInEnabled: payLaterEnabled,
                  onChanged: (value) =>
                      ref.read(saleCartProvider.notifier).setSaleType(value),
                ),
                if (payLaterDisabledMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    payLaterDisabledMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Summary Section
                Text(
                  'Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                // Cart Items
                SaleCartContent(
                  items: items,
                  groupLookup: groupLookup,
                  onIncrement: (index, line) =>
                      cartNotifier.updateQuantity(index, line.quantity + 1),
                  onDecrement: (index, line) =>
                      cartNotifier.updateQuantity(index, line.quantity - 1),
                  paymentMethod: paymentMethod,
                  tenderCurrency: tenderCurrency,
                  onPaymentMethodChanged: (value) =>
                      _handlePaymentMethodChanged(
                        value: value,
                        cartNotifier: cartNotifier,
                        readOnly: readOnly,
                        grandTotalUsd: grandTotalUsd,
                        grandTotalKhr: grandTotalKhr,
                      ),
                  onTenderCurrencyChanged: (value) => ref
                      .read(saleCartProvider.notifier)
                      .setTenderCurrency(value),
                  usdController: _usdController,
                  khrController: _khrController,
                  subtotal: subtotal,
                  taxUsd: taxUsd,
                  showTaxBreakdown: branchPolicy.saleVatEnabled,
                  grandTotalUsd: grandTotalUsd,
                  grandTotalKhr: grandTotalKhr,
                  fxRate: fxRate,
                  readOnly: readOnly,
                  onAmountsChanged: () {
                    _syncCashAmounts(cartNotifier);
                    setState(() {});
                  },
                  khqrStatus: cartState.khqrStatus,
                  onOpenKhqrPopup: () => _showKhqrPopup(
                    readOnly: readOnly,
                    grandTotalUsd: grandTotalUsd,
                    grandTotalKhr: grandTotalKhr,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (items.isNotEmpty)
          SaleCartBottomBar(
            grandTotalUsd: grandTotalUsd,
            grandTotalKhr: grandTotalKhr,
            canCheckout: canPrimaryAction,
            isProcessing: cartState.isFinalizing,
            actionLabel: primaryActionLabel,
            showClearCart: !readOnly,
            onClearCart: () => _showClearCartConfirmation(cartNotifier),
            onCheckout: () async {
              if (isPayLaterMode) {
                try {
                  final result = await cartNotifier.placeOrder();
                  await ref
                      .read(ordersProvider.notifier)
                      .load(date: DateTime.now());
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result.idempotentReplay
                            ? 'Open ticket already placed (replayed).'
                            : 'Open ticket placed.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _actionErrorMessage(
                          context: 'Place order failed',
                          error: e,
                        ),
                      ),
                    ),
                  );
                }
                return;
              }

              final ordersNotifier = ref.read(ordersProvider.notifier);
              _syncCashAmounts(cartNotifier);
              try {
                final result = await cartNotifier.checkout();
                await ordersNotifier.load(date: DateTime.now());
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_finalizeSuccessMessage(result))),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _actionErrorMessage(context: 'Checkout failed', error: e),
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
