import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/printing/esc_pos_receipt_formatter.dart';
import 'package:modular_pos/core/printing/thermal_printer_profile_store.dart';
import 'package:modular_pos/core/printing/thermal_printer_profiles.dart';
import 'package:modular_pos/core/printing/thermal_printer_state.dart';
import 'package:modular_pos/core/printing/web_serial_printer_service.dart';

final thermalPrinterControllerProvider =
    NotifierProvider<ThermalPrinterController, ThermalPrinterState>(
      ThermalPrinterController.new,
    );

class ThermalPrinterController extends Notifier<ThermalPrinterState> {
  late final WebSerialPrinterService _service = ref.read(
    webSerialPrinterServiceProvider,
  );
  late final ThermalPrinterProfileStore _store = ref.read(
    thermalPrinterProfileStoreProvider,
  );

  Future<void> _printQueue = Future<void>.value();

  @override
  ThermalPrinterState build() {
    _restorePreferences();
    _probeSupport();
    return const ThermalPrinterState();
  }

  Future<void> connect() async {
    if (state.status == ThermalPrinterStatus.unsupported) {
      _pushEvent(
        'Use Chrome or another supported Chromium browser for Web Serial.',
        isError: true,
      );
      return;
    }
    if (state.isBusy) return;

    state = state.copyWith(
      status: ThermalPrinterStatus.requestingPermission,
      lastErrorMessage: null,
    );

    final result = await _service.connect(profile: state.profile);
    if (!result.success) {
      final message =
          result.errorMessage ?? 'Unable to connect to the thermal printer.';
      state = state.copyWith(
        status: ThermalPrinterStatus.error,
        lastErrorMessage: message,
        printerLabel: result.printerLabel ?? state.printerLabel,
      );
      _pushEvent(message, isError: true);
      return;
    }

    final printerLabel = result.printerLabel ?? state.printerLabel;
    state = state.copyWith(
      status: ThermalPrinterStatus.connected,
      printerLabel: printerLabel,
      lastErrorMessage: null,
    );
    await _savePreferences(printerLabel: printerLabel);
    _pushEvent('Printer connected${_printerSuffix(printerLabel)}.');
  }

  Future<void> disconnect() async {
    final result = await _service.disconnect();
    final printerLabel = state.printerLabel;
    state = state.copyWith(
      status: ThermalPrinterStatus.disconnected,
      lastErrorMessage: result.success
          ? null
          : (result.errorMessage ?? state.lastErrorMessage),
    );
    _pushEvent(
      result.success
          ? 'Printer disconnected${_printerSuffix(printerLabel)}.'
          : (result.errorMessage ?? 'Printer disconnect failed.'),
      isError: !result.success,
    );
  }

  Future<bool> printReceipt(ThermalReceiptPrintData receipt) async {
    final formatter = EscPosReceiptFormatter(profile: state.profile);
    final bytes = await formatter.formatReceipt(receipt);
    return printBytes(
      bytes,
      receiptNumber: receipt.receiptNumber,
      startedMessage: 'Printing receipt ${receipt.receiptNumber}...',
    );
  }

  Future<bool> printTestPage() async {
    final formatter = EscPosReceiptFormatter(profile: state.profile);
    final bytes = await formatter.buildTestPage(
      printerLabel: state.printerLabel,
    );
    return printBytes(
      bytes,
      startedMessage: 'Sending test print...',
      successMessage: 'Test print sent.',
    );
  }

  Future<bool> printBytes(
    List<int> bytes, {
    String? receiptNumber,
    String? startedMessage,
    String? successMessage,
  }) {
    final completer = Completer<bool>();
    _printQueue = _printQueue.catchError((_) {}).then((_) async {
      final result = await _performPrint(
        bytes,
        receiptNumber: receiptNumber,
        startedMessage: startedMessage,
        successMessage: successMessage,
      );
      completer.complete(result);
    });
    return completer.future;
  }

  void selectProfile(ThermalPrinterProfile profile) {
    state = state.copyWith(profile: profile);
    unawaited(_savePreferences());
  }

  Future<void> _restorePreferences() async {
    final preferences = await _store.load();
    state = state.copyWith(
      profile: preferences.profile,
      printerLabel: preferences.printerLabel,
    );
  }

  Future<void> _probeSupport() async {
    final supported = await _service.isSupported();
    if (supported) {
      if (state.status == ThermalPrinterStatus.unsupported) {
        state = state.copyWith(status: ThermalPrinterStatus.disconnected);
      }
      return;
    }
    state = state.copyWith(status: ThermalPrinterStatus.unsupported);
  }

  Future<bool> _performPrint(
    List<int> bytes, {
    String? receiptNumber,
    String? startedMessage,
    String? successMessage,
  }) async {
    if (!state.isConnected) {
      _pushEvent(
        'Printer is not connected. Connect BT-583 before printing.',
        isError: true,
      );
      return false;
    }

    final previousStatus = state.status;
    state = state.copyWith(
      status: ThermalPrinterStatus.printing,
      lastErrorMessage: null,
    );
    if (startedMessage != null && startedMessage.trim().isNotEmpty) {
      _pushEvent(startedMessage);
    }

    final result = await _service.writeBytes(bytes);
    if (!result.success) {
      final message = result.errorMessage ?? 'Thermal printer write failed.';
      state = state.copyWith(
        status: ThermalPrinterStatus.error,
        lastErrorMessage: message,
      );
      _pushEvent(message, isError: true);
      return false;
    }

    state = state.copyWith(
      status: previousStatus == ThermalPrinterStatus.unsupported
          ? ThermalPrinterStatus.unsupported
          : ThermalPrinterStatus.connected,
      lastErrorMessage: null,
      lastPrintedReceiptNumber: receiptNumber ?? state.lastPrintedReceiptNumber,
    );
    _pushEvent(
      successMessage ??
          (receiptNumber != null
              ? 'Receipt $receiptNumber sent to printer.'
              : 'Print job sent to printer.'),
    );
    return true;
  }

  Future<void> _savePreferences({String? printerLabel}) async {
    try {
      await _store.save(
        ThermalPrinterPreferences(
          profileId: state.profile.id,
          printerLabel: printerLabel ?? state.printerLabel,
        ),
      );
    } catch (error, stackTrace) {
      AppLog.e(
        '[ThermalPrinterController] Failed to save preferences',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _pushEvent(String message, {bool isError = false}) {
    state = state.copyWith(
      lastEventId: state.lastEventId + 1,
      lastEventMessage: message,
      lastEventIsError: isError,
    );
  }

  String _printerSuffix(String? printerLabel) {
    if (printerLabel == null || printerLabel.trim().isEmpty) {
      return '';
    }
    return ' (${printerLabel.trim()})';
  }
}
