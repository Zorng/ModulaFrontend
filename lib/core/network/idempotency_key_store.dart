import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const idempotencyHeaderName = 'Idempotency-Key';
const idempotencyRequestExtraKey = '__idempotency_request__';
const _idempotencyUuidNamespace = '5642916f-e495-4bc6-8eb5-b730c4ec01d5';
const _uuid = Uuid();

enum IdempotencyScope { tenant, branch }

class IdempotencyRequest {
  const IdempotencyRequest({
    required this.actionKey,
    this.payload,
    this.intentId,
    this.scope = IdempotencyScope.branch,
  });

  final String actionKey;
  final Object? payload;
  final String? intentId;
  final IdempotencyScope scope;
}

Options withIdempotency({
  Options? options,
  required IdempotencyRequest request,
}) {
  final current = options ?? Options();
  final extra = <String, dynamic>{
    ...(current.extra ?? const <String, dynamic>{}),
  };
  extra[idempotencyRequestExtraKey] = request;
  return current.copyWith(extra: extra);
}

abstract class IdempotencyKeyStore {
  Future<String> getOrCreateKey(IdempotencyRequest request);
  Future<void> clear();
}

final idempotencyKeyStoreProvider = Provider<IdempotencyKeyStore>(
  (_) => InMemoryIdempotencyKeyStore(),
);

class InMemoryIdempotencyKeyStore implements IdempotencyKeyStore {
  final Map<String, _IdempotencyRecord> _records =
      <String, _IdempotencyRecord>{};

  @override
  Future<String> getOrCreateKey(IdempotencyRequest request) async {
    final payloadHash = _hashPayload(request.payload);
    final fingerprint = _fingerprint(request, payloadHash);
    final existing = _records[fingerprint];
    if (existing != null && existing.payloadHash == payloadHash) {
      return existing.key;
    }
    final key = _generateUuidV4();
    _records[fingerprint] = _IdempotencyRecord(
      key: key,
      payloadHash: payloadHash,
      updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    return key;
  }

  @override
  Future<void> clear() async {
    _records.clear();
  }
}

class SharedPrefsIdempotencyKeyStore implements IdempotencyKeyStore {
  SharedPrefsIdempotencyKeyStore(this._prefs);

  final SharedPreferences _prefs;
  static const _storageKey = 'idempotency_key_records_v1';
  static const _maxRecords = 500;
  bool _loaded = false;
  final Map<String, _IdempotencyRecord> _records =
      <String, _IdempotencyRecord>{};

  @override
  Future<String> getOrCreateKey(IdempotencyRequest request) async {
    await _ensureLoaded();

    final payloadHash = _hashPayload(request.payload);
    final fingerprint = _fingerprint(request, payloadHash);
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = _records[fingerprint];
    if (existing != null && existing.payloadHash == payloadHash) {
      _records[fingerprint] = existing.copyWith(updatedAtEpochMs: now);
      await _persist();
      return existing.key;
    }

    final key = _generateUuidV4();
    _records[fingerprint] = _IdempotencyRecord(
      key: key,
      payloadHash: payloadHash,
      updatedAtEpochMs: now,
    );
    _pruneIfNeeded();
    await _persist();
    return key;
  }

  @override
  Future<void> clear() async {
    _records.clear();
    _loaded = true;
    await _prefs.remove(_storageKey);
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _loaded = true;
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _loaded = true;
        return;
      }
      final records = decoded['records'];
      if (records is! Map) {
        _loaded = true;
        return;
      }

      for (final entry in records.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is! Map) continue;
        final parsed = _IdempotencyRecord.fromJson(
          value.map((k, v) => MapEntry(k.toString(), v)),
        );
        if (parsed != null) {
          _records[key] = parsed;
        }
      }
    } catch (_) {
      // Corrupt cache should not block requests.
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final payload = <String, dynamic>{
      'version': 1,
      'records': _records.map((key, value) => MapEntry(key, value.toJson())),
    };
    await _prefs.setString(_storageKey, jsonEncode(payload));
  }

  void _pruneIfNeeded() {
    if (_records.length <= _maxRecords) return;
    final sorted = _records.entries.toList()
      ..sort(
        (a, b) => a.value.updatedAtEpochMs.compareTo(b.value.updatedAtEpochMs),
      );
    final removeCount = _records.length - _maxRecords;
    for (var i = 0; i < removeCount; i++) {
      _records.remove(sorted[i].key);
    }
  }
}

class _IdempotencyRecord {
  const _IdempotencyRecord({
    required this.key,
    required this.payloadHash,
    required this.updatedAtEpochMs,
  });

  final String key;
  final String payloadHash;
  final int updatedAtEpochMs;

  _IdempotencyRecord copyWith({int? updatedAtEpochMs}) {
    return _IdempotencyRecord(
      key: key,
      payloadHash: payloadHash,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'payloadHash': payloadHash,
      'updatedAtEpochMs': updatedAtEpochMs,
    };
  }

  static _IdempotencyRecord? fromJson(Map<String, dynamic> json) {
    final key = json['key']?.toString() ?? '';
    final payloadHash = json['payloadHash']?.toString() ?? '';
    final updatedAtRaw = json['updatedAtEpochMs'];
    final updatedAt = updatedAtRaw is num ? updatedAtRaw.toInt() : 0;
    if (key.isEmpty || payloadHash.isEmpty || updatedAt <= 0) return null;
    return _IdempotencyRecord(
      key: key,
      payloadHash: payloadHash,
      updatedAtEpochMs: updatedAt,
    );
  }
}

String _fingerprint(IdempotencyRequest request, String payloadHash) {
  final parts = <String>[
    request.scope.name,
    request.actionKey.trim(),
    request.intentId?.trim() ?? '',
    payloadHash,
  ];
  return _uuid.v5(_idempotencyUuidNamespace, parts.join('::'));
}

String _hashPayload(Object? payload) {
  final canonical = _canonicalJson(payload);
  return _uuid.v5(_idempotencyUuidNamespace, canonical);
}

String _canonicalJson(Object? value) {
  final normalized = _normalize(value);
  return jsonEncode(normalized);
}

Object? _normalize(Object? value) {
  if (value is Map) {
    final sorted = SplayTreeMap<String, Object?>();
    for (final entry in value.entries) {
      sorted[entry.key.toString()] = _normalize(entry.value);
    }
    return sorted;
  }
  if (value is Iterable) {
    return value.map(_normalize).toList(growable: false);
  }
  if (value is num || value is bool || value is String || value == null) {
    return value;
  }
  return value.toString();
}

String _generateUuidV4() => _uuid.v4();
