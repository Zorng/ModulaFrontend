@JS()
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:modular_pos/core/printing/thermal_printer_profiles.dart';
import 'package:modular_pos/core/printing/web_serial_printer_service.dart';

@JS('modulaThermalPrinterBridge')
external _ThermalPrinterBridge? get _bridge;

extension type _ThermalPrinterBridge(JSObject _) implements JSObject {
  external bool isSupported();
  external JSPromise<JSString> connect(JSNumber baudRate);
  external JSPromise<JSString> disconnect();
  @JS('writeBase64')
  external JSPromise<JSString> writeBase64(JSString payload);
}

class _WebSerialPrinterServiceWeb implements WebSerialPrinterService {
  @override
  Future<bool> isSupported() async {
    final bridge = _bridge;
    if (bridge == null) return false;
    return bridge.isSupported();
  }

  @override
  Future<ThermalPrinterTransportResult> connect({
    required ThermalPrinterProfile profile,
  }) async {
    final bridge = _bridge;
    if (bridge == null) {
      return const ThermalPrinterTransportResult(
        success: false,
        errorCode: 'BRIDGE_NOT_FOUND',
        errorMessage: 'Web Serial bridge is not registered.',
      );
    }
    try {
      final raw = await bridge.connect(profile.baudRate.toJS).toDart;
      return _parseResult(raw.toDart);
    } catch (error) {
      return ThermalPrinterTransportResult(
        success: false,
        errorCode: 'BRIDGE_CALL_FAILED',
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<ThermalPrinterTransportResult> disconnect() async {
    final bridge = _bridge;
    if (bridge == null) {
      return const ThermalPrinterTransportResult(
        success: false,
        errorCode: 'BRIDGE_NOT_FOUND',
        errorMessage: 'Web Serial bridge is not registered.',
      );
    }
    try {
      final raw = await bridge.disconnect().toDart;
      return _parseResult(raw.toDart);
    } catch (error) {
      return ThermalPrinterTransportResult(
        success: false,
        errorCode: 'BRIDGE_CALL_FAILED',
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<ThermalPrinterTransportResult> writeBytes(List<int> bytes) async {
    final bridge = _bridge;
    if (bridge == null) {
      return const ThermalPrinterTransportResult(
        success: false,
        errorCode: 'BRIDGE_NOT_FOUND',
        errorMessage: 'Web Serial bridge is not registered.',
      );
    }
    try {
      final raw = await bridge.writeBase64(base64Encode(bytes).toJS).toDart;
      return _parseResult(raw.toDart);
    } catch (error) {
      return ThermalPrinterTransportResult(
        success: false,
        errorCode: 'BRIDGE_CALL_FAILED',
        errorMessage: error.toString(),
      );
    }
  }

  ThermalPrinterTransportResult _parseResult(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const ThermalPrinterTransportResult(
          success: false,
          errorCode: 'INVALID_BRIDGE_RESPONSE',
          errorMessage: 'Web Serial bridge returned an unexpected response.',
        );
      }
      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      return ThermalPrinterTransportResult(
        success: map['success'] == true,
        printerLabel: map['printerLabel']?.toString(),
        errorCode: map['errorCode']?.toString(),
        errorMessage: map['errorMessage']?.toString(),
      );
    } catch (_) {
      return const ThermalPrinterTransportResult(
        success: false,
        errorCode: 'INVALID_BRIDGE_RESPONSE',
        errorMessage: 'Web Serial bridge returned an unexpected response.',
      );
    }
  }
}

WebSerialPrinterService createWebSerialPrinterService() =>
    _WebSerialPrinterServiceWeb();
