import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/sync/sync_device_id_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('getOrCreate persists and reuses the same device id', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final store = SharedPrefsSyncDeviceIdStore(prefs: prefs);

    final first = await store.getOrCreate();
    final second = await store.getOrCreate();

    expect(first, isNotEmpty);
    expect(second, first);
    expect(prefs.getString(SharedPrefsSyncDeviceIdStore.storageKey), first);
  });
}
