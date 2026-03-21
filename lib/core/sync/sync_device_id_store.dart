import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract class SyncDeviceIdStore {
  Future<String> getOrCreate();
}

class SharedPrefsSyncDeviceIdStore implements SyncDeviceIdStore {
  SharedPrefsSyncDeviceIdStore({SharedPreferences? prefs, Uuid? uuid})
    : _prefs = prefs,
      _uuid = uuid ?? const Uuid();

  static const storageKey = 'sync_device_id';

  final SharedPreferences? _prefs;
  final Uuid _uuid;

  Future<SharedPreferences> _resolvePrefs() async {
    return _prefs ?? SharedPreferences.getInstance();
  }

  @override
  Future<String> getOrCreate() async {
    final prefs = await _resolvePrefs();
    final existing = (prefs.getString(storageKey) ?? '').trim();
    if (existing.isNotEmpty) return existing;

    final generated = _uuid.v4();
    await prefs.setString(storageKey, generated);
    return generated;
  }
}

final syncDeviceIdStoreProvider = Provider<SyncDeviceIdStore>((ref) {
  return SharedPrefsSyncDeviceIdStore();
});

final syncDeviceIdProvider = FutureProvider<String>((ref) async {
  return ref.read(syncDeviceIdStoreProvider).getOrCreate();
});
