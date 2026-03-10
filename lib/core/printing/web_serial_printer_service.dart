import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/printing/thermal_printer_profiles.dart';

import 'package:modular_pos/core/printing/web_serial_printer_service_stub.dart'
    if (dart.library.js_interop) 'package:modular_pos/core/printing/web_serial_printer_service_web.dart'
    as impl;

class ThermalPrinterTransportResult {
  const ThermalPrinterTransportResult({
    required this.success,
    this.printerLabel,
    this.errorCode,
    this.errorMessage,
  });

  final bool success;
  final String? printerLabel;
  final String? errorCode;
  final String? errorMessage;
}

abstract class WebSerialPrinterService {
  Future<bool> isSupported();

  Future<ThermalPrinterTransportResult> connect({
    required ThermalPrinterProfile profile,
  });

  Future<ThermalPrinterTransportResult> disconnect();

  Future<ThermalPrinterTransportResult> writeBytes(List<int> bytes);
}

WebSerialPrinterService createWebSerialPrinterService() =>
    impl.createWebSerialPrinterService();

final webSerialPrinterServiceProvider = Provider<WebSerialPrinterService>(
  (_) => createWebSerialPrinterService(),
);
