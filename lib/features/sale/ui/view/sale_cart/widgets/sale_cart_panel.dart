import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/printing/thermal_printer_controller.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/formatters/khr_currency_formatter.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_pricing.dart';
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
                      'Subtotal: \$${receipt.subtotalUsdExact.toStringAsFixed(2)}',
                    ),
                    if (receipt.discountUsdExact.abs() >= 0.005)
                      Text(
                        'Discount: -\$${receipt.discountUsdExact.toStringAsFixed(2)}',
                      ),
                    Text('Tax: \$${receipt.taxUsdExact.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
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
    required SaleCartNotifier cartNotifier,
    required bool readOnly,
    required double grandTotalUsd,
    required double grandTotalKhr,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SaleKhqrPopup(
        readOnly: readOnly,
        grandTotalUsd: grandTotalUsd,
        grandTotalKhr: grandTotalKhr,
      ),
    );
    if (result == true && mounted) {
      final ordersNotifier = ref.read(ordersProvider.notifier);
      try {
        final checkoutResult = await cartNotifier.checkout();
        await ordersNotifier.load(date: DateTime.now());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_finalizeSuccessMessage(checkoutResult))),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _actionErrorMessage(context: 'Checkout failed', error: e),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleKhqrPrimaryAction({
    required SaleCartNotifier cartNotifier,
    required bool readOnly,
    required double grandTotalUsd,
    required double grandTotalKhr,
    required String khqrStatus,
  }) async {
    if (readOnly) return;

    final normalizedStatus = SaleKhqrUiStates.normalize(khqrStatus);
    final needsFreshGenerate =
        normalizedStatus == SaleKhqrUiStates.readyToGenerate ||
        normalizedStatus == SaleKhqrUiStates.superseded ||
        normalizedStatus == SaleKhqrUiStates.expired ||
        normalizedStatus == SaleKhqrUiStates.cancelled;

    if (needsFreshGenerate) {
      try {
        await cartNotifier.generateKhqrAttempt();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _actionErrorMessage(context: 'Failed to generate KHQR', error: e),
            ),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    await _showKhqrPopup(
      cartNotifier: cartNotifier,
      readOnly: readOnly,
      grandTotalUsd: grandTotalUsd,
      grandTotalKhr: grandTotalKhr,
    );
  }

  Future<void> _handlePaymentMethodChanged({
    required String value,
    required SaleCartNotifier cartNotifier,
  }) async {
    await cartNotifier.setPaymentMethod(value);
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
    final khqrReceiverConfigured = ref.watch(
      saleKhqrReceiverConfiguredProvider,
    );
    final menuState = ref.watch(menuViewModelProvider);
    final cartNotifier = ref.read(saleCartProvider.notifier);
    final gate = ref.watch(saleAccessGateProvider);
    final connectivityStatus = ref.watch(appConnectivityStatusProvider);
    final readOnly = !gate.canAddToCart || cartState.isFinalizing;
    final policyState = ref.watch(policyNotifierProvider);
    final branchPolicy = policyState.branchPolicy;
    final fxRate = branchPolicy.saleFxRateKhrPerUsd;
    final groupLookup = {
      for (final g in menuState.modifierGroups) g.id: g,
      for (final g in menuState.hydratedModifierGroups.entries) g.key: g.value,
    };
    final cartPricing = SaleCartPricingCalculator.calculate(
      lines: items,
      groupLookup: groupLookup,
      branchPolicy: branchPolicy,
      resolvedDiscounts: cartState.resolvedDiscounts,
    );
    final subtotal = cartPricing.preDiscountSubtotalUsd;
    final discountUsd = cartPricing.discountUsd;
    final taxUsd = cartPricing.taxUsd;
    final grandTotalUsd = cartPricing.grandTotalUsd;
    final grandTotalKhr = cartPricing.grandTotalKhr;
    final tenderUsd = _tenderedUsd(
      grandTotalUsd,
      fxRate,
      paymentMethod: paymentMethod,
      tenderCurrency: tenderCurrency,
    );
    final isLarge = AppBreakpoints.isLarge(MediaQuery.sizeOf(context).width);
    final khqrStatus = SaleKhqrUiStates.normalize(cartState.khqrStatus);
    _syncKhqrPolling(
      paymentMethod: paymentMethod,
      khqrStatus: cartState.khqrStatus,
    );
    final orderType = cartState.saleType;
    final isOffline = connectivityStatus == AppConnectivityStatus.offline;
    final canCheckout =
        gate.canCheckout &&
        !cartState.isFinalizing &&
        items.isNotEmpty &&
        ((paymentMethod == 'cash' && tenderUsd >= grandTotalUsd) ||
            (paymentMethod == 'qr' &&
                saleKhqrCanFinalize(cartState.khqrStatus)));
    final canKhqrAction =
        gate.canCheckout &&
        !cartState.isFinalizing &&
        items.isNotEmpty &&
        khqrReceiverConfigured != false &&
        !isOffline;
    final canOfflineCashCapture =
        gate.canCreateDraftSale &&
        !cartState.isFinalizing &&
        items.isNotEmpty &&
        paymentMethod == 'cash';
    final qrPrimaryActionLabel = switch (khqrStatus) {
      SaleKhqrUiStates.superseded ||
      SaleKhqrUiStates.expired => 'Generate New Code',
      SaleKhqrUiStates.cancelled ||
      SaleKhqrUiStates.readyToGenerate => 'Generate Code',
      _ => 'View Code',
    };
    final canPrimaryAction = isOffline && paymentMethod == 'cash'
        ? canOfflineCashCapture
        : paymentMethod == 'qr'
        ? canKhqrAction
        : canCheckout;
    final primaryActionLabel = isOffline && paymentMethod == 'cash'
        ? 'Queue Cash Checkout'
        : paymentMethod == 'qr'
        ? qrPrimaryActionLabel
        : 'Checkout';
    final offlineKhqrUnavailableMessage = isOffline && paymentMethod == 'qr'
        ? 'KHQR checkout is unavailable while offline. Reconnect to continue.'
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
        if (isLarge) ...[
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
                        if (cartState.lastFinalizedOrderId != null)
                          Text('Order #: ${cartState.lastFinalizedOrderId}'),
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
                  onChanged: (value) =>
                      ref.read(saleCartProvider.notifier).setSaleType(value),
                ),
                if (offlineKhqrUnavailableMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    offlineKhqrUnavailableMessage,
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
                      ),
                  onTenderCurrencyChanged: (value) => ref
                      .read(saleCartProvider.notifier)
                      .setTenderCurrency(value),
                  usdController: _usdController,
                  khrController: _khrController,
                  subtotal: subtotal,
                  discountUsd: discountUsd,
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
                  khqrErrorCode: cartState.khqrErrorCode,
                  khqrReceiverConfigured: khqrReceiverConfigured,
                  linePricings: cartPricing.linePricings,
                  isResolvingDiscounts: cartState.isResolvingDiscounts,
                  discountResolutionError: cartState.discountResolutionError,
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
              if (isOffline && paymentMethod == 'cash') {
                try {
                  final result = await cartNotifier.captureOfflineCashOrder();
                  await ref
                      .read(ordersProvider.notifier)
                      .load(date: DateTime.now());
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order ${result.orderNumber} queued offline. Keep the app online later so cash checkout can sync automatically.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _actionErrorMessage(
                          context: 'Offline capture failed',
                          error: e,
                        ),
                      ),
                    ),
                  );
                }
                return;
              }

              if (isOffline && paymentMethod == 'qr') {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'KHQR checkout is unavailable while offline. Reconnect and try again.',
                    ),
                  ),
                );
                return;
              }

              if (paymentMethod == 'qr') {
                await _handleKhqrPrimaryAction(
                  cartNotifier: cartNotifier,
                  readOnly: readOnly,
                  grandTotalUsd: grandTotalUsd,
                  grandTotalKhr: grandTotalKhr,
                  khqrStatus: cartState.khqrStatus,
                );
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
