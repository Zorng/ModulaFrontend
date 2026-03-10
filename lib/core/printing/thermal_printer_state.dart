import 'package:modular_pos/core/printing/thermal_printer_profiles.dart';

enum ThermalPrinterStatus {
  unsupported,
  disconnected,
  requestingPermission,
  connecting,
  connected,
  printing,
  error,
}

class ThermalPrinterState {
  const ThermalPrinterState({
    this.status = ThermalPrinterStatus.disconnected,
    this.profile = ThermalPrinterProfiles.bt58358mm,
    this.printerLabel,
    this.lastErrorMessage,
    this.lastEventMessage,
    this.lastEventIsError = false,
    this.lastEventId = 0,
    this.lastPrintedReceiptNumber,
  });

  final ThermalPrinterStatus status;
  final ThermalPrinterProfile profile;
  final String? printerLabel;
  final String? lastErrorMessage;
  final String? lastEventMessage;
  final bool lastEventIsError;
  final int lastEventId;
  final String? lastPrintedReceiptNumber;

  bool get isConnected =>
      status == ThermalPrinterStatus.connected ||
      status == ThermalPrinterStatus.printing;

  bool get isBusy =>
      status == ThermalPrinterStatus.requestingPermission ||
      status == ThermalPrinterStatus.connecting ||
      status == ThermalPrinterStatus.printing;

  String get statusLabel {
    switch (status) {
      case ThermalPrinterStatus.unsupported:
        return 'Unsupported browser';
      case ThermalPrinterStatus.disconnected:
        return 'Disconnected';
      case ThermalPrinterStatus.requestingPermission:
        return 'Requesting permission';
      case ThermalPrinterStatus.connecting:
        return 'Connecting';
      case ThermalPrinterStatus.connected:
        return 'Connected';
      case ThermalPrinterStatus.printing:
        return 'Printing';
      case ThermalPrinterStatus.error:
        return 'Printer error';
    }
  }

  ThermalPrinterState copyWith({
    ThermalPrinterStatus? status,
    ThermalPrinterProfile? profile,
    Object? printerLabel = _unset,
    Object? lastErrorMessage = _unset,
    Object? lastEventMessage = _unset,
    bool? lastEventIsError,
    int? lastEventId,
    Object? lastPrintedReceiptNumber = _unset,
  }) {
    return ThermalPrinterState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      printerLabel: printerLabel == _unset
          ? this.printerLabel
          : printerLabel as String?,
      lastErrorMessage: lastErrorMessage == _unset
          ? this.lastErrorMessage
          : lastErrorMessage as String?,
      lastEventMessage: lastEventMessage == _unset
          ? this.lastEventMessage
          : lastEventMessage as String?,
      lastEventIsError: lastEventIsError ?? this.lastEventIsError,
      lastEventId: lastEventId ?? this.lastEventId,
      lastPrintedReceiptNumber: lastPrintedReceiptNumber == _unset
          ? this.lastPrintedReceiptNumber
          : lastPrintedReceiptNumber as String?,
    );
  }

  static const _unset = Object();
}
