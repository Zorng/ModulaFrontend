import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/printing/esc_pos_receipt_formatter.dart';
import 'package:modular_pos/core/printing/thermal_printer_controller.dart';
import 'package:modular_pos/core/printing/thermal_printer_profile_store.dart';
import 'package:modular_pos/core/printing/thermal_printer_profiles.dart';
import 'package:modular_pos/core/printing/thermal_printer_state.dart';
import 'package:modular_pos/core/printing/web_serial_printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _FakeWebSerialPrinterService implements WebSerialPrinterService {
  bool supported = true;
  ThermalPrinterTransportResult connectResult =
      const ThermalPrinterTransportResult(
        success: true,
        printerLabel: 'BT-583 Printer',
      );
  ThermalPrinterTransportResult writeResult =
      const ThermalPrinterTransportResult(success: true);
  ThermalPrinterTransportResult disconnectResult =
      const ThermalPrinterTransportResult(success: true);
  final List<List<int>> writes = <List<int>>[];

  @override
  Future<ThermalPrinterTransportResult> connect({
    required ThermalPrinterProfile profile,
  }) async {
    return connectResult;
  }

  @override
  Future<ThermalPrinterTransportResult> disconnect() async => disconnectResult;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<ThermalPrinterTransportResult> writeBytes(List<int> bytes) async {
    writes.add(bytes);
    return writeResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('connects and stores BT-583 label', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeWebSerialPrinterService();

    final container = createTestContainer(
      overrides: [
        webSerialPrinterServiceProvider.overrideWithValue(service),
        thermalPrinterProfileStoreProvider.overrideWithValue(
          ThermalPrinterProfileStore(prefs: prefs),
        ),
      ],
    );

    final notifier = container.read(thermalPrinterControllerProvider.notifier);
    container.read(thermalPrinterControllerProvider);
    await Future<void>.delayed(Duration.zero);

    await notifier.connect();

    final state = container.read(thermalPrinterControllerProvider);
    final persisted = await ThermalPrinterProfileStore(prefs: prefs).load();

    expect(state.status, ThermalPrinterStatus.connected);
    expect(state.printerLabel, 'BT-583 Printer');
    expect(persisted.printerLabel, 'BT-583 Printer');
  });

  test('pushes an error event when printing while disconnected', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeWebSerialPrinterService();

    final container = createTestContainer(
      overrides: [
        webSerialPrinterServiceProvider.overrideWithValue(service),
        thermalPrinterProfileStoreProvider.overrideWithValue(
          ThermalPrinterProfileStore(prefs: prefs),
        ),
      ],
    );

    final notifier = container.read(thermalPrinterControllerProvider.notifier);
    container.read(thermalPrinterControllerProvider);
    await Future<void>.delayed(Duration.zero);

    final result = await notifier.printReceipt(
      ThermalReceiptPrintData(
        receiptNumber: 'RCP-1001',
        tenantName: 'Acme Coffee',
        branchName: 'BKK 1',
        cashierName: 'Nika',
        paymentMethod: 'cash',
        issuedAt: DateTime(2026, 3, 10),
        subtotalUsd: 1,
        taxUsd: 0,
        totalUsd: 1,
        totalKhr: 4000,
        items: const [],
      ),
    );

    final state = container.read(thermalPrinterControllerProvider);

    expect(result, isFalse);
    expect(state.lastEventMessage, contains('Printer is not connected'));
    expect(state.lastEventIsError, isTrue);
    expect(service.writes, isEmpty);
  });
}
