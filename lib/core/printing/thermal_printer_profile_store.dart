import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/printing/thermal_printer_profiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThermalPrinterPreferences {
  const ThermalPrinterPreferences({
    this.profileId = 'bt_583_58mm',
    this.printerLabel,
  });

  final String profileId;
  final String? printerLabel;

  ThermalPrinterProfile get profile =>
      ThermalPrinterProfiles.resolve(profileId);

  ThermalPrinterPreferences copyWith({
    String? profileId,
    Object? printerLabel = _unset,
  }) {
    return ThermalPrinterPreferences(
      profileId: profileId ?? this.profileId,
      printerLabel: printerLabel == _unset
          ? this.printerLabel
          : printerLabel as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      if (printerLabel != null) 'printerLabel': printerLabel,
    };
  }

  factory ThermalPrinterPreferences.fromJson(Map<String, dynamic> json) {
    return ThermalPrinterPreferences(
      profileId: json['profileId']?.toString() ?? 'bt_583_58mm',
      printerLabel: json['printerLabel']?.toString(),
    );
  }

  static const _unset = Object();
}

class ThermalPrinterProfileStore {
  ThermalPrinterProfileStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const _storageKey = 'thermal_printer_preferences_v1';
  final SharedPreferences? _prefs;

  Future<SharedPreferences> _resolvePrefs() async {
    return _prefs ?? SharedPreferences.getInstance();
  }

  Future<ThermalPrinterPreferences> load() async {
    final prefs = await _resolvePrefs();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const ThermalPrinterPreferences();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const ThermalPrinterPreferences();
      }
      return ThermalPrinterPreferences.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      return const ThermalPrinterPreferences();
    }
  }

  Future<void> save(ThermalPrinterPreferences preferences) async {
    final prefs = await _resolvePrefs();
    await prefs.setString(_storageKey, jsonEncode(preferences.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _resolvePrefs();
    await prefs.remove(_storageKey);
  }
}

final thermalPrinterProfileStoreProvider = Provider<ThermalPrinterProfileStore>(
  (_) => ThermalPrinterProfileStore(),
);
