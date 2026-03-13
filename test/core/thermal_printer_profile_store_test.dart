import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/printing/thermal_printer_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads default BT-583 profile when preferences are empty', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = ThermalPrinterProfileStore(prefs: prefs);

    final result = await store.load();

    expect(result.profileId, 'bt_583_58mm');
    expect(result.printerLabel, isNull);
  });

  test('persists and restores selected printer label', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = ThermalPrinterProfileStore(prefs: prefs);

    await store.save(
      const ThermalPrinterPreferences(
        profileId: 'bt_583_58mm',
        printerLabel: 'BT-583 Printer',
      ),
    );

    final result = await store.load();

    expect(result.profileId, 'bt_583_58mm');
    expect(result.printerLabel, 'BT-583 Printer');
  });

  test('falls back safely when preferences are corrupt', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'thermal_printer_preferences_v1': '{bad-json',
    });
    final prefs = await SharedPreferences.getInstance();
    final store = ThermalPrinterProfileStore(prefs: prefs);

    final result = await store.load();

    expect(result.profileId, 'bt_583_58mm');
    expect(result.printerLabel, isNull);
  });
}
