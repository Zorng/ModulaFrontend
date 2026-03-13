import 'package:modular_pos/core/printing/thermal_printer_profiles.dart';
import 'package:modular_pos/core/printing/web_serial_printer_service.dart';

class _UnsupportedWebSerialPrinterService implements WebSerialPrinterService {
  @override
  Future<ThermalPrinterTransportResult> connect({
    required ThermalPrinterProfile profile,
  }) async {
    return const ThermalPrinterTransportResult(
      success: false,
      errorCode: 'UNSUPPORTED_BROWSER',
      errorMessage: 'Web Serial is only available in supported browsers.',
    );
  }

  @override
  Future<ThermalPrinterTransportResult> disconnect() async {
    return const ThermalPrinterTransportResult(success: true);
  }

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<ThermalPrinterTransportResult> writeBytes(List<int> bytes) async {
    return const ThermalPrinterTransportResult(
      success: false,
      errorCode: 'UNSUPPORTED_BROWSER',
      errorMessage: 'Web Serial is only available in supported browsers.',
    );
  }
}

WebSerialPrinterService createWebSerialPrinterService() =>
    _UnsupportedWebSerialPrinterService();
