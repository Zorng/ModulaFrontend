import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:modular_pos/core/formatters/khr_currency_formatter.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_checkout_error_message.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';

class SaleKhqrPopup extends ConsumerStatefulWidget {
  const SaleKhqrPopup({
    super.key,
    required this.readOnly,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
  });

  final bool readOnly;
  final double grandTotalUsd;
  final double grandTotalKhr;

  @override
  ConsumerState<SaleKhqrPopup> createState() => _SaleKhqrPopupState();
}

class _SaleKhqrPopupState extends ConsumerState<SaleKhqrPopup> {
  bool _didScheduleClose = false;
  bool _didAttemptAutoGenerate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeGenerateOnOpen();
    });
  }

  Future<void> _maybeGenerateOnOpen() async {
    if (_didAttemptAutoGenerate || !mounted || widget.readOnly) return;
    final state = ref.read(saleCartProvider);
    final normalizedStatus = SaleKhqrUiStates.normalize(state.khqrStatus);
    final needsGenerate =
        state.paymentMethod.toLowerCase() == 'qr' &&
        !state.isKhqrLoading &&
        (state.khqrQrPayload == null || state.khqrQrPayload!.trim().isEmpty) &&
        normalizedStatus != SaleKhqrUiStates.paidConfirmed;
    if (!needsGenerate) return;
    _didAttemptAutoGenerate = true;
    try {
      await ref.read(saleCartProvider.notifier).generateKhqrAttempt();
    } catch (_) {
      if (!mounted) return;
      _didAttemptAutoGenerate = false;
    }
  }

  String _statusLabel(String status) {
    return switch (SaleKhqrUiStates.normalize(status)) {
      SaleKhqrUiStates.readyToGenerate => 'Ready to generate',
      SaleKhqrUiStates.waitingForPayment => 'Waiting for payment',
      SaleKhqrUiStates.paidConfirmed => 'Paid confirmed',
      SaleKhqrUiStates.cancelled => 'Cancelled',
      SaleKhqrUiStates.expired => 'Expired',
      SaleKhqrUiStates.pendingConfirmation => 'Pending confirmation',
      SaleKhqrUiStates.superseded => 'Superseded',
      _ => status,
    };
  }

  Color _statusColor(BuildContext context, String status) {
    return switch (SaleKhqrUiStates.normalize(status)) {
      SaleKhqrUiStates.paidConfirmed => Colors.green.shade700,
      SaleKhqrUiStates.cancelled => Colors.red.shade700,
      SaleKhqrUiStates.expired => Colors.orange.shade700,
      SaleKhqrUiStates.pendingConfirmation => Colors.amber.shade800,
      SaleKhqrUiStates.superseded => Colors.blueGrey.shade700,
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  String? _lifecycleHint(String status) {
    return switch (SaleKhqrUiStates.normalize(status)) {
      SaleKhqrUiStates.readyToGenerate =>
        'Generate KHQR to start the QR payment flow.',
      SaleKhqrUiStates.waitingForPayment =>
        'Customer can scan and pay now. Keep checking for confirmation.',
      SaleKhqrUiStates.pendingConfirmation =>
        'Payment may be in progress. Keep checking status before finalizing.',
      SaleKhqrUiStates.paidConfirmed =>
        'Payment is confirmed. You can finalize checkout now.',
      SaleKhqrUiStates.cancelled =>
        'This KHQR intent was cancelled. Generate a new one to continue.',
      SaleKhqrUiStates.expired =>
        'This KHQR intent expired. Generate a new one to continue.',
      SaleKhqrUiStates.superseded =>
        'This KHQR intent is no longer valid. Generate a new one to continue.',
      _ => null,
    };
  }

  String _payableLabel(String tenderCurrency) {
    return tenderCurrency.toUpperCase() == 'KHR'
        ? 'KHR ${formatKhrAmount(widget.grandTotalKhr)}'
        : '\$${widget.grandTotalUsd.toStringAsFixed(2)}';
  }

  bool _canRenderQr(String? payloadType, String? payload) {
    if (payload == null || payload.trim().isEmpty) return false;
    final normalized = payloadType?.trim().toUpperCase() ?? '';
    return normalized.isEmpty ||
        normalized == 'EMV_KHQR_STRING' ||
        normalized == 'RAW';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleCartProvider);
    final normalizedStatus = SaleKhqrUiStates.normalize(state.khqrStatus);
    final payload = state.khqrQrPayload?.trim();

    if (!_didAttemptAutoGenerate &&
        state.paymentMethod.toLowerCase() == 'qr' &&
        !state.isKhqrLoading &&
        (payload == null || payload.isEmpty) &&
        normalizedStatus != SaleKhqrUiStates.paidConfirmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeGenerateOnOpen();
      });
    }

    if (!_didScheduleClose &&
        normalizedStatus == SaleKhqrUiStates.paidConfirmed &&
        Navigator.of(context).canPop()) {
      _didScheduleClose = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = Navigator.of(context);
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (!mounted || !navigator.mounted) return;
          navigator.pop(true);
        });
      });
    }
    final statusColor = _statusColor(context, state.khqrStatus);
    final lifecycleHint = _lifecycleHint(state.khqrStatus);
    final errorText = SaleCheckoutErrorMessage.build(
      reasonCode: state.khqrErrorCode,
      fallback: state.khqrErrorMessage,
    );
    final canRenderQr = _canRenderQr(state.khqrPayloadType, payload);

    return AlertDialog(
      title: const Text('KHQR Payment'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: normalizedStatus == SaleKhqrUiStates.paidConfirmed
              ? SizedBox(
                  height: 320,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Payment Successful',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'KHQR payment is confirmed.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This popup will close automatically.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Payable',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          _payableLabel(state.tenderCurrency),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Status', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(state.khqrStatus),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          if (state.isKhqrLoading) ...[
                            const SizedBox(
                              height: 220,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ] else if (canRenderQr) ...[
                            QrImageView(
                              data: payload!,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                            ),
                          ] else ...[
                            SizedBox(
                              height: 220,
                              child: Center(
                                child: Text(
                                  payload == null || payload.isEmpty
                                      ? 'Generate KHQR to show the payment QR.'
                                      : 'This KHQR payload cannot be rendered as a QR image.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (state.khqrExpiresAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Expires: ${state.khqrExpiresAt!.toLocal().toString().substring(0, 19)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (state.khqrConfirmedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Confirmed: ${state.khqrConfirmedAt!.toLocal().toString().substring(0, 19)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                    if (lifecycleHint != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        lifecycleHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (errorText.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
      actions: normalizedStatus == SaleKhqrUiStates.paidConfirmed
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
    );
  }
}
