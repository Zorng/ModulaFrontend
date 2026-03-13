import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:modular_pos/core/formatters/khr_currency_formatter.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_state.dart';
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
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _effectiveStatus(String status, DateTime? expiresAt) {
    final normalized = SaleKhqrUiStates.normalize(status);
    final canExpire =
        normalized == SaleKhqrUiStates.waitingForPayment ||
        normalized == SaleKhqrUiStates.pendingConfirmation;
    if (!canExpire || expiresAt == null) return normalized;
    return expiresAt.isAfter(DateTime.now())
        ? normalized
        : SaleKhqrUiStates.expired;
  }

  Duration? _timeRemaining(String effectiveStatus, DateTime? expiresAt) {
    if (expiresAt == null) return null;
    if (effectiveStatus != SaleKhqrUiStates.waitingForPayment &&
        effectiveStatus != SaleKhqrUiStates.pendingConfirmation) {
      return null;
    }
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      return Duration.zero;
    }
    return remaining;
  }

  String _formatCountdown(Duration remaining) {
    final totalSeconds = remaining.inSeconds.clamp(0, 359999);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String status, {required bool receiverUnavailable}) {
    if (receiverUnavailable) {
      return 'Receiver not configured';
    }
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

  Color _statusColor(
    BuildContext context,
    String status, {
    required bool receiverUnavailable,
  }) {
    if (receiverUnavailable) {
      return Colors.red.shade700;
    }
    return switch (SaleKhqrUiStates.normalize(status)) {
      SaleKhqrUiStates.paidConfirmed => Colors.green.shade700,
      SaleKhqrUiStates.cancelled => Colors.red.shade700,
      SaleKhqrUiStates.expired => Colors.orange.shade700,
      SaleKhqrUiStates.pendingConfirmation => Colors.amber.shade800,
      SaleKhqrUiStates.superseded => Colors.blueGrey.shade700,
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  String? _lifecycleHint(String status, {required bool receiverUnavailable}) {
    if (receiverUnavailable) {
      return 'This branch has no Bakong receiver configured. Ask an admin or manager to update the branch receiver before generating KHQR.';
    }
    return switch (SaleKhqrUiStates.normalize(status)) {
      SaleKhqrUiStates.readyToGenerate =>
        'KHQR has not been generated yet. Return to the cart to generate a payment QR.',
      SaleKhqrUiStates.waitingForPayment =>
        'Customer can scan and pay now. Keep checking for confirmation.',
      SaleKhqrUiStates.pendingConfirmation =>
        'Payment may already be in progress. Check the latest status before finalizing.',
      SaleKhqrUiStates.paidConfirmed =>
        'Payment is confirmed. You can finalize checkout now.',
      SaleKhqrUiStates.cancelled =>
        'This KHQR attempt was cancelled. Generate a new one to continue.',
      SaleKhqrUiStates.expired =>
        'This KHQR attempt expired. Generate a new one to continue.',
      SaleKhqrUiStates.superseded =>
        'Cart or payment details changed. Generate a new KHQR for the latest payable amount.',
      _ => null,
    };
  }

  String _payableLabel(String tenderCurrency) {
    return tenderCurrency.toUpperCase() == 'KHR'
        ? 'KHR ${formatKhrAmount(widget.grandTotalKhr)}'
        : '\$${widget.grandTotalUsd.toStringAsFixed(2)}';
  }

  String? _receiverName() {
    final receiverName = ref.watch(
      saleCartProvider.select((state) => state.khqrReceiverName?.trim()),
    );
    if (receiverName != null && receiverName.isNotEmpty) {
      return receiverName;
    }
    return null;
  }

  bool _canGenerate(
    String status,
    SaleCartState state, {
    required bool receiverUnavailable,
  }) {
    if (widget.readOnly || state.isKhqrLoading) return false;
    if (receiverUnavailable) return false;
    if (state.paymentMethod.toLowerCase() != 'qr') return false;
    final normalizedStatus = SaleKhqrUiStates.normalize(status);
    return normalizedStatus == SaleKhqrUiStates.superseded ||
        normalizedStatus == SaleKhqrUiStates.cancelled ||
        normalizedStatus == SaleKhqrUiStates.expired;
  }

  String _generateLabel(String status) {
    final normalized = SaleKhqrUiStates.normalize(status);
    if (normalized == SaleKhqrUiStates.expired) {
      return 'Refresh';
    }
    if (normalized == SaleKhqrUiStates.cancelled) {
      return 'Generate KHQR';
    }
    return 'Generate New KHQR';
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
    final receiverConfigured = ref.watch(saleKhqrReceiverConfiguredProvider);
    final normalizedStatus = _effectiveStatus(
      state.khqrStatus,
      state.khqrExpiresAt,
    );
    final normalizedErrorCode = SaleCheckoutReasonCodes.normalize(
      state.khqrErrorCode,
    );
    final receiverUnavailable =
        receiverConfigured == false ||
        normalizedErrorCode ==
            SaleCheckoutReasonCodes.khqrBranchReceiverNotConfigured;
    final canCancelAttempt =
        !widget.readOnly &&
        !state.isKhqrLoading &&
        (normalizedStatus == SaleKhqrUiStates.waitingForPayment ||
            normalizedStatus == SaleKhqrUiStates.pendingConfirmation);
    final payload = state.khqrQrPayload?.trim();

    final statusColor = _statusColor(
      context,
      normalizedStatus,
      receiverUnavailable: receiverUnavailable,
    );
    final lifecycleHint = _lifecycleHint(
      normalizedStatus,
      receiverUnavailable: receiverUnavailable,
    );
    final errorText = SaleCheckoutErrorMessage.build(
      reasonCode: state.khqrErrorCode,
      fallback: state.khqrErrorMessage,
    );
    final canRenderQr = _canRenderQr(state.khqrPayloadType, payload);
    final timeRemaining = _timeRemaining(normalizedStatus, state.khqrExpiresAt);
    final receiverName = _receiverName();

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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                            _statusLabel(
                              normalizedStatus,
                              receiverUnavailable: receiverUnavailable,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                QrImageView(
                                  data: payload!,
                                  version: QrVersions.auto,
                                  size: 220,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF0F172A),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                IgnorePointer(
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/bakong_logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (receiverName != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                receiverName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ] else ...[
                            SizedBox(
                              height: 220,
                              child: Center(
                                child: Text(
                                  payload == null || payload.isEmpty
                                      ? receiverUnavailable
                                            ? 'KHQR is unavailable until this branch receiver is configured.'
                                            : 'KHQR will appear here after it is generated from the cart.'
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
                        timeRemaining != null
                            ? 'Expires in ${_formatCountdown(timeRemaining)}'
                            : 'Expires: ${state.khqrExpiresAt!.toLocal().toString().substring(0, 19)}',
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
      actions: switch (normalizedStatus) {
        SaleKhqrUiStates.waitingForPayment ||
        SaleKhqrUiStates.pendingConfirmation => [
          OutlinedButton(
            onPressed: canCancelAttempt
                ? () async {
                    final navigator = Navigator.of(context);
                    try {
                      await ref
                          .read(saleCartProvider.notifier)
                          .cancelKhqrAttempt();
                      if (!mounted || !navigator.mounted) return;
                      navigator.pop(false);
                    } catch (_) {
                      if (!mounted) return;
                    }
                  }
                : null,
            child: const Text('Cancel KHQR'),
          ),
        ],
        SaleKhqrUiStates.expired => [
          if (_canGenerate(
            normalizedStatus,
            state,
            receiverUnavailable: receiverUnavailable,
          ))
            FilledButton(
              onPressed: () async {
                try {
                  await ref
                      .read(saleCartProvider.notifier)
                      .generateKhqrAttempt();
                } catch (_) {
                  if (!mounted) return;
                }
              },
              child: Text(_generateLabel(normalizedStatus)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
        ],
        SaleKhqrUiStates.paidConfirmed => [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Done'),
          ),
        ],
        _ => [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
        ],
      },
    );
  }
}
