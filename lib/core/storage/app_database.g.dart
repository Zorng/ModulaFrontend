// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncCheckpointEntriesTable extends SyncCheckpointEntries
    with TableInfo<$SyncCheckpointEntriesTable, SyncCheckpointEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCheckpointEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _moduleScopeSetKeyMeta = const VerificationMeta(
    'moduleScopeSetKey',
  );
  @override
  late final GeneratedColumn<String> moduleScopeSetKey =
      GeneratedColumn<String>(
        'module_scope_set_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta(
    'lastPullAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPullAt = GeneratedColumn<DateTime>(
    'last_pull_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessfulPullAtMeta =
      const VerificationMeta('lastSuccessfulPullAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulPullAt =
      GeneratedColumn<DateTime>(
        'last_successful_pull_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastPullStatusMeta = const VerificationMeta(
    'lastPullStatus',
  );
  @override
  late final GeneratedColumn<String> lastPullStatus = GeneratedColumn<String>(
    'last_pull_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    tenantId,
    branchId,
    accountId,
    moduleScopeSetKey,
    cursor,
    lastPullAt,
    lastSuccessfulPullAt,
    lastPullStatus,
    lastErrorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_checkpoint_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCheckpointEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('module_scope_set_key')) {
      context.handle(
        _moduleScopeSetKeyMeta,
        moduleScopeSetKey.isAcceptableOrUnknown(
          data['module_scope_set_key']!,
          _moduleScopeSetKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_moduleScopeSetKeyMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(
        _lastPullAtMeta,
        lastPullAt.isAcceptableOrUnknown(
          data['last_pull_at']!,
          _lastPullAtMeta,
        ),
      );
    }
    if (data.containsKey('last_successful_pull_at')) {
      context.handle(
        _lastSuccessfulPullAtMeta,
        lastSuccessfulPullAt.isAcceptableOrUnknown(
          data['last_successful_pull_at']!,
          _lastSuccessfulPullAtMeta,
        ),
      );
    }
    if (data.containsKey('last_pull_status')) {
      context.handle(
        _lastPullStatusMeta,
        lastPullStatus.isAcceptableOrUnknown(
          data['last_pull_status']!,
          _lastPullStatusMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    deviceId,
    tenantId,
    branchId,
    accountId,
    moduleScopeSetKey,
  };
  @override
  SyncCheckpointEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCheckpointEntry(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      moduleScopeSetKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module_scope_set_key'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      lastPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pull_at'],
      ),
      lastSuccessfulPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_successful_pull_at'],
      ),
      lastPullStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_pull_status'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
    );
  }

  @override
  $SyncCheckpointEntriesTable createAlias(String alias) {
    return $SyncCheckpointEntriesTable(attachedDatabase, alias);
  }
}

class SyncCheckpointEntry extends DataClass
    implements Insertable<SyncCheckpointEntry> {
  final String deviceId;
  final String tenantId;
  final String branchId;
  final String accountId;
  final String moduleScopeSetKey;
  final String? cursor;
  final DateTime? lastPullAt;
  final DateTime? lastSuccessfulPullAt;
  final String? lastPullStatus;
  final String? lastErrorCode;
  const SyncCheckpointEntry({
    required this.deviceId,
    required this.tenantId,
    required this.branchId,
    required this.accountId,
    required this.moduleScopeSetKey,
    this.cursor,
    this.lastPullAt,
    this.lastSuccessfulPullAt,
    this.lastPullStatus,
    this.lastErrorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['account_id'] = Variable<String>(accountId);
    map['module_scope_set_key'] = Variable<String>(moduleScopeSetKey);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || lastPullAt != null) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt);
    }
    if (!nullToAbsent || lastSuccessfulPullAt != null) {
      map['last_successful_pull_at'] = Variable<DateTime>(lastSuccessfulPullAt);
    }
    if (!nullToAbsent || lastPullStatus != null) {
      map['last_pull_status'] = Variable<String>(lastPullStatus);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    return map;
  }

  SyncCheckpointEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncCheckpointEntriesCompanion(
      deviceId: Value(deviceId),
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      accountId: Value(accountId),
      moduleScopeSetKey: Value(moduleScopeSetKey),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      lastPullAt: lastPullAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPullAt),
      lastSuccessfulPullAt: lastSuccessfulPullAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulPullAt),
      lastPullStatus: lastPullStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPullStatus),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
    );
  }

  factory SyncCheckpointEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCheckpointEntry(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      moduleScopeSetKey: serializer.fromJson<String>(json['moduleScopeSetKey']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      lastPullAt: serializer.fromJson<DateTime?>(json['lastPullAt']),
      lastSuccessfulPullAt: serializer.fromJson<DateTime?>(
        json['lastSuccessfulPullAt'],
      ),
      lastPullStatus: serializer.fromJson<String?>(json['lastPullStatus']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'accountId': serializer.toJson<String>(accountId),
      'moduleScopeSetKey': serializer.toJson<String>(moduleScopeSetKey),
      'cursor': serializer.toJson<String?>(cursor),
      'lastPullAt': serializer.toJson<DateTime?>(lastPullAt),
      'lastSuccessfulPullAt': serializer.toJson<DateTime?>(
        lastSuccessfulPullAt,
      ),
      'lastPullStatus': serializer.toJson<String?>(lastPullStatus),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
    };
  }

  SyncCheckpointEntry copyWith({
    String? deviceId,
    String? tenantId,
    String? branchId,
    String? accountId,
    String? moduleScopeSetKey,
    Value<String?> cursor = const Value.absent(),
    Value<DateTime?> lastPullAt = const Value.absent(),
    Value<DateTime?> lastSuccessfulPullAt = const Value.absent(),
    Value<String?> lastPullStatus = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
  }) => SyncCheckpointEntry(
    deviceId: deviceId ?? this.deviceId,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    accountId: accountId ?? this.accountId,
    moduleScopeSetKey: moduleScopeSetKey ?? this.moduleScopeSetKey,
    cursor: cursor.present ? cursor.value : this.cursor,
    lastPullAt: lastPullAt.present ? lastPullAt.value : this.lastPullAt,
    lastSuccessfulPullAt: lastSuccessfulPullAt.present
        ? lastSuccessfulPullAt.value
        : this.lastSuccessfulPullAt,
    lastPullStatus: lastPullStatus.present
        ? lastPullStatus.value
        : this.lastPullStatus,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
  );
  SyncCheckpointEntry copyWithCompanion(SyncCheckpointEntriesCompanion data) {
    return SyncCheckpointEntry(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      moduleScopeSetKey: data.moduleScopeSetKey.present
          ? data.moduleScopeSetKey.value
          : this.moduleScopeSetKey,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastPullAt: data.lastPullAt.present
          ? data.lastPullAt.value
          : this.lastPullAt,
      lastSuccessfulPullAt: data.lastSuccessfulPullAt.present
          ? data.lastSuccessfulPullAt.value
          : this.lastSuccessfulPullAt,
      lastPullStatus: data.lastPullStatus.present
          ? data.lastPullStatus.value
          : this.lastPullStatus,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpointEntry(')
          ..write('deviceId: $deviceId, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('moduleScopeSetKey: $moduleScopeSetKey, ')
          ..write('cursor: $cursor, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastSuccessfulPullAt: $lastSuccessfulPullAt, ')
          ..write('lastPullStatus: $lastPullStatus, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    tenantId,
    branchId,
    accountId,
    moduleScopeSetKey,
    cursor,
    lastPullAt,
    lastSuccessfulPullAt,
    lastPullStatus,
    lastErrorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCheckpointEntry &&
          other.deviceId == this.deviceId &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.accountId == this.accountId &&
          other.moduleScopeSetKey == this.moduleScopeSetKey &&
          other.cursor == this.cursor &&
          other.lastPullAt == this.lastPullAt &&
          other.lastSuccessfulPullAt == this.lastSuccessfulPullAt &&
          other.lastPullStatus == this.lastPullStatus &&
          other.lastErrorCode == this.lastErrorCode);
}

class SyncCheckpointEntriesCompanion
    extends UpdateCompanion<SyncCheckpointEntry> {
  final Value<String> deviceId;
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<String> accountId;
  final Value<String> moduleScopeSetKey;
  final Value<String?> cursor;
  final Value<DateTime?> lastPullAt;
  final Value<DateTime?> lastSuccessfulPullAt;
  final Value<String?> lastPullStatus;
  final Value<String?> lastErrorCode;
  final Value<int> rowid;
  const SyncCheckpointEntriesCompanion({
    this.deviceId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.moduleScopeSetKey = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.lastSuccessfulPullAt = const Value.absent(),
    this.lastPullStatus = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCheckpointEntriesCompanion.insert({
    required String deviceId,
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.accountId = const Value.absent(),
    required String moduleScopeSetKey,
    this.cursor = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.lastSuccessfulPullAt = const Value.absent(),
    this.lastPullStatus = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       moduleScopeSetKey = Value(moduleScopeSetKey);
  static Insertable<SyncCheckpointEntry> custom({
    Expression<String>? deviceId,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? accountId,
    Expression<String>? moduleScopeSetKey,
    Expression<String>? cursor,
    Expression<DateTime>? lastPullAt,
    Expression<DateTime>? lastSuccessfulPullAt,
    Expression<String>? lastPullStatus,
    Expression<String>? lastErrorCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (accountId != null) 'account_id': accountId,
      if (moduleScopeSetKey != null) 'module_scope_set_key': moduleScopeSetKey,
      if (cursor != null) 'cursor': cursor,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (lastSuccessfulPullAt != null)
        'last_successful_pull_at': lastSuccessfulPullAt,
      if (lastPullStatus != null) 'last_pull_status': lastPullStatus,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCheckpointEntriesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<String>? accountId,
    Value<String>? moduleScopeSetKey,
    Value<String?>? cursor,
    Value<DateTime?>? lastPullAt,
    Value<DateTime?>? lastSuccessfulPullAt,
    Value<String?>? lastPullStatus,
    Value<String?>? lastErrorCode,
    Value<int>? rowid,
  }) {
    return SyncCheckpointEntriesCompanion(
      deviceId: deviceId ?? this.deviceId,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      accountId: accountId ?? this.accountId,
      moduleScopeSetKey: moduleScopeSetKey ?? this.moduleScopeSetKey,
      cursor: cursor ?? this.cursor,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      lastSuccessfulPullAt: lastSuccessfulPullAt ?? this.lastSuccessfulPullAt,
      lastPullStatus: lastPullStatus ?? this.lastPullStatus,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (moduleScopeSetKey.present) {
      map['module_scope_set_key'] = Variable<String>(moduleScopeSetKey.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt.value);
    }
    if (lastSuccessfulPullAt.present) {
      map['last_successful_pull_at'] = Variable<DateTime>(
        lastSuccessfulPullAt.value,
      );
    }
    if (lastPullStatus.present) {
      map['last_pull_status'] = Variable<String>(lastPullStatus.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCheckpointEntriesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('moduleScopeSetKey: $moduleScopeSetKey, ')
          ..write('cursor: $cursor, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastSuccessfulPullAt: $lastSuccessfulPullAt, ')
          ..write('lastPullStatus: $lastPullStatus, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineCommandQueueEntriesTable extends OfflineCommandQueueEntries
    with TableInfo<$OfflineCommandQueueEntriesTable, OfflineCommandQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineCommandQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientOpIdMeta = const VerificationMeta(
    'clientOpId',
  );
  @override
  late final GeneratedColumn<String> clientOpId = GeneratedColumn<String>(
    'client_op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dependsOnClientOpIdMeta =
      const VerificationMeta('dependsOnClientOpId');
  @override
  late final GeneratedColumn<String> dependsOnClientOpId =
      GeneratedColumn<String>(
        'depends_on_client_op_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMessageMeta = const VerificationMeta(
    'lastErrorMessage',
  );
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
    'last_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientOpId,
    operationType,
    tenantId,
    branchId,
    accountId,
    occurredAt,
    payloadJson,
    dependsOnClientOpId,
    status,
    retryCount,
    createdAt,
    updatedAt,
    lastAttemptAt,
    lastSyncedAt,
    lastErrorCode,
    lastErrorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_command_queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineCommandQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_op_id')) {
      context.handle(
        _clientOpIdMeta,
        clientOpId.isAcceptableOrUnknown(
          data['client_op_id']!,
          _clientOpIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOpIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('depends_on_client_op_id')) {
      context.handle(
        _dependsOnClientOpIdMeta,
        dependsOnClientOpId.isAcceptableOrUnknown(
          data['depends_on_client_op_id']!,
          _dependsOnClientOpIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
        _lastErrorMessageMeta,
        lastErrorMessage.isAcceptableOrUnknown(
          data['last_error_message']!,
          _lastErrorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientOpId};
  @override
  OfflineCommandQueueEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineCommandQueueEntry(
      clientOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_op_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      dependsOnClientOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on_client_op_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      lastErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_message'],
      ),
    );
  }

  @override
  $OfflineCommandQueueEntriesTable createAlias(String alias) {
    return $OfflineCommandQueueEntriesTable(attachedDatabase, alias);
  }
}

class OfflineCommandQueueEntry extends DataClass
    implements Insertable<OfflineCommandQueueEntry> {
  final String clientOpId;
  final String operationType;
  final String tenantId;
  final String branchId;
  final String accountId;
  final DateTime occurredAt;
  final String payloadJson;
  final String? dependsOnClientOpId;
  final String status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  final DateTime? lastSyncedAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  const OfflineCommandQueueEntry({
    required this.clientOpId,
    required this.operationType,
    required this.tenantId,
    required this.branchId,
    required this.accountId,
    required this.occurredAt,
    required this.payloadJson,
    this.dependsOnClientOpId,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastAttemptAt,
    this.lastSyncedAt,
    this.lastErrorCode,
    this.lastErrorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_op_id'] = Variable<String>(clientOpId);
    map['operation_type'] = Variable<String>(operationType);
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['account_id'] = Variable<String>(accountId);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || dependsOnClientOpId != null) {
      map['depends_on_client_op_id'] = Variable<String>(dependsOnClientOpId);
    }
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    return map;
  }

  OfflineCommandQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return OfflineCommandQueueEntriesCompanion(
      clientOpId: Value(clientOpId),
      operationType: Value(operationType),
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      accountId: Value(accountId),
      occurredAt: Value(occurredAt),
      payloadJson: Value(payloadJson),
      dependsOnClientOpId: dependsOnClientOpId == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOnClientOpId),
      status: Value(status),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      lastErrorMessage: lastErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorMessage),
    );
  }

  factory OfflineCommandQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineCommandQueueEntry(
      clientOpId: serializer.fromJson<String>(json['clientOpId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      dependsOnClientOpId: serializer.fromJson<String?>(
        json['dependsOnClientOpId'],
      ),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientOpId': serializer.toJson<String>(clientOpId),
      'operationType': serializer.toJson<String>(operationType),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'accountId': serializer.toJson<String>(accountId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'dependsOnClientOpId': serializer.toJson<String?>(dependsOnClientOpId),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
    };
  }

  OfflineCommandQueueEntry copyWith({
    String? clientOpId,
    String? operationType,
    String? tenantId,
    String? branchId,
    String? accountId,
    DateTime? occurredAt,
    String? payloadJson,
    Value<String?> dependsOnClientOpId = const Value.absent(),
    String? status,
    int? retryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    Value<String?> lastErrorMessage = const Value.absent(),
  }) => OfflineCommandQueueEntry(
    clientOpId: clientOpId ?? this.clientOpId,
    operationType: operationType ?? this.operationType,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    accountId: accountId ?? this.accountId,
    occurredAt: occurredAt ?? this.occurredAt,
    payloadJson: payloadJson ?? this.payloadJson,
    dependsOnClientOpId: dependsOnClientOpId.present
        ? dependsOnClientOpId.value
        : this.dependsOnClientOpId,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    lastErrorMessage: lastErrorMessage.present
        ? lastErrorMessage.value
        : this.lastErrorMessage,
  );
  OfflineCommandQueueEntry copyWithCompanion(
    OfflineCommandQueueEntriesCompanion data,
  ) {
    return OfflineCommandQueueEntry(
      clientOpId: data.clientOpId.present
          ? data.clientOpId.value
          : this.clientOpId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      dependsOnClientOpId: data.dependsOnClientOpId.present
          ? data.dependsOnClientOpId.value
          : this.dependsOnClientOpId,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      lastErrorMessage: data.lastErrorMessage.present
          ? data.lastErrorMessage.value
          : this.lastErrorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineCommandQueueEntry(')
          ..write('clientOpId: $clientOpId, ')
          ..write('operationType: $operationType, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('dependsOnClientOpId: $dependsOnClientOpId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientOpId,
    operationType,
    tenantId,
    branchId,
    accountId,
    occurredAt,
    payloadJson,
    dependsOnClientOpId,
    status,
    retryCount,
    createdAt,
    updatedAt,
    lastAttemptAt,
    lastSyncedAt,
    lastErrorCode,
    lastErrorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineCommandQueueEntry &&
          other.clientOpId == this.clientOpId &&
          other.operationType == this.operationType &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.accountId == this.accountId &&
          other.occurredAt == this.occurredAt &&
          other.payloadJson == this.payloadJson &&
          other.dependsOnClientOpId == this.dependsOnClientOpId &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.lastErrorMessage == this.lastErrorMessage);
}

class OfflineCommandQueueEntriesCompanion
    extends UpdateCompanion<OfflineCommandQueueEntry> {
  final Value<String> clientOpId;
  final Value<String> operationType;
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<String> accountId;
  final Value<DateTime> occurredAt;
  final Value<String> payloadJson;
  final Value<String?> dependsOnClientOpId;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> lastErrorCode;
  final Value<String?> lastErrorMessage;
  final Value<int> rowid;
  const OfflineCommandQueueEntriesCompanion({
    this.clientOpId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.dependsOnClientOpId = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineCommandQueueEntriesCompanion.insert({
    required String clientOpId,
    required String operationType,
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.accountId = const Value.absent(),
    required DateTime occurredAt,
    required String payloadJson,
    this.dependsOnClientOpId = const Value.absent(),
    required String status,
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastAttemptAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientOpId = Value(clientOpId),
       operationType = Value(operationType),
       occurredAt = Value(occurredAt),
       payloadJson = Value(payloadJson),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OfflineCommandQueueEntry> custom({
    Expression<String>? clientOpId,
    Expression<String>? operationType,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? accountId,
    Expression<DateTime>? occurredAt,
    Expression<String>? payloadJson,
    Expression<String>? dependsOnClientOpId,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? lastErrorCode,
    Expression<String>? lastErrorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientOpId != null) 'client_op_id': clientOpId,
      if (operationType != null) 'operation_type': operationType,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (accountId != null) 'account_id': accountId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (dependsOnClientOpId != null)
        'depends_on_client_op_id': dependsOnClientOpId,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineCommandQueueEntriesCompanion copyWith({
    Value<String>? clientOpId,
    Value<String>? operationType,
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<String>? accountId,
    Value<DateTime>? occurredAt,
    Value<String>? payloadJson,
    Value<String?>? dependsOnClientOpId,
    Value<String>? status,
    Value<int>? retryCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? lastErrorCode,
    Value<String?>? lastErrorMessage,
    Value<int>? rowid,
  }) {
    return OfflineCommandQueueEntriesCompanion(
      clientOpId: clientOpId ?? this.clientOpId,
      operationType: operationType ?? this.operationType,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      accountId: accountId ?? this.accountId,
      occurredAt: occurredAt ?? this.occurredAt,
      payloadJson: payloadJson ?? this.payloadJson,
      dependsOnClientOpId: dependsOnClientOpId ?? this.dependsOnClientOpId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientOpId.present) {
      map['client_op_id'] = Variable<String>(clientOpId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (dependsOnClientOpId.present) {
      map['depends_on_client_op_id'] = Variable<String>(
        dependsOnClientOpId.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineCommandQueueEntriesCompanion(')
          ..write('clientOpId: $clientOpId, ')
          ..write('operationType: $operationType, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('dependsOnClientOpId: $dependsOnClientOpId, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleOutageOrderEntriesTable extends SaleOutageOrderEntries
    with TableInfo<$SaleOutageOrderEntriesTable, SaleOutageOrderEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleOutageOrderEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIntentIdMeta = const VerificationMeta(
    'localIntentId',
  );
  @override
  late final GeneratedColumn<String> localIntentId = GeneratedColumn<String>(
    'local_intent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderNumberMeta = const VerificationMeta(
    'orderNumber',
  );
  @override
  late final GeneratedColumn<String> orderNumber = GeneratedColumn<String>(
    'order_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleTypeMeta = const VerificationMeta(
    'saleType',
  );
  @override
  late final GeneratedColumn<String> saleType = GeneratedColumn<String>(
    'sale_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodRequestedMeta =
      const VerificationMeta('paymentMethodRequested');
  @override
  late final GeneratedColumn<String> paymentMethodRequested =
      GeneratedColumn<String>(
        'payment_method_requested',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _tenderCurrencyMeta = const VerificationMeta(
    'tenderCurrency',
  );
  @override
  late final GeneratedColumn<String> tenderCurrency = GeneratedColumn<String>(
    'tender_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashReceivedUsdMeta = const VerificationMeta(
    'cashReceivedUsd',
  );
  @override
  late final GeneratedColumn<double> cashReceivedUsd = GeneratedColumn<double>(
    'cash_received_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cashReceivedKhrMeta = const VerificationMeta(
    'cashReceivedKhr',
  );
  @override
  late final GeneratedColumn<double> cashReceivedKhr = GeneratedColumn<double>(
    'cash_received_khr',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalUsdMeta = const VerificationMeta(
    'totalUsd',
  );
  @override
  late final GeneratedColumn<double> totalUsd = GeneratedColumn<double>(
    'total_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalKhrMeta = const VerificationMeta(
    'totalKhr',
  );
  @override
  late final GeneratedColumn<double> totalKhr = GeneratedColumn<double>(
    'total_khr',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linesJsonMeta = const VerificationMeta(
    'linesJson',
  );
  @override
  late final GeneratedColumn<String> linesJson = GeneratedColumn<String>(
    'lines_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceModeMeta = const VerificationMeta(
    'sourceMode',
  );
  @override
  late final GeneratedColumn<String> sourceMode = GeneratedColumn<String>(
    'source_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backendOrderIdMeta = const VerificationMeta(
    'backendOrderId',
  );
  @override
  late final GeneratedColumn<String> backendOrderId = GeneratedColumn<String>(
    'backend_order_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _materializedAtMeta = const VerificationMeta(
    'materializedAt',
  );
  @override
  late final GeneratedColumn<DateTime> materializedAt =
      GeneratedColumn<DateTime>(
        'materialized_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _claimedPaymentMethodMeta =
      const VerificationMeta('claimedPaymentMethod');
  @override
  late final GeneratedColumn<String> claimedPaymentMethod =
      GeneratedColumn<String>(
        'claimed_payment_method',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _claimedTenderAmountMeta =
      const VerificationMeta('claimedTenderAmount');
  @override
  late final GeneratedColumn<double> claimedTenderAmount =
      GeneratedColumn<double>(
        'claimed_tender_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _proofImageUrlMeta = const VerificationMeta(
    'proofImageUrl',
  );
  @override
  late final GeneratedColumn<String> proofImageUrl = GeneratedColumn<String>(
    'proof_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerReferenceMeta = const VerificationMeta(
    'customerReference',
  );
  @override
  late final GeneratedColumn<String> customerReference =
      GeneratedColumn<String>(
        'customer_reference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _claimRecordedAtMeta = const VerificationMeta(
    'claimRecordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> claimRecordedAt =
      GeneratedColumn<DateTime>(
        'claim_recorded_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _backendClaimIdMeta = const VerificationMeta(
    'backendClaimId',
  );
  @override
  late final GeneratedColumn<String> backendClaimId = GeneratedColumn<String>(
    'backend_claim_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _claimSubmittedAtMeta = const VerificationMeta(
    'claimSubmittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> claimSubmittedAt =
      GeneratedColumn<DateTime>(
        'claim_submitted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMessageMeta = const VerificationMeta(
    'lastErrorMessage',
  );
  @override
  late final GeneratedColumn<String> lastErrorMessage = GeneratedColumn<String>(
    'last_error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localIntentId,
    orderNumber,
    tenantId,
    branchId,
    accountId,
    saleType,
    paymentMethodRequested,
    tenderCurrency,
    cashReceivedUsd,
    cashReceivedKhr,
    totalUsd,
    totalKhr,
    linesJson,
    state,
    sourceMode,
    backendOrderId,
    materializedAt,
    claimedPaymentMethod,
    claimedTenderAmount,
    proofImageUrl,
    customerReference,
    note,
    claimRecordedAt,
    backendClaimId,
    claimSubmittedAt,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_outage_order_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleOutageOrderEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_intent_id')) {
      context.handle(
        _localIntentIdMeta,
        localIntentId.isAcceptableOrUnknown(
          data['local_intent_id']!,
          _localIntentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localIntentIdMeta);
    }
    if (data.containsKey('order_number')) {
      context.handle(
        _orderNumberMeta,
        orderNumber.isAcceptableOrUnknown(
          data['order_number']!,
          _orderNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderNumberMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('sale_type')) {
      context.handle(
        _saleTypeMeta,
        saleType.isAcceptableOrUnknown(data['sale_type']!, _saleTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_saleTypeMeta);
    }
    if (data.containsKey('payment_method_requested')) {
      context.handle(
        _paymentMethodRequestedMeta,
        paymentMethodRequested.isAcceptableOrUnknown(
          data['payment_method_requested']!,
          _paymentMethodRequestedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodRequestedMeta);
    }
    if (data.containsKey('tender_currency')) {
      context.handle(
        _tenderCurrencyMeta,
        tenderCurrency.isAcceptableOrUnknown(
          data['tender_currency']!,
          _tenderCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tenderCurrencyMeta);
    }
    if (data.containsKey('cash_received_usd')) {
      context.handle(
        _cashReceivedUsdMeta,
        cashReceivedUsd.isAcceptableOrUnknown(
          data['cash_received_usd']!,
          _cashReceivedUsdMeta,
        ),
      );
    }
    if (data.containsKey('cash_received_khr')) {
      context.handle(
        _cashReceivedKhrMeta,
        cashReceivedKhr.isAcceptableOrUnknown(
          data['cash_received_khr']!,
          _cashReceivedKhrMeta,
        ),
      );
    }
    if (data.containsKey('total_usd')) {
      context.handle(
        _totalUsdMeta,
        totalUsd.isAcceptableOrUnknown(data['total_usd']!, _totalUsdMeta),
      );
    } else if (isInserting) {
      context.missing(_totalUsdMeta);
    }
    if (data.containsKey('total_khr')) {
      context.handle(
        _totalKhrMeta,
        totalKhr.isAcceptableOrUnknown(data['total_khr']!, _totalKhrMeta),
      );
    } else if (isInserting) {
      context.missing(_totalKhrMeta);
    }
    if (data.containsKey('lines_json')) {
      context.handle(
        _linesJsonMeta,
        linesJson.isAcceptableOrUnknown(data['lines_json']!, _linesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_linesJsonMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('source_mode')) {
      context.handle(
        _sourceModeMeta,
        sourceMode.isAcceptableOrUnknown(data['source_mode']!, _sourceModeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceModeMeta);
    }
    if (data.containsKey('backend_order_id')) {
      context.handle(
        _backendOrderIdMeta,
        backendOrderId.isAcceptableOrUnknown(
          data['backend_order_id']!,
          _backendOrderIdMeta,
        ),
      );
    }
    if (data.containsKey('materialized_at')) {
      context.handle(
        _materializedAtMeta,
        materializedAt.isAcceptableOrUnknown(
          data['materialized_at']!,
          _materializedAtMeta,
        ),
      );
    }
    if (data.containsKey('claimed_payment_method')) {
      context.handle(
        _claimedPaymentMethodMeta,
        claimedPaymentMethod.isAcceptableOrUnknown(
          data['claimed_payment_method']!,
          _claimedPaymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('claimed_tender_amount')) {
      context.handle(
        _claimedTenderAmountMeta,
        claimedTenderAmount.isAcceptableOrUnknown(
          data['claimed_tender_amount']!,
          _claimedTenderAmountMeta,
        ),
      );
    }
    if (data.containsKey('proof_image_url')) {
      context.handle(
        _proofImageUrlMeta,
        proofImageUrl.isAcceptableOrUnknown(
          data['proof_image_url']!,
          _proofImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('customer_reference')) {
      context.handle(
        _customerReferenceMeta,
        customerReference.isAcceptableOrUnknown(
          data['customer_reference']!,
          _customerReferenceMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('claim_recorded_at')) {
      context.handle(
        _claimRecordedAtMeta,
        claimRecordedAt.isAcceptableOrUnknown(
          data['claim_recorded_at']!,
          _claimRecordedAtMeta,
        ),
      );
    }
    if (data.containsKey('backend_claim_id')) {
      context.handle(
        _backendClaimIdMeta,
        backendClaimId.isAcceptableOrUnknown(
          data['backend_claim_id']!,
          _backendClaimIdMeta,
        ),
      );
    }
    if (data.containsKey('claim_submitted_at')) {
      context.handle(
        _claimSubmittedAtMeta,
        claimSubmittedAt.isAcceptableOrUnknown(
          data['claim_submitted_at']!,
          _claimSubmittedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('last_error_message')) {
      context.handle(
        _lastErrorMessageMeta,
        lastErrorMessage.isAcceptableOrUnknown(
          data['last_error_message']!,
          _lastErrorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localIntentId};
  @override
  SaleOutageOrderEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleOutageOrderEntry(
      localIntentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_intent_id'],
      )!,
      orderNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_number'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      saleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_type'],
      )!,
      paymentMethodRequested: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method_requested'],
      )!,
      tenderCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tender_currency'],
      )!,
      cashReceivedUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_received_usd'],
      )!,
      cashReceivedKhr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_received_khr'],
      )!,
      totalUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_usd'],
      )!,
      totalKhr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_khr'],
      )!,
      linesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lines_json'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      sourceMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_mode'],
      )!,
      backendOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backend_order_id'],
      ),
      materializedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}materialized_at'],
      ),
      claimedPaymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claimed_payment_method'],
      ),
      claimedTenderAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}claimed_tender_amount'],
      ),
      proofImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proof_image_url'],
      ),
      customerReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_reference'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      claimRecordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}claim_recorded_at'],
      ),
      backendClaimId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backend_claim_id'],
      ),
      claimSubmittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}claim_submitted_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      lastErrorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SaleOutageOrderEntriesTable createAlias(String alias) {
    return $SaleOutageOrderEntriesTable(attachedDatabase, alias);
  }
}

class SaleOutageOrderEntry extends DataClass
    implements Insertable<SaleOutageOrderEntry> {
  final String localIntentId;
  final String orderNumber;
  final String tenantId;
  final String branchId;
  final String accountId;
  final String saleType;
  final String paymentMethodRequested;
  final String tenderCurrency;
  final double cashReceivedUsd;
  final double cashReceivedKhr;
  final double totalUsd;
  final double totalKhr;
  final String linesJson;
  final String state;
  final String sourceMode;
  final String? backendOrderId;
  final DateTime? materializedAt;
  final String? claimedPaymentMethod;
  final double? claimedTenderAmount;
  final String? proofImageUrl;
  final String? customerReference;
  final String? note;
  final DateTime? claimRecordedAt;
  final String? backendClaimId;
  final DateTime? claimSubmittedAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SaleOutageOrderEntry({
    required this.localIntentId,
    required this.orderNumber,
    required this.tenantId,
    required this.branchId,
    required this.accountId,
    required this.saleType,
    required this.paymentMethodRequested,
    required this.tenderCurrency,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.totalUsd,
    required this.totalKhr,
    required this.linesJson,
    required this.state,
    required this.sourceMode,
    this.backendOrderId,
    this.materializedAt,
    this.claimedPaymentMethod,
    this.claimedTenderAmount,
    this.proofImageUrl,
    this.customerReference,
    this.note,
    this.claimRecordedAt,
    this.backendClaimId,
    this.claimSubmittedAt,
    this.lastErrorCode,
    this.lastErrorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_intent_id'] = Variable<String>(localIntentId);
    map['order_number'] = Variable<String>(orderNumber);
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['account_id'] = Variable<String>(accountId);
    map['sale_type'] = Variable<String>(saleType);
    map['payment_method_requested'] = Variable<String>(paymentMethodRequested);
    map['tender_currency'] = Variable<String>(tenderCurrency);
    map['cash_received_usd'] = Variable<double>(cashReceivedUsd);
    map['cash_received_khr'] = Variable<double>(cashReceivedKhr);
    map['total_usd'] = Variable<double>(totalUsd);
    map['total_khr'] = Variable<double>(totalKhr);
    map['lines_json'] = Variable<String>(linesJson);
    map['state'] = Variable<String>(state);
    map['source_mode'] = Variable<String>(sourceMode);
    if (!nullToAbsent || backendOrderId != null) {
      map['backend_order_id'] = Variable<String>(backendOrderId);
    }
    if (!nullToAbsent || materializedAt != null) {
      map['materialized_at'] = Variable<DateTime>(materializedAt);
    }
    if (!nullToAbsent || claimedPaymentMethod != null) {
      map['claimed_payment_method'] = Variable<String>(claimedPaymentMethod);
    }
    if (!nullToAbsent || claimedTenderAmount != null) {
      map['claimed_tender_amount'] = Variable<double>(claimedTenderAmount);
    }
    if (!nullToAbsent || proofImageUrl != null) {
      map['proof_image_url'] = Variable<String>(proofImageUrl);
    }
    if (!nullToAbsent || customerReference != null) {
      map['customer_reference'] = Variable<String>(customerReference);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || claimRecordedAt != null) {
      map['claim_recorded_at'] = Variable<DateTime>(claimRecordedAt);
    }
    if (!nullToAbsent || backendClaimId != null) {
      map['backend_claim_id'] = Variable<String>(backendClaimId);
    }
    if (!nullToAbsent || claimSubmittedAt != null) {
      map['claim_submitted_at'] = Variable<DateTime>(claimSubmittedAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || lastErrorMessage != null) {
      map['last_error_message'] = Variable<String>(lastErrorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SaleOutageOrderEntriesCompanion toCompanion(bool nullToAbsent) {
    return SaleOutageOrderEntriesCompanion(
      localIntentId: Value(localIntentId),
      orderNumber: Value(orderNumber),
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      accountId: Value(accountId),
      saleType: Value(saleType),
      paymentMethodRequested: Value(paymentMethodRequested),
      tenderCurrency: Value(tenderCurrency),
      cashReceivedUsd: Value(cashReceivedUsd),
      cashReceivedKhr: Value(cashReceivedKhr),
      totalUsd: Value(totalUsd),
      totalKhr: Value(totalKhr),
      linesJson: Value(linesJson),
      state: Value(state),
      sourceMode: Value(sourceMode),
      backendOrderId: backendOrderId == null && nullToAbsent
          ? const Value.absent()
          : Value(backendOrderId),
      materializedAt: materializedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(materializedAt),
      claimedPaymentMethod: claimedPaymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(claimedPaymentMethod),
      claimedTenderAmount: claimedTenderAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(claimedTenderAmount),
      proofImageUrl: proofImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(proofImageUrl),
      customerReference: customerReference == null && nullToAbsent
          ? const Value.absent()
          : Value(customerReference),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      claimRecordedAt: claimRecordedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(claimRecordedAt),
      backendClaimId: backendClaimId == null && nullToAbsent
          ? const Value.absent()
          : Value(backendClaimId),
      claimSubmittedAt: claimSubmittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(claimSubmittedAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      lastErrorMessage: lastErrorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SaleOutageOrderEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleOutageOrderEntry(
      localIntentId: serializer.fromJson<String>(json['localIntentId']),
      orderNumber: serializer.fromJson<String>(json['orderNumber']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      saleType: serializer.fromJson<String>(json['saleType']),
      paymentMethodRequested: serializer.fromJson<String>(
        json['paymentMethodRequested'],
      ),
      tenderCurrency: serializer.fromJson<String>(json['tenderCurrency']),
      cashReceivedUsd: serializer.fromJson<double>(json['cashReceivedUsd']),
      cashReceivedKhr: serializer.fromJson<double>(json['cashReceivedKhr']),
      totalUsd: serializer.fromJson<double>(json['totalUsd']),
      totalKhr: serializer.fromJson<double>(json['totalKhr']),
      linesJson: serializer.fromJson<String>(json['linesJson']),
      state: serializer.fromJson<String>(json['state']),
      sourceMode: serializer.fromJson<String>(json['sourceMode']),
      backendOrderId: serializer.fromJson<String?>(json['backendOrderId']),
      materializedAt: serializer.fromJson<DateTime?>(json['materializedAt']),
      claimedPaymentMethod: serializer.fromJson<String?>(
        json['claimedPaymentMethod'],
      ),
      claimedTenderAmount: serializer.fromJson<double?>(
        json['claimedTenderAmount'],
      ),
      proofImageUrl: serializer.fromJson<String?>(json['proofImageUrl']),
      customerReference: serializer.fromJson<String?>(
        json['customerReference'],
      ),
      note: serializer.fromJson<String?>(json['note']),
      claimRecordedAt: serializer.fromJson<DateTime?>(json['claimRecordedAt']),
      backendClaimId: serializer.fromJson<String?>(json['backendClaimId']),
      claimSubmittedAt: serializer.fromJson<DateTime?>(
        json['claimSubmittedAt'],
      ),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      lastErrorMessage: serializer.fromJson<String?>(json['lastErrorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localIntentId': serializer.toJson<String>(localIntentId),
      'orderNumber': serializer.toJson<String>(orderNumber),
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'accountId': serializer.toJson<String>(accountId),
      'saleType': serializer.toJson<String>(saleType),
      'paymentMethodRequested': serializer.toJson<String>(
        paymentMethodRequested,
      ),
      'tenderCurrency': serializer.toJson<String>(tenderCurrency),
      'cashReceivedUsd': serializer.toJson<double>(cashReceivedUsd),
      'cashReceivedKhr': serializer.toJson<double>(cashReceivedKhr),
      'totalUsd': serializer.toJson<double>(totalUsd),
      'totalKhr': serializer.toJson<double>(totalKhr),
      'linesJson': serializer.toJson<String>(linesJson),
      'state': serializer.toJson<String>(state),
      'sourceMode': serializer.toJson<String>(sourceMode),
      'backendOrderId': serializer.toJson<String?>(backendOrderId),
      'materializedAt': serializer.toJson<DateTime?>(materializedAt),
      'claimedPaymentMethod': serializer.toJson<String?>(claimedPaymentMethod),
      'claimedTenderAmount': serializer.toJson<double?>(claimedTenderAmount),
      'proofImageUrl': serializer.toJson<String?>(proofImageUrl),
      'customerReference': serializer.toJson<String?>(customerReference),
      'note': serializer.toJson<String?>(note),
      'claimRecordedAt': serializer.toJson<DateTime?>(claimRecordedAt),
      'backendClaimId': serializer.toJson<String?>(backendClaimId),
      'claimSubmittedAt': serializer.toJson<DateTime?>(claimSubmittedAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'lastErrorMessage': serializer.toJson<String?>(lastErrorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SaleOutageOrderEntry copyWith({
    String? localIntentId,
    String? orderNumber,
    String? tenantId,
    String? branchId,
    String? accountId,
    String? saleType,
    String? paymentMethodRequested,
    String? tenderCurrency,
    double? cashReceivedUsd,
    double? cashReceivedKhr,
    double? totalUsd,
    double? totalKhr,
    String? linesJson,
    String? state,
    String? sourceMode,
    Value<String?> backendOrderId = const Value.absent(),
    Value<DateTime?> materializedAt = const Value.absent(),
    Value<String?> claimedPaymentMethod = const Value.absent(),
    Value<double?> claimedTenderAmount = const Value.absent(),
    Value<String?> proofImageUrl = const Value.absent(),
    Value<String?> customerReference = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<DateTime?> claimRecordedAt = const Value.absent(),
    Value<String?> backendClaimId = const Value.absent(),
    Value<DateTime?> claimSubmittedAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    Value<String?> lastErrorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SaleOutageOrderEntry(
    localIntentId: localIntentId ?? this.localIntentId,
    orderNumber: orderNumber ?? this.orderNumber,
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    accountId: accountId ?? this.accountId,
    saleType: saleType ?? this.saleType,
    paymentMethodRequested:
        paymentMethodRequested ?? this.paymentMethodRequested,
    tenderCurrency: tenderCurrency ?? this.tenderCurrency,
    cashReceivedUsd: cashReceivedUsd ?? this.cashReceivedUsd,
    cashReceivedKhr: cashReceivedKhr ?? this.cashReceivedKhr,
    totalUsd: totalUsd ?? this.totalUsd,
    totalKhr: totalKhr ?? this.totalKhr,
    linesJson: linesJson ?? this.linesJson,
    state: state ?? this.state,
    sourceMode: sourceMode ?? this.sourceMode,
    backendOrderId: backendOrderId.present
        ? backendOrderId.value
        : this.backendOrderId,
    materializedAt: materializedAt.present
        ? materializedAt.value
        : this.materializedAt,
    claimedPaymentMethod: claimedPaymentMethod.present
        ? claimedPaymentMethod.value
        : this.claimedPaymentMethod,
    claimedTenderAmount: claimedTenderAmount.present
        ? claimedTenderAmount.value
        : this.claimedTenderAmount,
    proofImageUrl: proofImageUrl.present
        ? proofImageUrl.value
        : this.proofImageUrl,
    customerReference: customerReference.present
        ? customerReference.value
        : this.customerReference,
    note: note.present ? note.value : this.note,
    claimRecordedAt: claimRecordedAt.present
        ? claimRecordedAt.value
        : this.claimRecordedAt,
    backendClaimId: backendClaimId.present
        ? backendClaimId.value
        : this.backendClaimId,
    claimSubmittedAt: claimSubmittedAt.present
        ? claimSubmittedAt.value
        : this.claimSubmittedAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    lastErrorMessage: lastErrorMessage.present
        ? lastErrorMessage.value
        : this.lastErrorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SaleOutageOrderEntry copyWithCompanion(SaleOutageOrderEntriesCompanion data) {
    return SaleOutageOrderEntry(
      localIntentId: data.localIntentId.present
          ? data.localIntentId.value
          : this.localIntentId,
      orderNumber: data.orderNumber.present
          ? data.orderNumber.value
          : this.orderNumber,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      saleType: data.saleType.present ? data.saleType.value : this.saleType,
      paymentMethodRequested: data.paymentMethodRequested.present
          ? data.paymentMethodRequested.value
          : this.paymentMethodRequested,
      tenderCurrency: data.tenderCurrency.present
          ? data.tenderCurrency.value
          : this.tenderCurrency,
      cashReceivedUsd: data.cashReceivedUsd.present
          ? data.cashReceivedUsd.value
          : this.cashReceivedUsd,
      cashReceivedKhr: data.cashReceivedKhr.present
          ? data.cashReceivedKhr.value
          : this.cashReceivedKhr,
      totalUsd: data.totalUsd.present ? data.totalUsd.value : this.totalUsd,
      totalKhr: data.totalKhr.present ? data.totalKhr.value : this.totalKhr,
      linesJson: data.linesJson.present ? data.linesJson.value : this.linesJson,
      state: data.state.present ? data.state.value : this.state,
      sourceMode: data.sourceMode.present
          ? data.sourceMode.value
          : this.sourceMode,
      backendOrderId: data.backendOrderId.present
          ? data.backendOrderId.value
          : this.backendOrderId,
      materializedAt: data.materializedAt.present
          ? data.materializedAt.value
          : this.materializedAt,
      claimedPaymentMethod: data.claimedPaymentMethod.present
          ? data.claimedPaymentMethod.value
          : this.claimedPaymentMethod,
      claimedTenderAmount: data.claimedTenderAmount.present
          ? data.claimedTenderAmount.value
          : this.claimedTenderAmount,
      proofImageUrl: data.proofImageUrl.present
          ? data.proofImageUrl.value
          : this.proofImageUrl,
      customerReference: data.customerReference.present
          ? data.customerReference.value
          : this.customerReference,
      note: data.note.present ? data.note.value : this.note,
      claimRecordedAt: data.claimRecordedAt.present
          ? data.claimRecordedAt.value
          : this.claimRecordedAt,
      backendClaimId: data.backendClaimId.present
          ? data.backendClaimId.value
          : this.backendClaimId,
      claimSubmittedAt: data.claimSubmittedAt.present
          ? data.claimSubmittedAt.value
          : this.claimSubmittedAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      lastErrorMessage: data.lastErrorMessage.present
          ? data.lastErrorMessage.value
          : this.lastErrorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleOutageOrderEntry(')
          ..write('localIntentId: $localIntentId, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('saleType: $saleType, ')
          ..write('paymentMethodRequested: $paymentMethodRequested, ')
          ..write('tenderCurrency: $tenderCurrency, ')
          ..write('cashReceivedUsd: $cashReceivedUsd, ')
          ..write('cashReceivedKhr: $cashReceivedKhr, ')
          ..write('totalUsd: $totalUsd, ')
          ..write('totalKhr: $totalKhr, ')
          ..write('linesJson: $linesJson, ')
          ..write('state: $state, ')
          ..write('sourceMode: $sourceMode, ')
          ..write('backendOrderId: $backendOrderId, ')
          ..write('materializedAt: $materializedAt, ')
          ..write('claimedPaymentMethod: $claimedPaymentMethod, ')
          ..write('claimedTenderAmount: $claimedTenderAmount, ')
          ..write('proofImageUrl: $proofImageUrl, ')
          ..write('customerReference: $customerReference, ')
          ..write('note: $note, ')
          ..write('claimRecordedAt: $claimRecordedAt, ')
          ..write('backendClaimId: $backendClaimId, ')
          ..write('claimSubmittedAt: $claimSubmittedAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    localIntentId,
    orderNumber,
    tenantId,
    branchId,
    accountId,
    saleType,
    paymentMethodRequested,
    tenderCurrency,
    cashReceivedUsd,
    cashReceivedKhr,
    totalUsd,
    totalKhr,
    linesJson,
    state,
    sourceMode,
    backendOrderId,
    materializedAt,
    claimedPaymentMethod,
    claimedTenderAmount,
    proofImageUrl,
    customerReference,
    note,
    claimRecordedAt,
    backendClaimId,
    claimSubmittedAt,
    lastErrorCode,
    lastErrorMessage,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleOutageOrderEntry &&
          other.localIntentId == this.localIntentId &&
          other.orderNumber == this.orderNumber &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.accountId == this.accountId &&
          other.saleType == this.saleType &&
          other.paymentMethodRequested == this.paymentMethodRequested &&
          other.tenderCurrency == this.tenderCurrency &&
          other.cashReceivedUsd == this.cashReceivedUsd &&
          other.cashReceivedKhr == this.cashReceivedKhr &&
          other.totalUsd == this.totalUsd &&
          other.totalKhr == this.totalKhr &&
          other.linesJson == this.linesJson &&
          other.state == this.state &&
          other.sourceMode == this.sourceMode &&
          other.backendOrderId == this.backendOrderId &&
          other.materializedAt == this.materializedAt &&
          other.claimedPaymentMethod == this.claimedPaymentMethod &&
          other.claimedTenderAmount == this.claimedTenderAmount &&
          other.proofImageUrl == this.proofImageUrl &&
          other.customerReference == this.customerReference &&
          other.note == this.note &&
          other.claimRecordedAt == this.claimRecordedAt &&
          other.backendClaimId == this.backendClaimId &&
          other.claimSubmittedAt == this.claimSubmittedAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.lastErrorMessage == this.lastErrorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SaleOutageOrderEntriesCompanion
    extends UpdateCompanion<SaleOutageOrderEntry> {
  final Value<String> localIntentId;
  final Value<String> orderNumber;
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<String> accountId;
  final Value<String> saleType;
  final Value<String> paymentMethodRequested;
  final Value<String> tenderCurrency;
  final Value<double> cashReceivedUsd;
  final Value<double> cashReceivedKhr;
  final Value<double> totalUsd;
  final Value<double> totalKhr;
  final Value<String> linesJson;
  final Value<String> state;
  final Value<String> sourceMode;
  final Value<String?> backendOrderId;
  final Value<DateTime?> materializedAt;
  final Value<String?> claimedPaymentMethod;
  final Value<double?> claimedTenderAmount;
  final Value<String?> proofImageUrl;
  final Value<String?> customerReference;
  final Value<String?> note;
  final Value<DateTime?> claimRecordedAt;
  final Value<String?> backendClaimId;
  final Value<DateTime?> claimSubmittedAt;
  final Value<String?> lastErrorCode;
  final Value<String?> lastErrorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SaleOutageOrderEntriesCompanion({
    this.localIntentId = const Value.absent(),
    this.orderNumber = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.saleType = const Value.absent(),
    this.paymentMethodRequested = const Value.absent(),
    this.tenderCurrency = const Value.absent(),
    this.cashReceivedUsd = const Value.absent(),
    this.cashReceivedKhr = const Value.absent(),
    this.totalUsd = const Value.absent(),
    this.totalKhr = const Value.absent(),
    this.linesJson = const Value.absent(),
    this.state = const Value.absent(),
    this.sourceMode = const Value.absent(),
    this.backendOrderId = const Value.absent(),
    this.materializedAt = const Value.absent(),
    this.claimedPaymentMethod = const Value.absent(),
    this.claimedTenderAmount = const Value.absent(),
    this.proofImageUrl = const Value.absent(),
    this.customerReference = const Value.absent(),
    this.note = const Value.absent(),
    this.claimRecordedAt = const Value.absent(),
    this.backendClaimId = const Value.absent(),
    this.claimSubmittedAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleOutageOrderEntriesCompanion.insert({
    required String localIntentId,
    required String orderNumber,
    required String tenantId,
    required String branchId,
    required String accountId,
    required String saleType,
    required String paymentMethodRequested,
    required String tenderCurrency,
    this.cashReceivedUsd = const Value.absent(),
    this.cashReceivedKhr = const Value.absent(),
    required double totalUsd,
    required double totalKhr,
    required String linesJson,
    required String state,
    required String sourceMode,
    this.backendOrderId = const Value.absent(),
    this.materializedAt = const Value.absent(),
    this.claimedPaymentMethod = const Value.absent(),
    this.claimedTenderAmount = const Value.absent(),
    this.proofImageUrl = const Value.absent(),
    this.customerReference = const Value.absent(),
    this.note = const Value.absent(),
    this.claimRecordedAt = const Value.absent(),
    this.backendClaimId = const Value.absent(),
    this.claimSubmittedAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : localIntentId = Value(localIntentId),
       orderNumber = Value(orderNumber),
       tenantId = Value(tenantId),
       branchId = Value(branchId),
       accountId = Value(accountId),
       saleType = Value(saleType),
       paymentMethodRequested = Value(paymentMethodRequested),
       tenderCurrency = Value(tenderCurrency),
       totalUsd = Value(totalUsd),
       totalKhr = Value(totalKhr),
       linesJson = Value(linesJson),
       state = Value(state),
       sourceMode = Value(sourceMode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SaleOutageOrderEntry> custom({
    Expression<String>? localIntentId,
    Expression<String>? orderNumber,
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? accountId,
    Expression<String>? saleType,
    Expression<String>? paymentMethodRequested,
    Expression<String>? tenderCurrency,
    Expression<double>? cashReceivedUsd,
    Expression<double>? cashReceivedKhr,
    Expression<double>? totalUsd,
    Expression<double>? totalKhr,
    Expression<String>? linesJson,
    Expression<String>? state,
    Expression<String>? sourceMode,
    Expression<String>? backendOrderId,
    Expression<DateTime>? materializedAt,
    Expression<String>? claimedPaymentMethod,
    Expression<double>? claimedTenderAmount,
    Expression<String>? proofImageUrl,
    Expression<String>? customerReference,
    Expression<String>? note,
    Expression<DateTime>? claimRecordedAt,
    Expression<String>? backendClaimId,
    Expression<DateTime>? claimSubmittedAt,
    Expression<String>? lastErrorCode,
    Expression<String>? lastErrorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localIntentId != null) 'local_intent_id': localIntentId,
      if (orderNumber != null) 'order_number': orderNumber,
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (accountId != null) 'account_id': accountId,
      if (saleType != null) 'sale_type': saleType,
      if (paymentMethodRequested != null)
        'payment_method_requested': paymentMethodRequested,
      if (tenderCurrency != null) 'tender_currency': tenderCurrency,
      if (cashReceivedUsd != null) 'cash_received_usd': cashReceivedUsd,
      if (cashReceivedKhr != null) 'cash_received_khr': cashReceivedKhr,
      if (totalUsd != null) 'total_usd': totalUsd,
      if (totalKhr != null) 'total_khr': totalKhr,
      if (linesJson != null) 'lines_json': linesJson,
      if (state != null) 'state': state,
      if (sourceMode != null) 'source_mode': sourceMode,
      if (backendOrderId != null) 'backend_order_id': backendOrderId,
      if (materializedAt != null) 'materialized_at': materializedAt,
      if (claimedPaymentMethod != null)
        'claimed_payment_method': claimedPaymentMethod,
      if (claimedTenderAmount != null)
        'claimed_tender_amount': claimedTenderAmount,
      if (proofImageUrl != null) 'proof_image_url': proofImageUrl,
      if (customerReference != null) 'customer_reference': customerReference,
      if (note != null) 'note': note,
      if (claimRecordedAt != null) 'claim_recorded_at': claimRecordedAt,
      if (backendClaimId != null) 'backend_claim_id': backendClaimId,
      if (claimSubmittedAt != null) 'claim_submitted_at': claimSubmittedAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (lastErrorMessage != null) 'last_error_message': lastErrorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleOutageOrderEntriesCompanion copyWith({
    Value<String>? localIntentId,
    Value<String>? orderNumber,
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<String>? accountId,
    Value<String>? saleType,
    Value<String>? paymentMethodRequested,
    Value<String>? tenderCurrency,
    Value<double>? cashReceivedUsd,
    Value<double>? cashReceivedKhr,
    Value<double>? totalUsd,
    Value<double>? totalKhr,
    Value<String>? linesJson,
    Value<String>? state,
    Value<String>? sourceMode,
    Value<String?>? backendOrderId,
    Value<DateTime?>? materializedAt,
    Value<String?>? claimedPaymentMethod,
    Value<double?>? claimedTenderAmount,
    Value<String?>? proofImageUrl,
    Value<String?>? customerReference,
    Value<String?>? note,
    Value<DateTime?>? claimRecordedAt,
    Value<String?>? backendClaimId,
    Value<DateTime?>? claimSubmittedAt,
    Value<String?>? lastErrorCode,
    Value<String?>? lastErrorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SaleOutageOrderEntriesCompanion(
      localIntentId: localIntentId ?? this.localIntentId,
      orderNumber: orderNumber ?? this.orderNumber,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      accountId: accountId ?? this.accountId,
      saleType: saleType ?? this.saleType,
      paymentMethodRequested:
          paymentMethodRequested ?? this.paymentMethodRequested,
      tenderCurrency: tenderCurrency ?? this.tenderCurrency,
      cashReceivedUsd: cashReceivedUsd ?? this.cashReceivedUsd,
      cashReceivedKhr: cashReceivedKhr ?? this.cashReceivedKhr,
      totalUsd: totalUsd ?? this.totalUsd,
      totalKhr: totalKhr ?? this.totalKhr,
      linesJson: linesJson ?? this.linesJson,
      state: state ?? this.state,
      sourceMode: sourceMode ?? this.sourceMode,
      backendOrderId: backendOrderId ?? this.backendOrderId,
      materializedAt: materializedAt ?? this.materializedAt,
      claimedPaymentMethod: claimedPaymentMethod ?? this.claimedPaymentMethod,
      claimedTenderAmount: claimedTenderAmount ?? this.claimedTenderAmount,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      customerReference: customerReference ?? this.customerReference,
      note: note ?? this.note,
      claimRecordedAt: claimRecordedAt ?? this.claimRecordedAt,
      backendClaimId: backendClaimId ?? this.backendClaimId,
      claimSubmittedAt: claimSubmittedAt ?? this.claimSubmittedAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localIntentId.present) {
      map['local_intent_id'] = Variable<String>(localIntentId.value);
    }
    if (orderNumber.present) {
      map['order_number'] = Variable<String>(orderNumber.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (saleType.present) {
      map['sale_type'] = Variable<String>(saleType.value);
    }
    if (paymentMethodRequested.present) {
      map['payment_method_requested'] = Variable<String>(
        paymentMethodRequested.value,
      );
    }
    if (tenderCurrency.present) {
      map['tender_currency'] = Variable<String>(tenderCurrency.value);
    }
    if (cashReceivedUsd.present) {
      map['cash_received_usd'] = Variable<double>(cashReceivedUsd.value);
    }
    if (cashReceivedKhr.present) {
      map['cash_received_khr'] = Variable<double>(cashReceivedKhr.value);
    }
    if (totalUsd.present) {
      map['total_usd'] = Variable<double>(totalUsd.value);
    }
    if (totalKhr.present) {
      map['total_khr'] = Variable<double>(totalKhr.value);
    }
    if (linesJson.present) {
      map['lines_json'] = Variable<String>(linesJson.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (sourceMode.present) {
      map['source_mode'] = Variable<String>(sourceMode.value);
    }
    if (backendOrderId.present) {
      map['backend_order_id'] = Variable<String>(backendOrderId.value);
    }
    if (materializedAt.present) {
      map['materialized_at'] = Variable<DateTime>(materializedAt.value);
    }
    if (claimedPaymentMethod.present) {
      map['claimed_payment_method'] = Variable<String>(
        claimedPaymentMethod.value,
      );
    }
    if (claimedTenderAmount.present) {
      map['claimed_tender_amount'] = Variable<double>(
        claimedTenderAmount.value,
      );
    }
    if (proofImageUrl.present) {
      map['proof_image_url'] = Variable<String>(proofImageUrl.value);
    }
    if (customerReference.present) {
      map['customer_reference'] = Variable<String>(customerReference.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (claimRecordedAt.present) {
      map['claim_recorded_at'] = Variable<DateTime>(claimRecordedAt.value);
    }
    if (backendClaimId.present) {
      map['backend_claim_id'] = Variable<String>(backendClaimId.value);
    }
    if (claimSubmittedAt.present) {
      map['claim_submitted_at'] = Variable<DateTime>(claimSubmittedAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (lastErrorMessage.present) {
      map['last_error_message'] = Variable<String>(lastErrorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleOutageOrderEntriesCompanion(')
          ..write('localIntentId: $localIntentId, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('saleType: $saleType, ')
          ..write('paymentMethodRequested: $paymentMethodRequested, ')
          ..write('tenderCurrency: $tenderCurrency, ')
          ..write('cashReceivedUsd: $cashReceivedUsd, ')
          ..write('cashReceivedKhr: $cashReceivedKhr, ')
          ..write('totalUsd: $totalUsd, ')
          ..write('totalKhr: $totalKhr, ')
          ..write('linesJson: $linesJson, ')
          ..write('state: $state, ')
          ..write('sourceMode: $sourceMode, ')
          ..write('backendOrderId: $backendOrderId, ')
          ..write('materializedAt: $materializedAt, ')
          ..write('claimedPaymentMethod: $claimedPaymentMethod, ')
          ..write('claimedTenderAmount: $claimedTenderAmount, ')
          ..write('proofImageUrl: $proofImageUrl, ')
          ..write('customerReference: $customerReference, ')
          ..write('note: $note, ')
          ..write('claimRecordedAt: $claimRecordedAt, ')
          ..write('backendClaimId: $backendClaimId, ')
          ..write('claimSubmittedAt: $claimSubmittedAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorMessage: $lastErrorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PolicyCacheEntriesTable extends PolicyCacheEntries
    with TableInfo<$PolicyCacheEntriesTable, PolicyCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PolicyCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleVatEnabledMeta = const VerificationMeta(
    'saleVatEnabled',
  );
  @override
  late final GeneratedColumn<bool> saleVatEnabled = GeneratedColumn<bool>(
    'sale_vat_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sale_vat_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _saleVatRatePercentMeta =
      const VerificationMeta('saleVatRatePercent');
  @override
  late final GeneratedColumn<double> saleVatRatePercent =
      GeneratedColumn<double>(
        'sale_vat_rate_percent',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _saleFxRateKhrPerUsdMeta =
      const VerificationMeta('saleFxRateKhrPerUsd');
  @override
  late final GeneratedColumn<double> saleFxRateKhrPerUsd =
      GeneratedColumn<double>(
        'sale_fx_rate_khr_per_usd',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _saleKhrRoundingEnabledMeta =
      const VerificationMeta('saleKhrRoundingEnabled');
  @override
  late final GeneratedColumn<bool> saleKhrRoundingEnabled =
      GeneratedColumn<bool>(
        'sale_khr_rounding_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sale_khr_rounding_enabled" IN (0, 1))',
        ),
      );
  static const VerificationMeta _saleKhrRoundingModeMeta =
      const VerificationMeta('saleKhrRoundingMode');
  @override
  late final GeneratedColumn<String> saleKhrRoundingMode =
      GeneratedColumn<String>(
        'sale_khr_rounding_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _saleKhrRoundingGranularityMeta =
      const VerificationMeta('saleKhrRoundingGranularity');
  @override
  late final GeneratedColumn<String> saleKhrRoundingGranularity =
      GeneratedColumn<String>(
        'sale_khr_rounding_granularity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _saleAllowPayLaterMeta = const VerificationMeta(
    'saleAllowPayLater',
  );
  @override
  late final GeneratedColumn<bool> saleAllowPayLater = GeneratedColumn<bool>(
    'sale_allow_pay_later',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sale_allow_pay_later" IN (0, 1))',
    ),
  );
  static const VerificationMeta _saleAllowManualExternalPaymentClaimMeta =
      const VerificationMeta('saleAllowManualExternalPaymentClaim');
  @override
  late final GeneratedColumn<bool> saleAllowManualExternalPaymentClaim =
      GeneratedColumn<bool>(
        'sale_allow_manual_external_payment_claim',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("sale_allow_manual_external_payment_claim" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncCursorAppliedMeta = const VerificationMeta(
    'syncCursorApplied',
  );
  @override
  late final GeneratedColumn<String> syncCursorApplied =
      GeneratedColumn<String>(
        'sync_cursor_applied',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta(
    'lastPullAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPullAt = GeneratedColumn<DateTime>(
    'last_pull_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    branchId,
    saleVatEnabled,
    saleVatRatePercent,
    saleFxRateKhrPerUsd,
    saleKhrRoundingEnabled,
    saleKhrRoundingMode,
    saleKhrRoundingGranularity,
    saleAllowPayLater,
    saleAllowManualExternalPaymentClaim,
    createdAt,
    updatedAt,
    cachedAt,
    syncCursorApplied,
    lastPullAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'policy_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PolicyCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('sale_vat_enabled')) {
      context.handle(
        _saleVatEnabledMeta,
        saleVatEnabled.isAcceptableOrUnknown(
          data['sale_vat_enabled']!,
          _saleVatEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saleVatEnabledMeta);
    }
    if (data.containsKey('sale_vat_rate_percent')) {
      context.handle(
        _saleVatRatePercentMeta,
        saleVatRatePercent.isAcceptableOrUnknown(
          data['sale_vat_rate_percent']!,
          _saleVatRatePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saleVatRatePercentMeta);
    }
    if (data.containsKey('sale_fx_rate_khr_per_usd')) {
      context.handle(
        _saleFxRateKhrPerUsdMeta,
        saleFxRateKhrPerUsd.isAcceptableOrUnknown(
          data['sale_fx_rate_khr_per_usd']!,
          _saleFxRateKhrPerUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saleFxRateKhrPerUsdMeta);
    }
    if (data.containsKey('sale_khr_rounding_enabled')) {
      context.handle(
        _saleKhrRoundingEnabledMeta,
        saleKhrRoundingEnabled.isAcceptableOrUnknown(
          data['sale_khr_rounding_enabled']!,
          _saleKhrRoundingEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saleKhrRoundingEnabledMeta);
    }
    if (data.containsKey('sale_khr_rounding_mode')) {
      context.handle(
        _saleKhrRoundingModeMeta,
        saleKhrRoundingMode.isAcceptableOrUnknown(
          data['sale_khr_rounding_mode']!,
          _saleKhrRoundingModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saleKhrRoundingModeMeta);
    }
    if (data.containsKey('sale_khr_rounding_granularity')) {
      context.handle(
        _saleKhrRoundingGranularityMeta,
        saleKhrRoundingGranularity.isAcceptableOrUnknown(
          data['sale_khr_rounding_granularity']!,
          _saleKhrRoundingGranularityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saleKhrRoundingGranularityMeta);
    }
    if (data.containsKey('sale_allow_pay_later')) {
      context.handle(
        _saleAllowPayLaterMeta,
        saleAllowPayLater.isAcceptableOrUnknown(
          data['sale_allow_pay_later']!,
          _saleAllowPayLaterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saleAllowPayLaterMeta);
    }
    if (data.containsKey('sale_allow_manual_external_payment_claim')) {
      context.handle(
        _saleAllowManualExternalPaymentClaimMeta,
        saleAllowManualExternalPaymentClaim.isAcceptableOrUnknown(
          data['sale_allow_manual_external_payment_claim']!,
          _saleAllowManualExternalPaymentClaimMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('sync_cursor_applied')) {
      context.handle(
        _syncCursorAppliedMeta,
        syncCursorApplied.isAcceptableOrUnknown(
          data['sync_cursor_applied']!,
          _syncCursorAppliedMeta,
        ),
      );
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(
        _lastPullAtMeta,
        lastPullAt.isAcceptableOrUnknown(
          data['last_pull_at']!,
          _lastPullAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, branchId};
  @override
  PolicyCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PolicyCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      saleVatEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sale_vat_enabled'],
      )!,
      saleVatRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sale_vat_rate_percent'],
      )!,
      saleFxRateKhrPerUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sale_fx_rate_khr_per_usd'],
      )!,
      saleKhrRoundingEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sale_khr_rounding_enabled'],
      )!,
      saleKhrRoundingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_khr_rounding_mode'],
      )!,
      saleKhrRoundingGranularity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_khr_rounding_granularity'],
      )!,
      saleAllowPayLater: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sale_allow_pay_later'],
      )!,
      saleAllowManualExternalPaymentClaim: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sale_allow_manual_external_payment_claim'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      syncCursorApplied: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_cursor_applied'],
      ),
      lastPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pull_at'],
      ),
    );
  }

  @override
  $PolicyCacheEntriesTable createAlias(String alias) {
    return $PolicyCacheEntriesTable(attachedDatabase, alias);
  }
}

class PolicyCacheEntry extends DataClass
    implements Insertable<PolicyCacheEntry> {
  final String tenantId;
  final String branchId;
  final bool saleVatEnabled;
  final double saleVatRatePercent;
  final double saleFxRateKhrPerUsd;
  final bool saleKhrRoundingEnabled;
  final String saleKhrRoundingMode;
  final String saleKhrRoundingGranularity;
  final bool saleAllowPayLater;
  final bool saleAllowManualExternalPaymentClaim;
  final String createdAt;
  final String updatedAt;
  final DateTime cachedAt;
  final String? syncCursorApplied;
  final DateTime? lastPullAt;
  const PolicyCacheEntry({
    required this.tenantId,
    required this.branchId,
    required this.saleVatEnabled,
    required this.saleVatRatePercent,
    required this.saleFxRateKhrPerUsd,
    required this.saleKhrRoundingEnabled,
    required this.saleKhrRoundingMode,
    required this.saleKhrRoundingGranularity,
    required this.saleAllowPayLater,
    required this.saleAllowManualExternalPaymentClaim,
    required this.createdAt,
    required this.updatedAt,
    required this.cachedAt,
    this.syncCursorApplied,
    this.lastPullAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['sale_vat_enabled'] = Variable<bool>(saleVatEnabled);
    map['sale_vat_rate_percent'] = Variable<double>(saleVatRatePercent);
    map['sale_fx_rate_khr_per_usd'] = Variable<double>(saleFxRateKhrPerUsd);
    map['sale_khr_rounding_enabled'] = Variable<bool>(saleKhrRoundingEnabled);
    map['sale_khr_rounding_mode'] = Variable<String>(saleKhrRoundingMode);
    map['sale_khr_rounding_granularity'] = Variable<String>(
      saleKhrRoundingGranularity,
    );
    map['sale_allow_pay_later'] = Variable<bool>(saleAllowPayLater);
    map['sale_allow_manual_external_payment_claim'] = Variable<bool>(
      saleAllowManualExternalPaymentClaim,
    );
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    if (!nullToAbsent || syncCursorApplied != null) {
      map['sync_cursor_applied'] = Variable<String>(syncCursorApplied);
    }
    if (!nullToAbsent || lastPullAt != null) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt);
    }
    return map;
  }

  PolicyCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return PolicyCacheEntriesCompanion(
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      saleVatEnabled: Value(saleVatEnabled),
      saleVatRatePercent: Value(saleVatRatePercent),
      saleFxRateKhrPerUsd: Value(saleFxRateKhrPerUsd),
      saleKhrRoundingEnabled: Value(saleKhrRoundingEnabled),
      saleKhrRoundingMode: Value(saleKhrRoundingMode),
      saleKhrRoundingGranularity: Value(saleKhrRoundingGranularity),
      saleAllowPayLater: Value(saleAllowPayLater),
      saleAllowManualExternalPaymentClaim: Value(
        saleAllowManualExternalPaymentClaim,
      ),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      cachedAt: Value(cachedAt),
      syncCursorApplied: syncCursorApplied == null && nullToAbsent
          ? const Value.absent()
          : Value(syncCursorApplied),
      lastPullAt: lastPullAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPullAt),
    );
  }

  factory PolicyCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PolicyCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      saleVatEnabled: serializer.fromJson<bool>(json['saleVatEnabled']),
      saleVatRatePercent: serializer.fromJson<double>(
        json['saleVatRatePercent'],
      ),
      saleFxRateKhrPerUsd: serializer.fromJson<double>(
        json['saleFxRateKhrPerUsd'],
      ),
      saleKhrRoundingEnabled: serializer.fromJson<bool>(
        json['saleKhrRoundingEnabled'],
      ),
      saleKhrRoundingMode: serializer.fromJson<String>(
        json['saleKhrRoundingMode'],
      ),
      saleKhrRoundingGranularity: serializer.fromJson<String>(
        json['saleKhrRoundingGranularity'],
      ),
      saleAllowPayLater: serializer.fromJson<bool>(json['saleAllowPayLater']),
      saleAllowManualExternalPaymentClaim: serializer.fromJson<bool>(
        json['saleAllowManualExternalPaymentClaim'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      syncCursorApplied: serializer.fromJson<String?>(
        json['syncCursorApplied'],
      ),
      lastPullAt: serializer.fromJson<DateTime?>(json['lastPullAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'saleVatEnabled': serializer.toJson<bool>(saleVatEnabled),
      'saleVatRatePercent': serializer.toJson<double>(saleVatRatePercent),
      'saleFxRateKhrPerUsd': serializer.toJson<double>(saleFxRateKhrPerUsd),
      'saleKhrRoundingEnabled': serializer.toJson<bool>(saleKhrRoundingEnabled),
      'saleKhrRoundingMode': serializer.toJson<String>(saleKhrRoundingMode),
      'saleKhrRoundingGranularity': serializer.toJson<String>(
        saleKhrRoundingGranularity,
      ),
      'saleAllowPayLater': serializer.toJson<bool>(saleAllowPayLater),
      'saleAllowManualExternalPaymentClaim': serializer.toJson<bool>(
        saleAllowManualExternalPaymentClaim,
      ),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'syncCursorApplied': serializer.toJson<String?>(syncCursorApplied),
      'lastPullAt': serializer.toJson<DateTime?>(lastPullAt),
    };
  }

  PolicyCacheEntry copyWith({
    String? tenantId,
    String? branchId,
    bool? saleVatEnabled,
    double? saleVatRatePercent,
    double? saleFxRateKhrPerUsd,
    bool? saleKhrRoundingEnabled,
    String? saleKhrRoundingMode,
    String? saleKhrRoundingGranularity,
    bool? saleAllowPayLater,
    bool? saleAllowManualExternalPaymentClaim,
    String? createdAt,
    String? updatedAt,
    DateTime? cachedAt,
    Value<String?> syncCursorApplied = const Value.absent(),
    Value<DateTime?> lastPullAt = const Value.absent(),
  }) => PolicyCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    saleVatEnabled: saleVatEnabled ?? this.saleVatEnabled,
    saleVatRatePercent: saleVatRatePercent ?? this.saleVatRatePercent,
    saleFxRateKhrPerUsd: saleFxRateKhrPerUsd ?? this.saleFxRateKhrPerUsd,
    saleKhrRoundingEnabled:
        saleKhrRoundingEnabled ?? this.saleKhrRoundingEnabled,
    saleKhrRoundingMode: saleKhrRoundingMode ?? this.saleKhrRoundingMode,
    saleKhrRoundingGranularity:
        saleKhrRoundingGranularity ?? this.saleKhrRoundingGranularity,
    saleAllowPayLater: saleAllowPayLater ?? this.saleAllowPayLater,
    saleAllowManualExternalPaymentClaim:
        saleAllowManualExternalPaymentClaim ??
        this.saleAllowManualExternalPaymentClaim,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
    syncCursorApplied: syncCursorApplied.present
        ? syncCursorApplied.value
        : this.syncCursorApplied,
    lastPullAt: lastPullAt.present ? lastPullAt.value : this.lastPullAt,
  );
  PolicyCacheEntry copyWithCompanion(PolicyCacheEntriesCompanion data) {
    return PolicyCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      saleVatEnabled: data.saleVatEnabled.present
          ? data.saleVatEnabled.value
          : this.saleVatEnabled,
      saleVatRatePercent: data.saleVatRatePercent.present
          ? data.saleVatRatePercent.value
          : this.saleVatRatePercent,
      saleFxRateKhrPerUsd: data.saleFxRateKhrPerUsd.present
          ? data.saleFxRateKhrPerUsd.value
          : this.saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled: data.saleKhrRoundingEnabled.present
          ? data.saleKhrRoundingEnabled.value
          : this.saleKhrRoundingEnabled,
      saleKhrRoundingMode: data.saleKhrRoundingMode.present
          ? data.saleKhrRoundingMode.value
          : this.saleKhrRoundingMode,
      saleKhrRoundingGranularity: data.saleKhrRoundingGranularity.present
          ? data.saleKhrRoundingGranularity.value
          : this.saleKhrRoundingGranularity,
      saleAllowPayLater: data.saleAllowPayLater.present
          ? data.saleAllowPayLater.value
          : this.saleAllowPayLater,
      saleAllowManualExternalPaymentClaim:
          data.saleAllowManualExternalPaymentClaim.present
          ? data.saleAllowManualExternalPaymentClaim.value
          : this.saleAllowManualExternalPaymentClaim,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      syncCursorApplied: data.syncCursorApplied.present
          ? data.syncCursorApplied.value
          : this.syncCursorApplied,
      lastPullAt: data.lastPullAt.present
          ? data.lastPullAt.value
          : this.lastPullAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PolicyCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('saleVatEnabled: $saleVatEnabled, ')
          ..write('saleVatRatePercent: $saleVatRatePercent, ')
          ..write('saleFxRateKhrPerUsd: $saleFxRateKhrPerUsd, ')
          ..write('saleKhrRoundingEnabled: $saleKhrRoundingEnabled, ')
          ..write('saleKhrRoundingMode: $saleKhrRoundingMode, ')
          ..write('saleKhrRoundingGranularity: $saleKhrRoundingGranularity, ')
          ..write('saleAllowPayLater: $saleAllowPayLater, ')
          ..write(
            'saleAllowManualExternalPaymentClaim: $saleAllowManualExternalPaymentClaim, ',
          )
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('syncCursorApplied: $syncCursorApplied, ')
          ..write('lastPullAt: $lastPullAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    branchId,
    saleVatEnabled,
    saleVatRatePercent,
    saleFxRateKhrPerUsd,
    saleKhrRoundingEnabled,
    saleKhrRoundingMode,
    saleKhrRoundingGranularity,
    saleAllowPayLater,
    saleAllowManualExternalPaymentClaim,
    createdAt,
    updatedAt,
    cachedAt,
    syncCursorApplied,
    lastPullAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PolicyCacheEntry &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.saleVatEnabled == this.saleVatEnabled &&
          other.saleVatRatePercent == this.saleVatRatePercent &&
          other.saleFxRateKhrPerUsd == this.saleFxRateKhrPerUsd &&
          other.saleKhrRoundingEnabled == this.saleKhrRoundingEnabled &&
          other.saleKhrRoundingMode == this.saleKhrRoundingMode &&
          other.saleKhrRoundingGranularity == this.saleKhrRoundingGranularity &&
          other.saleAllowPayLater == this.saleAllowPayLater &&
          other.saleAllowManualExternalPaymentClaim ==
              this.saleAllowManualExternalPaymentClaim &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt &&
          other.syncCursorApplied == this.syncCursorApplied &&
          other.lastPullAt == this.lastPullAt);
}

class PolicyCacheEntriesCompanion extends UpdateCompanion<PolicyCacheEntry> {
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<bool> saleVatEnabled;
  final Value<double> saleVatRatePercent;
  final Value<double> saleFxRateKhrPerUsd;
  final Value<bool> saleKhrRoundingEnabled;
  final Value<String> saleKhrRoundingMode;
  final Value<String> saleKhrRoundingGranularity;
  final Value<bool> saleAllowPayLater;
  final Value<bool> saleAllowManualExternalPaymentClaim;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime> cachedAt;
  final Value<String?> syncCursorApplied;
  final Value<DateTime?> lastPullAt;
  final Value<int> rowid;
  const PolicyCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.saleVatEnabled = const Value.absent(),
    this.saleVatRatePercent = const Value.absent(),
    this.saleFxRateKhrPerUsd = const Value.absent(),
    this.saleKhrRoundingEnabled = const Value.absent(),
    this.saleKhrRoundingMode = const Value.absent(),
    this.saleKhrRoundingGranularity = const Value.absent(),
    this.saleAllowPayLater = const Value.absent(),
    this.saleAllowManualExternalPaymentClaim = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.syncCursorApplied = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PolicyCacheEntriesCompanion.insert({
    required String tenantId,
    required String branchId,
    required bool saleVatEnabled,
    required double saleVatRatePercent,
    required double saleFxRateKhrPerUsd,
    required bool saleKhrRoundingEnabled,
    required String saleKhrRoundingMode,
    required String saleKhrRoundingGranularity,
    required bool saleAllowPayLater,
    this.saleAllowManualExternalPaymentClaim = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    required DateTime cachedAt,
    this.syncCursorApplied = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       branchId = Value(branchId),
       saleVatEnabled = Value(saleVatEnabled),
       saleVatRatePercent = Value(saleVatRatePercent),
       saleFxRateKhrPerUsd = Value(saleFxRateKhrPerUsd),
       saleKhrRoundingEnabled = Value(saleKhrRoundingEnabled),
       saleKhrRoundingMode = Value(saleKhrRoundingMode),
       saleKhrRoundingGranularity = Value(saleKhrRoundingGranularity),
       saleAllowPayLater = Value(saleAllowPayLater),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<PolicyCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<bool>? saleVatEnabled,
    Expression<double>? saleVatRatePercent,
    Expression<double>? saleFxRateKhrPerUsd,
    Expression<bool>? saleKhrRoundingEnabled,
    Expression<String>? saleKhrRoundingMode,
    Expression<String>? saleKhrRoundingGranularity,
    Expression<bool>? saleAllowPayLater,
    Expression<bool>? saleAllowManualExternalPaymentClaim,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? cachedAt,
    Expression<String>? syncCursorApplied,
    Expression<DateTime>? lastPullAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (saleVatEnabled != null) 'sale_vat_enabled': saleVatEnabled,
      if (saleVatRatePercent != null)
        'sale_vat_rate_percent': saleVatRatePercent,
      if (saleFxRateKhrPerUsd != null)
        'sale_fx_rate_khr_per_usd': saleFxRateKhrPerUsd,
      if (saleKhrRoundingEnabled != null)
        'sale_khr_rounding_enabled': saleKhrRoundingEnabled,
      if (saleKhrRoundingMode != null)
        'sale_khr_rounding_mode': saleKhrRoundingMode,
      if (saleKhrRoundingGranularity != null)
        'sale_khr_rounding_granularity': saleKhrRoundingGranularity,
      if (saleAllowPayLater != null) 'sale_allow_pay_later': saleAllowPayLater,
      if (saleAllowManualExternalPaymentClaim != null)
        'sale_allow_manual_external_payment_claim':
            saleAllowManualExternalPaymentClaim,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (syncCursorApplied != null) 'sync_cursor_applied': syncCursorApplied,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PolicyCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<bool>? saleVatEnabled,
    Value<double>? saleVatRatePercent,
    Value<double>? saleFxRateKhrPerUsd,
    Value<bool>? saleKhrRoundingEnabled,
    Value<String>? saleKhrRoundingMode,
    Value<String>? saleKhrRoundingGranularity,
    Value<bool>? saleAllowPayLater,
    Value<bool>? saleAllowManualExternalPaymentClaim,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime>? cachedAt,
    Value<String?>? syncCursorApplied,
    Value<DateTime?>? lastPullAt,
    Value<int>? rowid,
  }) {
    return PolicyCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      saleVatEnabled: saleVatEnabled ?? this.saleVatEnabled,
      saleVatRatePercent: saleVatRatePercent ?? this.saleVatRatePercent,
      saleFxRateKhrPerUsd: saleFxRateKhrPerUsd ?? this.saleFxRateKhrPerUsd,
      saleKhrRoundingEnabled:
          saleKhrRoundingEnabled ?? this.saleKhrRoundingEnabled,
      saleKhrRoundingMode: saleKhrRoundingMode ?? this.saleKhrRoundingMode,
      saleKhrRoundingGranularity:
          saleKhrRoundingGranularity ?? this.saleKhrRoundingGranularity,
      saleAllowPayLater: saleAllowPayLater ?? this.saleAllowPayLater,
      saleAllowManualExternalPaymentClaim:
          saleAllowManualExternalPaymentClaim ??
          this.saleAllowManualExternalPaymentClaim,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      syncCursorApplied: syncCursorApplied ?? this.syncCursorApplied,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (saleVatEnabled.present) {
      map['sale_vat_enabled'] = Variable<bool>(saleVatEnabled.value);
    }
    if (saleVatRatePercent.present) {
      map['sale_vat_rate_percent'] = Variable<double>(saleVatRatePercent.value);
    }
    if (saleFxRateKhrPerUsd.present) {
      map['sale_fx_rate_khr_per_usd'] = Variable<double>(
        saleFxRateKhrPerUsd.value,
      );
    }
    if (saleKhrRoundingEnabled.present) {
      map['sale_khr_rounding_enabled'] = Variable<bool>(
        saleKhrRoundingEnabled.value,
      );
    }
    if (saleKhrRoundingMode.present) {
      map['sale_khr_rounding_mode'] = Variable<String>(
        saleKhrRoundingMode.value,
      );
    }
    if (saleKhrRoundingGranularity.present) {
      map['sale_khr_rounding_granularity'] = Variable<String>(
        saleKhrRoundingGranularity.value,
      );
    }
    if (saleAllowPayLater.present) {
      map['sale_allow_pay_later'] = Variable<bool>(saleAllowPayLater.value);
    }
    if (saleAllowManualExternalPaymentClaim.present) {
      map['sale_allow_manual_external_payment_claim'] = Variable<bool>(
        saleAllowManualExternalPaymentClaim.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (syncCursorApplied.present) {
      map['sync_cursor_applied'] = Variable<String>(syncCursorApplied.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PolicyCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('saleVatEnabled: $saleVatEnabled, ')
          ..write('saleVatRatePercent: $saleVatRatePercent, ')
          ..write('saleFxRateKhrPerUsd: $saleFxRateKhrPerUsd, ')
          ..write('saleKhrRoundingEnabled: $saleKhrRoundingEnabled, ')
          ..write('saleKhrRoundingMode: $saleKhrRoundingMode, ')
          ..write('saleKhrRoundingGranularity: $saleKhrRoundingGranularity, ')
          ..write('saleAllowPayLater: $saleAllowPayLater, ')
          ..write(
            'saleAllowManualExternalPaymentClaim: $saleAllowManualExternalPaymentClaim, ',
          )
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('syncCursorApplied: $syncCursorApplied, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashSessionSnapshotEntriesTable extends CashSessionSnapshotEntries
    with TableInfo<$CashSessionSnapshotEntriesTable, CashSessionSnapshotEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashSessionSnapshotEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedByAccountIdMeta = const VerificationMeta(
    'openedByAccountId',
  );
  @override
  late final GeneratedColumn<String> openedByAccountId =
      GeneratedColumn<String>(
        'opened_by_account_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _openedByNameMeta = const VerificationMeta(
    'openedByName',
  );
  @override
  late final GeneratedColumn<String> openedByName = GeneratedColumn<String>(
    'opened_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingFloatUsdMeta = const VerificationMeta(
    'openingFloatUsd',
  );
  @override
  late final GeneratedColumn<double> openingFloatUsd = GeneratedColumn<double>(
    'opening_float_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingFloatKhrMeta = const VerificationMeta(
    'openingFloatKhr',
  );
  @override
  late final GeneratedColumn<double> openingFloatKhr = GeneratedColumn<double>(
    'opening_float_khr',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedByAccountIdMeta = const VerificationMeta(
    'closedByAccountId',
  );
  @override
  late final GeneratedColumn<String> closedByAccountId =
      GeneratedColumn<String>(
        'closed_by_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _closedByNameMeta = const VerificationMeta(
    'closedByName',
  );
  @override
  late final GeneratedColumn<String> closedByName = GeneratedColumn<String>(
    'closed_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closeNoteMeta = const VerificationMeta(
    'closeNote',
  );
  @override
  late final GeneratedColumn<String> closeNote = GeneratedColumn<String>(
    'close_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPaidInUsdMeta = const VerificationMeta(
    'totalPaidInUsd',
  );
  @override
  late final GeneratedColumn<double> totalPaidInUsd = GeneratedColumn<double>(
    'total_paid_in_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPaidOutUsdMeta = const VerificationMeta(
    'totalPaidOutUsd',
  );
  @override
  late final GeneratedColumn<double> totalPaidOutUsd = GeneratedColumn<double>(
    'total_paid_out_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    branchId,
    sessionId,
    openedByAccountId,
    openedByName,
    openedAt,
    status,
    openingFloatUsd,
    openingFloatKhr,
    closedAt,
    closedByAccountId,
    closedByName,
    closeNote,
    totalPaidInUsd,
    totalPaidOutUsd,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_session_snapshot_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashSessionSnapshotEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('opened_by_account_id')) {
      context.handle(
        _openedByAccountIdMeta,
        openedByAccountId.isAcceptableOrUnknown(
          data['opened_by_account_id']!,
          _openedByAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openedByAccountIdMeta);
    }
    if (data.containsKey('opened_by_name')) {
      context.handle(
        _openedByNameMeta,
        openedByName.isAcceptableOrUnknown(
          data['opened_by_name']!,
          _openedByNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openedByNameMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('opening_float_usd')) {
      context.handle(
        _openingFloatUsdMeta,
        openingFloatUsd.isAcceptableOrUnknown(
          data['opening_float_usd']!,
          _openingFloatUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingFloatUsdMeta);
    }
    if (data.containsKey('opening_float_khr')) {
      context.handle(
        _openingFloatKhrMeta,
        openingFloatKhr.isAcceptableOrUnknown(
          data['opening_float_khr']!,
          _openingFloatKhrMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingFloatKhrMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('closed_by_account_id')) {
      context.handle(
        _closedByAccountIdMeta,
        closedByAccountId.isAcceptableOrUnknown(
          data['closed_by_account_id']!,
          _closedByAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('closed_by_name')) {
      context.handle(
        _closedByNameMeta,
        closedByName.isAcceptableOrUnknown(
          data['closed_by_name']!,
          _closedByNameMeta,
        ),
      );
    }
    if (data.containsKey('close_note')) {
      context.handle(
        _closeNoteMeta,
        closeNote.isAcceptableOrUnknown(data['close_note']!, _closeNoteMeta),
      );
    }
    if (data.containsKey('total_paid_in_usd')) {
      context.handle(
        _totalPaidInUsdMeta,
        totalPaidInUsd.isAcceptableOrUnknown(
          data['total_paid_in_usd']!,
          _totalPaidInUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPaidInUsdMeta);
    }
    if (data.containsKey('total_paid_out_usd')) {
      context.handle(
        _totalPaidOutUsdMeta,
        totalPaidOutUsd.isAcceptableOrUnknown(
          data['total_paid_out_usd']!,
          _totalPaidOutUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPaidOutUsdMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, branchId};
  @override
  CashSessionSnapshotEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashSessionSnapshotEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      openedByAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_by_account_id'],
      )!,
      openedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_by_name'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      openingFloatUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opening_float_usd'],
      )!,
      openingFloatKhr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opening_float_khr'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      closedByAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by_account_id'],
      ),
      closedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by_name'],
      ),
      closeNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}close_note'],
      ),
      totalPaidInUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_paid_in_usd'],
      )!,
      totalPaidOutUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_paid_out_usd'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CashSessionSnapshotEntriesTable createAlias(String alias) {
    return $CashSessionSnapshotEntriesTable(attachedDatabase, alias);
  }
}

class CashSessionSnapshotEntry extends DataClass
    implements Insertable<CashSessionSnapshotEntry> {
  final String tenantId;
  final String branchId;
  final String sessionId;
  final String openedByAccountId;
  final String openedByName;
  final DateTime? openedAt;
  final String status;
  final double openingFloatUsd;
  final double openingFloatKhr;
  final DateTime? closedAt;
  final String? closedByAccountId;
  final String? closedByName;
  final String? closeNote;
  final double totalPaidInUsd;
  final double totalPaidOutUsd;
  final DateTime cachedAt;
  const CashSessionSnapshotEntry({
    required this.tenantId,
    required this.branchId,
    required this.sessionId,
    required this.openedByAccountId,
    required this.openedByName,
    this.openedAt,
    required this.status,
    required this.openingFloatUsd,
    required this.openingFloatKhr,
    this.closedAt,
    this.closedByAccountId,
    this.closedByName,
    this.closeNote,
    required this.totalPaidInUsd,
    required this.totalPaidOutUsd,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['session_id'] = Variable<String>(sessionId);
    map['opened_by_account_id'] = Variable<String>(openedByAccountId);
    map['opened_by_name'] = Variable<String>(openedByName);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    map['status'] = Variable<String>(status);
    map['opening_float_usd'] = Variable<double>(openingFloatUsd);
    map['opening_float_khr'] = Variable<double>(openingFloatKhr);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || closedByAccountId != null) {
      map['closed_by_account_id'] = Variable<String>(closedByAccountId);
    }
    if (!nullToAbsent || closedByName != null) {
      map['closed_by_name'] = Variable<String>(closedByName);
    }
    if (!nullToAbsent || closeNote != null) {
      map['close_note'] = Variable<String>(closeNote);
    }
    map['total_paid_in_usd'] = Variable<double>(totalPaidInUsd);
    map['total_paid_out_usd'] = Variable<double>(totalPaidOutUsd);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CashSessionSnapshotEntriesCompanion toCompanion(bool nullToAbsent) {
    return CashSessionSnapshotEntriesCompanion(
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      sessionId: Value(sessionId),
      openedByAccountId: Value(openedByAccountId),
      openedByName: Value(openedByName),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      status: Value(status),
      openingFloatUsd: Value(openingFloatUsd),
      openingFloatKhr: Value(openingFloatKhr),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      closedByAccountId: closedByAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(closedByAccountId),
      closedByName: closedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(closedByName),
      closeNote: closeNote == null && nullToAbsent
          ? const Value.absent()
          : Value(closeNote),
      totalPaidInUsd: Value(totalPaidInUsd),
      totalPaidOutUsd: Value(totalPaidOutUsd),
      cachedAt: Value(cachedAt),
    );
  }

  factory CashSessionSnapshotEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashSessionSnapshotEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      openedByAccountId: serializer.fromJson<String>(json['openedByAccountId']),
      openedByName: serializer.fromJson<String>(json['openedByName']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      status: serializer.fromJson<String>(json['status']),
      openingFloatUsd: serializer.fromJson<double>(json['openingFloatUsd']),
      openingFloatKhr: serializer.fromJson<double>(json['openingFloatKhr']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      closedByAccountId: serializer.fromJson<String?>(
        json['closedByAccountId'],
      ),
      closedByName: serializer.fromJson<String?>(json['closedByName']),
      closeNote: serializer.fromJson<String?>(json['closeNote']),
      totalPaidInUsd: serializer.fromJson<double>(json['totalPaidInUsd']),
      totalPaidOutUsd: serializer.fromJson<double>(json['totalPaidOutUsd']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'sessionId': serializer.toJson<String>(sessionId),
      'openedByAccountId': serializer.toJson<String>(openedByAccountId),
      'openedByName': serializer.toJson<String>(openedByName),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'status': serializer.toJson<String>(status),
      'openingFloatUsd': serializer.toJson<double>(openingFloatUsd),
      'openingFloatKhr': serializer.toJson<double>(openingFloatKhr),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'closedByAccountId': serializer.toJson<String?>(closedByAccountId),
      'closedByName': serializer.toJson<String?>(closedByName),
      'closeNote': serializer.toJson<String?>(closeNote),
      'totalPaidInUsd': serializer.toJson<double>(totalPaidInUsd),
      'totalPaidOutUsd': serializer.toJson<double>(totalPaidOutUsd),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CashSessionSnapshotEntry copyWith({
    String? tenantId,
    String? branchId,
    String? sessionId,
    String? openedByAccountId,
    String? openedByName,
    Value<DateTime?> openedAt = const Value.absent(),
    String? status,
    double? openingFloatUsd,
    double? openingFloatKhr,
    Value<DateTime?> closedAt = const Value.absent(),
    Value<String?> closedByAccountId = const Value.absent(),
    Value<String?> closedByName = const Value.absent(),
    Value<String?> closeNote = const Value.absent(),
    double? totalPaidInUsd,
    double? totalPaidOutUsd,
    DateTime? cachedAt,
  }) => CashSessionSnapshotEntry(
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    sessionId: sessionId ?? this.sessionId,
    openedByAccountId: openedByAccountId ?? this.openedByAccountId,
    openedByName: openedByName ?? this.openedByName,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    status: status ?? this.status,
    openingFloatUsd: openingFloatUsd ?? this.openingFloatUsd,
    openingFloatKhr: openingFloatKhr ?? this.openingFloatKhr,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    closedByAccountId: closedByAccountId.present
        ? closedByAccountId.value
        : this.closedByAccountId,
    closedByName: closedByName.present ? closedByName.value : this.closedByName,
    closeNote: closeNote.present ? closeNote.value : this.closeNote,
    totalPaidInUsd: totalPaidInUsd ?? this.totalPaidInUsd,
    totalPaidOutUsd: totalPaidOutUsd ?? this.totalPaidOutUsd,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CashSessionSnapshotEntry copyWithCompanion(
    CashSessionSnapshotEntriesCompanion data,
  ) {
    return CashSessionSnapshotEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      openedByAccountId: data.openedByAccountId.present
          ? data.openedByAccountId.value
          : this.openedByAccountId,
      openedByName: data.openedByName.present
          ? data.openedByName.value
          : this.openedByName,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      status: data.status.present ? data.status.value : this.status,
      openingFloatUsd: data.openingFloatUsd.present
          ? data.openingFloatUsd.value
          : this.openingFloatUsd,
      openingFloatKhr: data.openingFloatKhr.present
          ? data.openingFloatKhr.value
          : this.openingFloatKhr,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      closedByAccountId: data.closedByAccountId.present
          ? data.closedByAccountId.value
          : this.closedByAccountId,
      closedByName: data.closedByName.present
          ? data.closedByName.value
          : this.closedByName,
      closeNote: data.closeNote.present ? data.closeNote.value : this.closeNote,
      totalPaidInUsd: data.totalPaidInUsd.present
          ? data.totalPaidInUsd.value
          : this.totalPaidInUsd,
      totalPaidOutUsd: data.totalPaidOutUsd.present
          ? data.totalPaidOutUsd.value
          : this.totalPaidOutUsd,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashSessionSnapshotEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('sessionId: $sessionId, ')
          ..write('openedByAccountId: $openedByAccountId, ')
          ..write('openedByName: $openedByName, ')
          ..write('openedAt: $openedAt, ')
          ..write('status: $status, ')
          ..write('openingFloatUsd: $openingFloatUsd, ')
          ..write('openingFloatKhr: $openingFloatKhr, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedByAccountId: $closedByAccountId, ')
          ..write('closedByName: $closedByName, ')
          ..write('closeNote: $closeNote, ')
          ..write('totalPaidInUsd: $totalPaidInUsd, ')
          ..write('totalPaidOutUsd: $totalPaidOutUsd, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    branchId,
    sessionId,
    openedByAccountId,
    openedByName,
    openedAt,
    status,
    openingFloatUsd,
    openingFloatKhr,
    closedAt,
    closedByAccountId,
    closedByName,
    closeNote,
    totalPaidInUsd,
    totalPaidOutUsd,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashSessionSnapshotEntry &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.sessionId == this.sessionId &&
          other.openedByAccountId == this.openedByAccountId &&
          other.openedByName == this.openedByName &&
          other.openedAt == this.openedAt &&
          other.status == this.status &&
          other.openingFloatUsd == this.openingFloatUsd &&
          other.openingFloatKhr == this.openingFloatKhr &&
          other.closedAt == this.closedAt &&
          other.closedByAccountId == this.closedByAccountId &&
          other.closedByName == this.closedByName &&
          other.closeNote == this.closeNote &&
          other.totalPaidInUsd == this.totalPaidInUsd &&
          other.totalPaidOutUsd == this.totalPaidOutUsd &&
          other.cachedAt == this.cachedAt);
}

class CashSessionSnapshotEntriesCompanion
    extends UpdateCompanion<CashSessionSnapshotEntry> {
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<String> sessionId;
  final Value<String> openedByAccountId;
  final Value<String> openedByName;
  final Value<DateTime?> openedAt;
  final Value<String> status;
  final Value<double> openingFloatUsd;
  final Value<double> openingFloatKhr;
  final Value<DateTime?> closedAt;
  final Value<String?> closedByAccountId;
  final Value<String?> closedByName;
  final Value<String?> closeNote;
  final Value<double> totalPaidInUsd;
  final Value<double> totalPaidOutUsd;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CashSessionSnapshotEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.openedByAccountId = const Value.absent(),
    this.openedByName = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.openingFloatUsd = const Value.absent(),
    this.openingFloatKhr = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.closedByAccountId = const Value.absent(),
    this.closedByName = const Value.absent(),
    this.closeNote = const Value.absent(),
    this.totalPaidInUsd = const Value.absent(),
    this.totalPaidOutUsd = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashSessionSnapshotEntriesCompanion.insert({
    required String tenantId,
    required String branchId,
    required String sessionId,
    required String openedByAccountId,
    required String openedByName,
    this.openedAt = const Value.absent(),
    required String status,
    required double openingFloatUsd,
    required double openingFloatKhr,
    this.closedAt = const Value.absent(),
    this.closedByAccountId = const Value.absent(),
    this.closedByName = const Value.absent(),
    this.closeNote = const Value.absent(),
    required double totalPaidInUsd,
    required double totalPaidOutUsd,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       branchId = Value(branchId),
       sessionId = Value(sessionId),
       openedByAccountId = Value(openedByAccountId),
       openedByName = Value(openedByName),
       status = Value(status),
       openingFloatUsd = Value(openingFloatUsd),
       openingFloatKhr = Value(openingFloatKhr),
       totalPaidInUsd = Value(totalPaidInUsd),
       totalPaidOutUsd = Value(totalPaidOutUsd),
       cachedAt = Value(cachedAt);
  static Insertable<CashSessionSnapshotEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? sessionId,
    Expression<String>? openedByAccountId,
    Expression<String>? openedByName,
    Expression<DateTime>? openedAt,
    Expression<String>? status,
    Expression<double>? openingFloatUsd,
    Expression<double>? openingFloatKhr,
    Expression<DateTime>? closedAt,
    Expression<String>? closedByAccountId,
    Expression<String>? closedByName,
    Expression<String>? closeNote,
    Expression<double>? totalPaidInUsd,
    Expression<double>? totalPaidOutUsd,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (sessionId != null) 'session_id': sessionId,
      if (openedByAccountId != null) 'opened_by_account_id': openedByAccountId,
      if (openedByName != null) 'opened_by_name': openedByName,
      if (openedAt != null) 'opened_at': openedAt,
      if (status != null) 'status': status,
      if (openingFloatUsd != null) 'opening_float_usd': openingFloatUsd,
      if (openingFloatKhr != null) 'opening_float_khr': openingFloatKhr,
      if (closedAt != null) 'closed_at': closedAt,
      if (closedByAccountId != null) 'closed_by_account_id': closedByAccountId,
      if (closedByName != null) 'closed_by_name': closedByName,
      if (closeNote != null) 'close_note': closeNote,
      if (totalPaidInUsd != null) 'total_paid_in_usd': totalPaidInUsd,
      if (totalPaidOutUsd != null) 'total_paid_out_usd': totalPaidOutUsd,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashSessionSnapshotEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<String>? sessionId,
    Value<String>? openedByAccountId,
    Value<String>? openedByName,
    Value<DateTime?>? openedAt,
    Value<String>? status,
    Value<double>? openingFloatUsd,
    Value<double>? openingFloatKhr,
    Value<DateTime?>? closedAt,
    Value<String?>? closedByAccountId,
    Value<String?>? closedByName,
    Value<String?>? closeNote,
    Value<double>? totalPaidInUsd,
    Value<double>? totalPaidOutUsd,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CashSessionSnapshotEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      sessionId: sessionId ?? this.sessionId,
      openedByAccountId: openedByAccountId ?? this.openedByAccountId,
      openedByName: openedByName ?? this.openedByName,
      openedAt: openedAt ?? this.openedAt,
      status: status ?? this.status,
      openingFloatUsd: openingFloatUsd ?? this.openingFloatUsd,
      openingFloatKhr: openingFloatKhr ?? this.openingFloatKhr,
      closedAt: closedAt ?? this.closedAt,
      closedByAccountId: closedByAccountId ?? this.closedByAccountId,
      closedByName: closedByName ?? this.closedByName,
      closeNote: closeNote ?? this.closeNote,
      totalPaidInUsd: totalPaidInUsd ?? this.totalPaidInUsd,
      totalPaidOutUsd: totalPaidOutUsd ?? this.totalPaidOutUsd,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (openedByAccountId.present) {
      map['opened_by_account_id'] = Variable<String>(openedByAccountId.value);
    }
    if (openedByName.present) {
      map['opened_by_name'] = Variable<String>(openedByName.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openingFloatUsd.present) {
      map['opening_float_usd'] = Variable<double>(openingFloatUsd.value);
    }
    if (openingFloatKhr.present) {
      map['opening_float_khr'] = Variable<double>(openingFloatKhr.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (closedByAccountId.present) {
      map['closed_by_account_id'] = Variable<String>(closedByAccountId.value);
    }
    if (closedByName.present) {
      map['closed_by_name'] = Variable<String>(closedByName.value);
    }
    if (closeNote.present) {
      map['close_note'] = Variable<String>(closeNote.value);
    }
    if (totalPaidInUsd.present) {
      map['total_paid_in_usd'] = Variable<double>(totalPaidInUsd.value);
    }
    if (totalPaidOutUsd.present) {
      map['total_paid_out_usd'] = Variable<double>(totalPaidOutUsd.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashSessionSnapshotEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('sessionId: $sessionId, ')
          ..write('openedByAccountId: $openedByAccountId, ')
          ..write('openedByName: $openedByName, ')
          ..write('openedAt: $openedAt, ')
          ..write('status: $status, ')
          ..write('openingFloatUsd: $openingFloatUsd, ')
          ..write('openingFloatKhr: $openingFloatKhr, ')
          ..write('closedAt: $closedAt, ')
          ..write('closedByAccountId: $closedByAccountId, ')
          ..write('closedByName: $closedByName, ')
          ..write('closeNote: $closeNote, ')
          ..write('totalPaidInUsd: $totalPaidInUsd, ')
          ..write('totalPaidOutUsd: $totalPaidOutUsd, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashSessionMovementCacheEntriesTable
    extends CashSessionMovementCacheEntries
    with
        TableInfo<
          $CashSessionMovementCacheEntriesTable,
          CashSessionMovementCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashSessionMovementCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementIdMeta = const VerificationMeta(
    'movementId',
  );
  @override
  late final GeneratedColumn<String> movementId = GeneratedColumn<String>(
    'movement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountUsdMeta = const VerificationMeta(
    'amountUsd',
  );
  @override
  late final GeneratedColumn<double> amountUsd = GeneratedColumn<double>(
    'amount_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountKhrMeta = const VerificationMeta(
    'amountKhr',
  );
  @override
  late final GeneratedColumn<double> amountKhr = GeneratedColumn<double>(
    'amount_khr',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRefTypeMeta = const VerificationMeta(
    'sourceRefType',
  );
  @override
  late final GeneratedColumn<String> sourceRefType = GeneratedColumn<String>(
    'source_ref_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRefIdMeta = const VerificationMeta(
    'sourceRefId',
  );
  @override
  late final GeneratedColumn<String> sourceRefId = GeneratedColumn<String>(
    'source_ref_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedByAccountIdMeta =
      const VerificationMeta('recordedByAccountId');
  @override
  late final GeneratedColumn<String> recordedByAccountId =
      GeneratedColumn<String>(
        'recorded_by_account_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    branchId,
    sessionId,
    movementId,
    movementType,
    amountUsd,
    amountKhr,
    reason,
    sourceRefType,
    sourceRefId,
    recordedByAccountId,
    occurredAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_session_movement_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashSessionMovementCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('movement_id')) {
      context.handle(
        _movementIdMeta,
        movementId.isAcceptableOrUnknown(data['movement_id']!, _movementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_movementIdMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('amount_usd')) {
      context.handle(
        _amountUsdMeta,
        amountUsd.isAcceptableOrUnknown(data['amount_usd']!, _amountUsdMeta),
      );
    } else if (isInserting) {
      context.missing(_amountUsdMeta);
    }
    if (data.containsKey('amount_khr')) {
      context.handle(
        _amountKhrMeta,
        amountKhr.isAcceptableOrUnknown(data['amount_khr']!, _amountKhrMeta),
      );
    } else if (isInserting) {
      context.missing(_amountKhrMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('source_ref_type')) {
      context.handle(
        _sourceRefTypeMeta,
        sourceRefType.isAcceptableOrUnknown(
          data['source_ref_type']!,
          _sourceRefTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceRefTypeMeta);
    }
    if (data.containsKey('source_ref_id')) {
      context.handle(
        _sourceRefIdMeta,
        sourceRefId.isAcceptableOrUnknown(
          data['source_ref_id']!,
          _sourceRefIdMeta,
        ),
      );
    }
    if (data.containsKey('recorded_by_account_id')) {
      context.handle(
        _recordedByAccountIdMeta,
        recordedByAccountId.isAcceptableOrUnknown(
          data['recorded_by_account_id']!,
          _recordedByAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedByAccountIdMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    tenantId,
    branchId,
    sessionId,
    movementId,
  };
  @override
  CashSessionMovementCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashSessionMovementCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      movementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_id'],
      )!,
      movementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_type'],
      )!,
      amountUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_usd'],
      )!,
      amountKhr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_khr'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      sourceRefType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref_type'],
      )!,
      sourceRefId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref_id'],
      ),
      recordedByAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_account_id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CashSessionMovementCacheEntriesTable createAlias(String alias) {
    return $CashSessionMovementCacheEntriesTable(attachedDatabase, alias);
  }
}

class CashSessionMovementCacheEntry extends DataClass
    implements Insertable<CashSessionMovementCacheEntry> {
  final String tenantId;
  final String branchId;
  final String sessionId;
  final String movementId;
  final String movementType;
  final double amountUsd;
  final double amountKhr;
  final String? reason;
  final String sourceRefType;
  final String? sourceRefId;
  final String recordedByAccountId;
  final DateTime? occurredAt;
  final int sortOrder;
  const CashSessionMovementCacheEntry({
    required this.tenantId,
    required this.branchId,
    required this.sessionId,
    required this.movementId,
    required this.movementType,
    required this.amountUsd,
    required this.amountKhr,
    this.reason,
    required this.sourceRefType,
    this.sourceRefId,
    required this.recordedByAccountId,
    this.occurredAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['session_id'] = Variable<String>(sessionId);
    map['movement_id'] = Variable<String>(movementId);
    map['movement_type'] = Variable<String>(movementType);
    map['amount_usd'] = Variable<double>(amountUsd);
    map['amount_khr'] = Variable<double>(amountKhr);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['source_ref_type'] = Variable<String>(sourceRefType);
    if (!nullToAbsent || sourceRefId != null) {
      map['source_ref_id'] = Variable<String>(sourceRefId);
    }
    map['recorded_by_account_id'] = Variable<String>(recordedByAccountId);
    if (!nullToAbsent || occurredAt != null) {
      map['occurred_at'] = Variable<DateTime>(occurredAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CashSessionMovementCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CashSessionMovementCacheEntriesCompanion(
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      sessionId: Value(sessionId),
      movementId: Value(movementId),
      movementType: Value(movementType),
      amountUsd: Value(amountUsd),
      amountKhr: Value(amountKhr),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      sourceRefType: Value(sourceRefType),
      sourceRefId: sourceRefId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRefId),
      recordedByAccountId: Value(recordedByAccountId),
      occurredAt: occurredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(occurredAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory CashSessionMovementCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashSessionMovementCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      movementId: serializer.fromJson<String>(json['movementId']),
      movementType: serializer.fromJson<String>(json['movementType']),
      amountUsd: serializer.fromJson<double>(json['amountUsd']),
      amountKhr: serializer.fromJson<double>(json['amountKhr']),
      reason: serializer.fromJson<String?>(json['reason']),
      sourceRefType: serializer.fromJson<String>(json['sourceRefType']),
      sourceRefId: serializer.fromJson<String?>(json['sourceRefId']),
      recordedByAccountId: serializer.fromJson<String>(
        json['recordedByAccountId'],
      ),
      occurredAt: serializer.fromJson<DateTime?>(json['occurredAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'sessionId': serializer.toJson<String>(sessionId),
      'movementId': serializer.toJson<String>(movementId),
      'movementType': serializer.toJson<String>(movementType),
      'amountUsd': serializer.toJson<double>(amountUsd),
      'amountKhr': serializer.toJson<double>(amountKhr),
      'reason': serializer.toJson<String?>(reason),
      'sourceRefType': serializer.toJson<String>(sourceRefType),
      'sourceRefId': serializer.toJson<String?>(sourceRefId),
      'recordedByAccountId': serializer.toJson<String>(recordedByAccountId),
      'occurredAt': serializer.toJson<DateTime?>(occurredAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CashSessionMovementCacheEntry copyWith({
    String? tenantId,
    String? branchId,
    String? sessionId,
    String? movementId,
    String? movementType,
    double? amountUsd,
    double? amountKhr,
    Value<String?> reason = const Value.absent(),
    String? sourceRefType,
    Value<String?> sourceRefId = const Value.absent(),
    String? recordedByAccountId,
    Value<DateTime?> occurredAt = const Value.absent(),
    int? sortOrder,
  }) => CashSessionMovementCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    sessionId: sessionId ?? this.sessionId,
    movementId: movementId ?? this.movementId,
    movementType: movementType ?? this.movementType,
    amountUsd: amountUsd ?? this.amountUsd,
    amountKhr: amountKhr ?? this.amountKhr,
    reason: reason.present ? reason.value : this.reason,
    sourceRefType: sourceRefType ?? this.sourceRefType,
    sourceRefId: sourceRefId.present ? sourceRefId.value : this.sourceRefId,
    recordedByAccountId: recordedByAccountId ?? this.recordedByAccountId,
    occurredAt: occurredAt.present ? occurredAt.value : this.occurredAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CashSessionMovementCacheEntry copyWithCompanion(
    CashSessionMovementCacheEntriesCompanion data,
  ) {
    return CashSessionMovementCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      movementId: data.movementId.present
          ? data.movementId.value
          : this.movementId,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      amountUsd: data.amountUsd.present ? data.amountUsd.value : this.amountUsd,
      amountKhr: data.amountKhr.present ? data.amountKhr.value : this.amountKhr,
      reason: data.reason.present ? data.reason.value : this.reason,
      sourceRefType: data.sourceRefType.present
          ? data.sourceRefType.value
          : this.sourceRefType,
      sourceRefId: data.sourceRefId.present
          ? data.sourceRefId.value
          : this.sourceRefId,
      recordedByAccountId: data.recordedByAccountId.present
          ? data.recordedByAccountId.value
          : this.recordedByAccountId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashSessionMovementCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('sessionId: $sessionId, ')
          ..write('movementId: $movementId, ')
          ..write('movementType: $movementType, ')
          ..write('amountUsd: $amountUsd, ')
          ..write('amountKhr: $amountKhr, ')
          ..write('reason: $reason, ')
          ..write('sourceRefType: $sourceRefType, ')
          ..write('sourceRefId: $sourceRefId, ')
          ..write('recordedByAccountId: $recordedByAccountId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    branchId,
    sessionId,
    movementId,
    movementType,
    amountUsd,
    amountKhr,
    reason,
    sourceRefType,
    sourceRefId,
    recordedByAccountId,
    occurredAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashSessionMovementCacheEntry &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.sessionId == this.sessionId &&
          other.movementId == this.movementId &&
          other.movementType == this.movementType &&
          other.amountUsd == this.amountUsd &&
          other.amountKhr == this.amountKhr &&
          other.reason == this.reason &&
          other.sourceRefType == this.sourceRefType &&
          other.sourceRefId == this.sourceRefId &&
          other.recordedByAccountId == this.recordedByAccountId &&
          other.occurredAt == this.occurredAt &&
          other.sortOrder == this.sortOrder);
}

class CashSessionMovementCacheEntriesCompanion
    extends UpdateCompanion<CashSessionMovementCacheEntry> {
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<String> sessionId;
  final Value<String> movementId;
  final Value<String> movementType;
  final Value<double> amountUsd;
  final Value<double> amountKhr;
  final Value<String?> reason;
  final Value<String> sourceRefType;
  final Value<String?> sourceRefId;
  final Value<String> recordedByAccountId;
  final Value<DateTime?> occurredAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CashSessionMovementCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.movementId = const Value.absent(),
    this.movementType = const Value.absent(),
    this.amountUsd = const Value.absent(),
    this.amountKhr = const Value.absent(),
    this.reason = const Value.absent(),
    this.sourceRefType = const Value.absent(),
    this.sourceRefId = const Value.absent(),
    this.recordedByAccountId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashSessionMovementCacheEntriesCompanion.insert({
    required String tenantId,
    required String branchId,
    required String sessionId,
    required String movementId,
    required String movementType,
    required double amountUsd,
    required double amountKhr,
    this.reason = const Value.absent(),
    required String sourceRefType,
    this.sourceRefId = const Value.absent(),
    required String recordedByAccountId,
    this.occurredAt = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       branchId = Value(branchId),
       sessionId = Value(sessionId),
       movementId = Value(movementId),
       movementType = Value(movementType),
       amountUsd = Value(amountUsd),
       amountKhr = Value(amountKhr),
       sourceRefType = Value(sourceRefType),
       recordedByAccountId = Value(recordedByAccountId),
       sortOrder = Value(sortOrder);
  static Insertable<CashSessionMovementCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? sessionId,
    Expression<String>? movementId,
    Expression<String>? movementType,
    Expression<double>? amountUsd,
    Expression<double>? amountKhr,
    Expression<String>? reason,
    Expression<String>? sourceRefType,
    Expression<String>? sourceRefId,
    Expression<String>? recordedByAccountId,
    Expression<DateTime>? occurredAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (sessionId != null) 'session_id': sessionId,
      if (movementId != null) 'movement_id': movementId,
      if (movementType != null) 'movement_type': movementType,
      if (amountUsd != null) 'amount_usd': amountUsd,
      if (amountKhr != null) 'amount_khr': amountKhr,
      if (reason != null) 'reason': reason,
      if (sourceRefType != null) 'source_ref_type': sourceRefType,
      if (sourceRefId != null) 'source_ref_id': sourceRefId,
      if (recordedByAccountId != null)
        'recorded_by_account_id': recordedByAccountId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashSessionMovementCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<String>? sessionId,
    Value<String>? movementId,
    Value<String>? movementType,
    Value<double>? amountUsd,
    Value<double>? amountKhr,
    Value<String?>? reason,
    Value<String>? sourceRefType,
    Value<String?>? sourceRefId,
    Value<String>? recordedByAccountId,
    Value<DateTime?>? occurredAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CashSessionMovementCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      sessionId: sessionId ?? this.sessionId,
      movementId: movementId ?? this.movementId,
      movementType: movementType ?? this.movementType,
      amountUsd: amountUsd ?? this.amountUsd,
      amountKhr: amountKhr ?? this.amountKhr,
      reason: reason ?? this.reason,
      sourceRefType: sourceRefType ?? this.sourceRefType,
      sourceRefId: sourceRefId ?? this.sourceRefId,
      recordedByAccountId: recordedByAccountId ?? this.recordedByAccountId,
      occurredAt: occurredAt ?? this.occurredAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (movementId.present) {
      map['movement_id'] = Variable<String>(movementId.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (amountUsd.present) {
      map['amount_usd'] = Variable<double>(amountUsd.value);
    }
    if (amountKhr.present) {
      map['amount_khr'] = Variable<double>(amountKhr.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (sourceRefType.present) {
      map['source_ref_type'] = Variable<String>(sourceRefType.value);
    }
    if (sourceRefId.present) {
      map['source_ref_id'] = Variable<String>(sourceRefId.value);
    }
    if (recordedByAccountId.present) {
      map['recorded_by_account_id'] = Variable<String>(
        recordedByAccountId.value,
      );
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashSessionMovementCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('sessionId: $sessionId, ')
          ..write('movementId: $movementId, ')
          ..write('movementType: $movementType, ')
          ..write('amountUsd: $amountUsd, ')
          ..write('amountKhr: $amountKhr, ')
          ..write('reason: $reason, ')
          ..write('sourceRefType: $sourceRefType, ')
          ..write('sourceRefId: $sourceRefId, ')
          ..write('recordedByAccountId: $recordedByAccountId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashSessionSaleCacheEntriesTable extends CashSessionSaleCacheEntries
    with
        TableInfo<
          $CashSessionSaleCacheEntriesTable,
          CashSessionSaleCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashSessionSaleCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleTypeMeta = const VerificationMeta(
    'saleType',
  );
  @override
  late final GeneratedColumn<String> saleType = GeneratedColumn<String>(
    'sale_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finalizedAtMeta = const VerificationMeta(
    'finalizedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finalizedAt = GeneratedColumn<DateTime>(
    'finalized_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalItemsMeta = const VerificationMeta(
    'totalItems',
  );
  @override
  late final GeneratedColumn<int> totalItems = GeneratedColumn<int>(
    'total_items',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grandTotalUsdMeta = const VerificationMeta(
    'grandTotalUsd',
  );
  @override
  late final GeneratedColumn<double> grandTotalUsd = GeneratedColumn<double>(
    'grand_total_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grandTotalKhrMeta = const VerificationMeta(
    'grandTotalKhr',
  );
  @override
  late final GeneratedColumn<double> grandTotalKhr = GeneratedColumn<double>(
    'grand_total_khr',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierAccountIdMeta = const VerificationMeta(
    'cashierAccountId',
  );
  @override
  late final GeneratedColumn<String> cashierAccountId = GeneratedColumn<String>(
    'cashier_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashierNameMeta = const VerificationMeta(
    'cashierName',
  );
  @override
  late final GeneratedColumn<String> cashierName = GeneratedColumn<String>(
    'cashier_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voidedAtMeta = const VerificationMeta(
    'voidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> voidedAt = GeneratedColumn<DateTime>(
    'voided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    branchId,
    sessionId,
    saleId,
    status,
    paymentMethod,
    saleType,
    finalizedAt,
    totalItems,
    grandTotalUsd,
    grandTotalKhr,
    cashierAccountId,
    cashierName,
    voidedAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_session_sale_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashSessionSaleCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('sale_type')) {
      context.handle(
        _saleTypeMeta,
        saleType.isAcceptableOrUnknown(data['sale_type']!, _saleTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_saleTypeMeta);
    }
    if (data.containsKey('finalized_at')) {
      context.handle(
        _finalizedAtMeta,
        finalizedAt.isAcceptableOrUnknown(
          data['finalized_at']!,
          _finalizedAtMeta,
        ),
      );
    }
    if (data.containsKey('total_items')) {
      context.handle(
        _totalItemsMeta,
        totalItems.isAcceptableOrUnknown(data['total_items']!, _totalItemsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalItemsMeta);
    }
    if (data.containsKey('grand_total_usd')) {
      context.handle(
        _grandTotalUsdMeta,
        grandTotalUsd.isAcceptableOrUnknown(
          data['grand_total_usd']!,
          _grandTotalUsdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grandTotalUsdMeta);
    }
    if (data.containsKey('grand_total_khr')) {
      context.handle(
        _grandTotalKhrMeta,
        grandTotalKhr.isAcceptableOrUnknown(
          data['grand_total_khr']!,
          _grandTotalKhrMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grandTotalKhrMeta);
    }
    if (data.containsKey('cashier_account_id')) {
      context.handle(
        _cashierAccountIdMeta,
        cashierAccountId.isAcceptableOrUnknown(
          data['cashier_account_id']!,
          _cashierAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashierAccountIdMeta);
    }
    if (data.containsKey('cashier_name')) {
      context.handle(
        _cashierNameMeta,
        cashierName.isAcceptableOrUnknown(
          data['cashier_name']!,
          _cashierNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashierNameMeta);
    }
    if (data.containsKey('voided_at')) {
      context.handle(
        _voidedAtMeta,
        voidedAt.isAcceptableOrUnknown(data['voided_at']!, _voidedAtMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    tenantId,
    branchId,
    sessionId,
    saleId,
  };
  @override
  CashSessionSaleCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashSessionSaleCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      saleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_type'],
      )!,
      finalizedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finalized_at'],
      ),
      totalItems: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_items'],
      )!,
      grandTotalUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grand_total_usd'],
      )!,
      grandTotalKhr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grand_total_khr'],
      )!,
      cashierAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_account_id'],
      )!,
      cashierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_name'],
      )!,
      voidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}voided_at'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CashSessionSaleCacheEntriesTable createAlias(String alias) {
    return $CashSessionSaleCacheEntriesTable(attachedDatabase, alias);
  }
}

class CashSessionSaleCacheEntry extends DataClass
    implements Insertable<CashSessionSaleCacheEntry> {
  final String tenantId;
  final String branchId;
  final String sessionId;
  final String saleId;
  final String status;
  final String paymentMethod;
  final String saleType;
  final DateTime? finalizedAt;
  final int totalItems;
  final double grandTotalUsd;
  final double grandTotalKhr;
  final String cashierAccountId;
  final String cashierName;
  final DateTime? voidedAt;
  final int sortOrder;
  const CashSessionSaleCacheEntry({
    required this.tenantId,
    required this.branchId,
    required this.sessionId,
    required this.saleId,
    required this.status,
    required this.paymentMethod,
    required this.saleType,
    this.finalizedAt,
    required this.totalItems,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
    required this.cashierAccountId,
    required this.cashierName,
    this.voidedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['session_id'] = Variable<String>(sessionId);
    map['sale_id'] = Variable<String>(saleId);
    map['status'] = Variable<String>(status);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['sale_type'] = Variable<String>(saleType);
    if (!nullToAbsent || finalizedAt != null) {
      map['finalized_at'] = Variable<DateTime>(finalizedAt);
    }
    map['total_items'] = Variable<int>(totalItems);
    map['grand_total_usd'] = Variable<double>(grandTotalUsd);
    map['grand_total_khr'] = Variable<double>(grandTotalKhr);
    map['cashier_account_id'] = Variable<String>(cashierAccountId);
    map['cashier_name'] = Variable<String>(cashierName);
    if (!nullToAbsent || voidedAt != null) {
      map['voided_at'] = Variable<DateTime>(voidedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CashSessionSaleCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CashSessionSaleCacheEntriesCompanion(
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      sessionId: Value(sessionId),
      saleId: Value(saleId),
      status: Value(status),
      paymentMethod: Value(paymentMethod),
      saleType: Value(saleType),
      finalizedAt: finalizedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finalizedAt),
      totalItems: Value(totalItems),
      grandTotalUsd: Value(grandTotalUsd),
      grandTotalKhr: Value(grandTotalKhr),
      cashierAccountId: Value(cashierAccountId),
      cashierName: Value(cashierName),
      voidedAt: voidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(voidedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory CashSessionSaleCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashSessionSaleCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      saleId: serializer.fromJson<String>(json['saleId']),
      status: serializer.fromJson<String>(json['status']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      saleType: serializer.fromJson<String>(json['saleType']),
      finalizedAt: serializer.fromJson<DateTime?>(json['finalizedAt']),
      totalItems: serializer.fromJson<int>(json['totalItems']),
      grandTotalUsd: serializer.fromJson<double>(json['grandTotalUsd']),
      grandTotalKhr: serializer.fromJson<double>(json['grandTotalKhr']),
      cashierAccountId: serializer.fromJson<String>(json['cashierAccountId']),
      cashierName: serializer.fromJson<String>(json['cashierName']),
      voidedAt: serializer.fromJson<DateTime?>(json['voidedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'sessionId': serializer.toJson<String>(sessionId),
      'saleId': serializer.toJson<String>(saleId),
      'status': serializer.toJson<String>(status),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'saleType': serializer.toJson<String>(saleType),
      'finalizedAt': serializer.toJson<DateTime?>(finalizedAt),
      'totalItems': serializer.toJson<int>(totalItems),
      'grandTotalUsd': serializer.toJson<double>(grandTotalUsd),
      'grandTotalKhr': serializer.toJson<double>(grandTotalKhr),
      'cashierAccountId': serializer.toJson<String>(cashierAccountId),
      'cashierName': serializer.toJson<String>(cashierName),
      'voidedAt': serializer.toJson<DateTime?>(voidedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CashSessionSaleCacheEntry copyWith({
    String? tenantId,
    String? branchId,
    String? sessionId,
    String? saleId,
    String? status,
    String? paymentMethod,
    String? saleType,
    Value<DateTime?> finalizedAt = const Value.absent(),
    int? totalItems,
    double? grandTotalUsd,
    double? grandTotalKhr,
    String? cashierAccountId,
    String? cashierName,
    Value<DateTime?> voidedAt = const Value.absent(),
    int? sortOrder,
  }) => CashSessionSaleCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    sessionId: sessionId ?? this.sessionId,
    saleId: saleId ?? this.saleId,
    status: status ?? this.status,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    saleType: saleType ?? this.saleType,
    finalizedAt: finalizedAt.present ? finalizedAt.value : this.finalizedAt,
    totalItems: totalItems ?? this.totalItems,
    grandTotalUsd: grandTotalUsd ?? this.grandTotalUsd,
    grandTotalKhr: grandTotalKhr ?? this.grandTotalKhr,
    cashierAccountId: cashierAccountId ?? this.cashierAccountId,
    cashierName: cashierName ?? this.cashierName,
    voidedAt: voidedAt.present ? voidedAt.value : this.voidedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CashSessionSaleCacheEntry copyWithCompanion(
    CashSessionSaleCacheEntriesCompanion data,
  ) {
    return CashSessionSaleCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      status: data.status.present ? data.status.value : this.status,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      saleType: data.saleType.present ? data.saleType.value : this.saleType,
      finalizedAt: data.finalizedAt.present
          ? data.finalizedAt.value
          : this.finalizedAt,
      totalItems: data.totalItems.present
          ? data.totalItems.value
          : this.totalItems,
      grandTotalUsd: data.grandTotalUsd.present
          ? data.grandTotalUsd.value
          : this.grandTotalUsd,
      grandTotalKhr: data.grandTotalKhr.present
          ? data.grandTotalKhr.value
          : this.grandTotalKhr,
      cashierAccountId: data.cashierAccountId.present
          ? data.cashierAccountId.value
          : this.cashierAccountId,
      cashierName: data.cashierName.present
          ? data.cashierName.value
          : this.cashierName,
      voidedAt: data.voidedAt.present ? data.voidedAt.value : this.voidedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashSessionSaleCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('sessionId: $sessionId, ')
          ..write('saleId: $saleId, ')
          ..write('status: $status, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('saleType: $saleType, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('totalItems: $totalItems, ')
          ..write('grandTotalUsd: $grandTotalUsd, ')
          ..write('grandTotalKhr: $grandTotalKhr, ')
          ..write('cashierAccountId: $cashierAccountId, ')
          ..write('cashierName: $cashierName, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    branchId,
    sessionId,
    saleId,
    status,
    paymentMethod,
    saleType,
    finalizedAt,
    totalItems,
    grandTotalUsd,
    grandTotalKhr,
    cashierAccountId,
    cashierName,
    voidedAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashSessionSaleCacheEntry &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.sessionId == this.sessionId &&
          other.saleId == this.saleId &&
          other.status == this.status &&
          other.paymentMethod == this.paymentMethod &&
          other.saleType == this.saleType &&
          other.finalizedAt == this.finalizedAt &&
          other.totalItems == this.totalItems &&
          other.grandTotalUsd == this.grandTotalUsd &&
          other.grandTotalKhr == this.grandTotalKhr &&
          other.cashierAccountId == this.cashierAccountId &&
          other.cashierName == this.cashierName &&
          other.voidedAt == this.voidedAt &&
          other.sortOrder == this.sortOrder);
}

class CashSessionSaleCacheEntriesCompanion
    extends UpdateCompanion<CashSessionSaleCacheEntry> {
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<String> sessionId;
  final Value<String> saleId;
  final Value<String> status;
  final Value<String> paymentMethod;
  final Value<String> saleType;
  final Value<DateTime?> finalizedAt;
  final Value<int> totalItems;
  final Value<double> grandTotalUsd;
  final Value<double> grandTotalKhr;
  final Value<String> cashierAccountId;
  final Value<String> cashierName;
  final Value<DateTime?> voidedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CashSessionSaleCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.saleId = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.saleType = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    this.totalItems = const Value.absent(),
    this.grandTotalUsd = const Value.absent(),
    this.grandTotalKhr = const Value.absent(),
    this.cashierAccountId = const Value.absent(),
    this.cashierName = const Value.absent(),
    this.voidedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashSessionSaleCacheEntriesCompanion.insert({
    required String tenantId,
    required String branchId,
    required String sessionId,
    required String saleId,
    required String status,
    required String paymentMethod,
    required String saleType,
    this.finalizedAt = const Value.absent(),
    required int totalItems,
    required double grandTotalUsd,
    required double grandTotalKhr,
    required String cashierAccountId,
    required String cashierName,
    this.voidedAt = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       branchId = Value(branchId),
       sessionId = Value(sessionId),
       saleId = Value(saleId),
       status = Value(status),
       paymentMethod = Value(paymentMethod),
       saleType = Value(saleType),
       totalItems = Value(totalItems),
       grandTotalUsd = Value(grandTotalUsd),
       grandTotalKhr = Value(grandTotalKhr),
       cashierAccountId = Value(cashierAccountId),
       cashierName = Value(cashierName),
       sortOrder = Value(sortOrder);
  static Insertable<CashSessionSaleCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? sessionId,
    Expression<String>? saleId,
    Expression<String>? status,
    Expression<String>? paymentMethod,
    Expression<String>? saleType,
    Expression<DateTime>? finalizedAt,
    Expression<int>? totalItems,
    Expression<double>? grandTotalUsd,
    Expression<double>? grandTotalKhr,
    Expression<String>? cashierAccountId,
    Expression<String>? cashierName,
    Expression<DateTime>? voidedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (sessionId != null) 'session_id': sessionId,
      if (saleId != null) 'sale_id': saleId,
      if (status != null) 'status': status,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (saleType != null) 'sale_type': saleType,
      if (finalizedAt != null) 'finalized_at': finalizedAt,
      if (totalItems != null) 'total_items': totalItems,
      if (grandTotalUsd != null) 'grand_total_usd': grandTotalUsd,
      if (grandTotalKhr != null) 'grand_total_khr': grandTotalKhr,
      if (cashierAccountId != null) 'cashier_account_id': cashierAccountId,
      if (cashierName != null) 'cashier_name': cashierName,
      if (voidedAt != null) 'voided_at': voidedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashSessionSaleCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<String>? sessionId,
    Value<String>? saleId,
    Value<String>? status,
    Value<String>? paymentMethod,
    Value<String>? saleType,
    Value<DateTime?>? finalizedAt,
    Value<int>? totalItems,
    Value<double>? grandTotalUsd,
    Value<double>? grandTotalKhr,
    Value<String>? cashierAccountId,
    Value<String>? cashierName,
    Value<DateTime?>? voidedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CashSessionSaleCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      sessionId: sessionId ?? this.sessionId,
      saleId: saleId ?? this.saleId,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleType: saleType ?? this.saleType,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      totalItems: totalItems ?? this.totalItems,
      grandTotalUsd: grandTotalUsd ?? this.grandTotalUsd,
      grandTotalKhr: grandTotalKhr ?? this.grandTotalKhr,
      cashierAccountId: cashierAccountId ?? this.cashierAccountId,
      cashierName: cashierName ?? this.cashierName,
      voidedAt: voidedAt ?? this.voidedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (saleType.present) {
      map['sale_type'] = Variable<String>(saleType.value);
    }
    if (finalizedAt.present) {
      map['finalized_at'] = Variable<DateTime>(finalizedAt.value);
    }
    if (totalItems.present) {
      map['total_items'] = Variable<int>(totalItems.value);
    }
    if (grandTotalUsd.present) {
      map['grand_total_usd'] = Variable<double>(grandTotalUsd.value);
    }
    if (grandTotalKhr.present) {
      map['grand_total_khr'] = Variable<double>(grandTotalKhr.value);
    }
    if (cashierAccountId.present) {
      map['cashier_account_id'] = Variable<String>(cashierAccountId.value);
    }
    if (cashierName.present) {
      map['cashier_name'] = Variable<String>(cashierName.value);
    }
    if (voidedAt.present) {
      map['voided_at'] = Variable<DateTime>(voidedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashSessionSaleCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('sessionId: $sessionId, ')
          ..write('saleId: $saleId, ')
          ..write('status: $status, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('saleType: $saleType, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('totalItems: $totalItems, ')
          ..write('grandTotalUsd: $grandTotalUsd, ')
          ..write('grandTotalKhr: $grandTotalKhr, ')
          ..write('cashierAccountId: $cashierAccountId, ')
          ..write('cashierName: $cashierName, ')
          ..write('voidedAt: $voidedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuCacheScopesTable extends MenuCacheScopes
    with TableInfo<$MenuCacheScopesTable, MenuCacheScope> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuCacheScopesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tenantId, scopeKey, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_cache_scopes';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuCacheScope> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, scopeKey};
  @override
  MenuCacheScope map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuCacheScope(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $MenuCacheScopesTable createAlias(String alias) {
    return $MenuCacheScopesTable(attachedDatabase, alias);
  }
}

class MenuCacheScope extends DataClass implements Insertable<MenuCacheScope> {
  final String tenantId;
  final String scopeKey;
  final DateTime cachedAt;
  const MenuCacheScope({
    required this.tenantId,
    required this.scopeKey,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  MenuCacheScopesCompanion toCompanion(bool nullToAbsent) {
    return MenuCacheScopesCompanion(
      tenantId: Value(tenantId),
      scopeKey: Value(scopeKey),
      cachedAt: Value(cachedAt),
    );
  }

  factory MenuCacheScope.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuCacheScope(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  MenuCacheScope copyWith({
    String? tenantId,
    String? scopeKey,
    DateTime? cachedAt,
  }) => MenuCacheScope(
    tenantId: tenantId ?? this.tenantId,
    scopeKey: scopeKey ?? this.scopeKey,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  MenuCacheScope copyWithCompanion(MenuCacheScopesCompanion data) {
    return MenuCacheScope(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuCacheScope(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tenantId, scopeKey, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuCacheScope &&
          other.tenantId == this.tenantId &&
          other.scopeKey == this.scopeKey &&
          other.cachedAt == this.cachedAt);
}

class MenuCacheScopesCompanion extends UpdateCompanion<MenuCacheScope> {
  final Value<String> tenantId;
  final Value<String> scopeKey;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const MenuCacheScopesCompanion({
    this.tenantId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuCacheScopesCompanion.insert({
    required String tenantId,
    required String scopeKey,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scopeKey = Value(scopeKey),
       cachedAt = Value(cachedAt);
  static Insertable<MenuCacheScope> custom({
    Expression<String>? tenantId,
    Expression<String>? scopeKey,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuCacheScopesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scopeKey,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return MenuCacheScopesCompanion(
      tenantId: tenantId ?? this.tenantId,
      scopeKey: scopeKey ?? this.scopeKey,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuCacheScopesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuItemCacheEntriesTable extends MenuItemCacheEntries
    with TableInfo<$MenuItemCacheEntriesTable, MenuItemCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuItemCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    scopeKey,
    itemId,
    sortOrder,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_item_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuItemCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, scopeKey, itemId};
  @override
  MenuItemCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuItemCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $MenuItemCacheEntriesTable createAlias(String alias) {
    return $MenuItemCacheEntriesTable(attachedDatabase, alias);
  }
}

class MenuItemCacheEntry extends DataClass
    implements Insertable<MenuItemCacheEntry> {
  final String tenantId;
  final String scopeKey;
  final String itemId;
  final int sortOrder;
  final String payloadJson;
  const MenuItemCacheEntry({
    required this.tenantId,
    required this.scopeKey,
    required this.itemId,
    required this.sortOrder,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['item_id'] = Variable<String>(itemId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  MenuItemCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return MenuItemCacheEntriesCompanion(
      tenantId: Value(tenantId),
      scopeKey: Value(scopeKey),
      itemId: Value(itemId),
      sortOrder: Value(sortOrder),
      payloadJson: Value(payloadJson),
    );
  }

  factory MenuItemCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuItemCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      itemId: serializer.fromJson<String>(json['itemId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'itemId': serializer.toJson<String>(itemId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  MenuItemCacheEntry copyWith({
    String? tenantId,
    String? scopeKey,
    String? itemId,
    int? sortOrder,
    String? payloadJson,
  }) => MenuItemCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    scopeKey: scopeKey ?? this.scopeKey,
    itemId: itemId ?? this.itemId,
    sortOrder: sortOrder ?? this.sortOrder,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  MenuItemCacheEntry copyWithCompanion(MenuItemCacheEntriesCompanion data) {
    return MenuItemCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuItemCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('itemId: $itemId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, scopeKey, itemId, sortOrder, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuItemCacheEntry &&
          other.tenantId == this.tenantId &&
          other.scopeKey == this.scopeKey &&
          other.itemId == this.itemId &&
          other.sortOrder == this.sortOrder &&
          other.payloadJson == this.payloadJson);
}

class MenuItemCacheEntriesCompanion
    extends UpdateCompanion<MenuItemCacheEntry> {
  final Value<String> tenantId;
  final Value<String> scopeKey;
  final Value<String> itemId;
  final Value<int> sortOrder;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const MenuItemCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.itemId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuItemCacheEntriesCompanion.insert({
    required String tenantId,
    required String scopeKey,
    required String itemId,
    required int sortOrder,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scopeKey = Value(scopeKey),
       itemId = Value(itemId),
       sortOrder = Value(sortOrder),
       payloadJson = Value(payloadJson);
  static Insertable<MenuItemCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? scopeKey,
    Expression<String>? itemId,
    Expression<int>? sortOrder,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (itemId != null) 'item_id': itemId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuItemCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scopeKey,
    Value<String>? itemId,
    Value<int>? sortOrder,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return MenuItemCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      scopeKey: scopeKey ?? this.scopeKey,
      itemId: itemId ?? this.itemId,
      sortOrder: sortOrder ?? this.sortOrder,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuItemCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('itemId: $itemId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuCategoryCacheEntriesTable extends MenuCategoryCacheEntries
    with TableInfo<$MenuCategoryCacheEntriesTable, MenuCategoryCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuCategoryCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    scopeKey,
    categoryId,
    sortOrder,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_category_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuCategoryCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, scopeKey, categoryId};
  @override
  MenuCategoryCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuCategoryCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $MenuCategoryCacheEntriesTable createAlias(String alias) {
    return $MenuCategoryCacheEntriesTable(attachedDatabase, alias);
  }
}

class MenuCategoryCacheEntry extends DataClass
    implements Insertable<MenuCategoryCacheEntry> {
  final String tenantId;
  final String scopeKey;
  final String categoryId;
  final int sortOrder;
  final String payloadJson;
  const MenuCategoryCacheEntry({
    required this.tenantId,
    required this.scopeKey,
    required this.categoryId,
    required this.sortOrder,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['category_id'] = Variable<String>(categoryId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  MenuCategoryCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return MenuCategoryCacheEntriesCompanion(
      tenantId: Value(tenantId),
      scopeKey: Value(scopeKey),
      categoryId: Value(categoryId),
      sortOrder: Value(sortOrder),
      payloadJson: Value(payloadJson),
    );
  }

  factory MenuCategoryCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuCategoryCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'categoryId': serializer.toJson<String>(categoryId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  MenuCategoryCacheEntry copyWith({
    String? tenantId,
    String? scopeKey,
    String? categoryId,
    int? sortOrder,
    String? payloadJson,
  }) => MenuCategoryCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    scopeKey: scopeKey ?? this.scopeKey,
    categoryId: categoryId ?? this.categoryId,
    sortOrder: sortOrder ?? this.sortOrder,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  MenuCategoryCacheEntry copyWithCompanion(
    MenuCategoryCacheEntriesCompanion data,
  ) {
    return MenuCategoryCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuCategoryCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, scopeKey, categoryId, sortOrder, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuCategoryCacheEntry &&
          other.tenantId == this.tenantId &&
          other.scopeKey == this.scopeKey &&
          other.categoryId == this.categoryId &&
          other.sortOrder == this.sortOrder &&
          other.payloadJson == this.payloadJson);
}

class MenuCategoryCacheEntriesCompanion
    extends UpdateCompanion<MenuCategoryCacheEntry> {
  final Value<String> tenantId;
  final Value<String> scopeKey;
  final Value<String> categoryId;
  final Value<int> sortOrder;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const MenuCategoryCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuCategoryCacheEntriesCompanion.insert({
    required String tenantId,
    required String scopeKey,
    required String categoryId,
    required int sortOrder,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scopeKey = Value(scopeKey),
       categoryId = Value(categoryId),
       sortOrder = Value(sortOrder),
       payloadJson = Value(payloadJson);
  static Insertable<MenuCategoryCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? scopeKey,
    Expression<String>? categoryId,
    Expression<int>? sortOrder,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (categoryId != null) 'category_id': categoryId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuCategoryCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scopeKey,
    Value<String>? categoryId,
    Value<int>? sortOrder,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return MenuCategoryCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      scopeKey: scopeKey ?? this.scopeKey,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuCategoryCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuModifierGroupCacheEntriesTable extends MenuModifierGroupCacheEntries
    with
        TableInfo<
          $MenuModifierGroupCacheEntriesTable,
          MenuModifierGroupCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuModifierGroupCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    scopeKey,
    groupId,
    sortOrder,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_modifier_group_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuModifierGroupCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, scopeKey, groupId};
  @override
  MenuModifierGroupCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuModifierGroupCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $MenuModifierGroupCacheEntriesTable createAlias(String alias) {
    return $MenuModifierGroupCacheEntriesTable(attachedDatabase, alias);
  }
}

class MenuModifierGroupCacheEntry extends DataClass
    implements Insertable<MenuModifierGroupCacheEntry> {
  final String tenantId;
  final String scopeKey;
  final String groupId;
  final int sortOrder;
  final String payloadJson;
  const MenuModifierGroupCacheEntry({
    required this.tenantId,
    required this.scopeKey,
    required this.groupId,
    required this.sortOrder,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['group_id'] = Variable<String>(groupId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  MenuModifierGroupCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return MenuModifierGroupCacheEntriesCompanion(
      tenantId: Value(tenantId),
      scopeKey: Value(scopeKey),
      groupId: Value(groupId),
      sortOrder: Value(sortOrder),
      payloadJson: Value(payloadJson),
    );
  }

  factory MenuModifierGroupCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuModifierGroupCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      groupId: serializer.fromJson<String>(json['groupId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'groupId': serializer.toJson<String>(groupId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  MenuModifierGroupCacheEntry copyWith({
    String? tenantId,
    String? scopeKey,
    String? groupId,
    int? sortOrder,
    String? payloadJson,
  }) => MenuModifierGroupCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    scopeKey: scopeKey ?? this.scopeKey,
    groupId: groupId ?? this.groupId,
    sortOrder: sortOrder ?? this.sortOrder,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  MenuModifierGroupCacheEntry copyWithCompanion(
    MenuModifierGroupCacheEntriesCompanion data,
  ) {
    return MenuModifierGroupCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuModifierGroupCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, scopeKey, groupId, sortOrder, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuModifierGroupCacheEntry &&
          other.tenantId == this.tenantId &&
          other.scopeKey == this.scopeKey &&
          other.groupId == this.groupId &&
          other.sortOrder == this.sortOrder &&
          other.payloadJson == this.payloadJson);
}

class MenuModifierGroupCacheEntriesCompanion
    extends UpdateCompanion<MenuModifierGroupCacheEntry> {
  final Value<String> tenantId;
  final Value<String> scopeKey;
  final Value<String> groupId;
  final Value<int> sortOrder;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const MenuModifierGroupCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.groupId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuModifierGroupCacheEntriesCompanion.insert({
    required String tenantId,
    required String scopeKey,
    required String groupId,
    required int sortOrder,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scopeKey = Value(scopeKey),
       groupId = Value(groupId),
       sortOrder = Value(sortOrder),
       payloadJson = Value(payloadJson);
  static Insertable<MenuModifierGroupCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? scopeKey,
    Expression<String>? groupId,
    Expression<int>? sortOrder,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (groupId != null) 'group_id': groupId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuModifierGroupCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scopeKey,
    Value<String>? groupId,
    Value<int>? sortOrder,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return MenuModifierGroupCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      scopeKey: scopeKey ?? this.scopeKey,
      groupId: groupId ?? this.groupId,
      sortOrder: sortOrder ?? this.sortOrder,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuModifierGroupCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuBranchCacheEntriesTable extends MenuBranchCacheEntries
    with TableInfo<$MenuBranchCacheEntriesTable, MenuBranchCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuBranchCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    scopeKey,
    branchId,
    sortOrder,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_branch_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuBranchCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, scopeKey, branchId};
  @override
  MenuBranchCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuBranchCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $MenuBranchCacheEntriesTable createAlias(String alias) {
    return $MenuBranchCacheEntriesTable(attachedDatabase, alias);
  }
}

class MenuBranchCacheEntry extends DataClass
    implements Insertable<MenuBranchCacheEntry> {
  final String tenantId;
  final String scopeKey;
  final String branchId;
  final int sortOrder;
  final String payloadJson;
  const MenuBranchCacheEntry({
    required this.tenantId,
    required this.scopeKey,
    required this.branchId,
    required this.sortOrder,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['branch_id'] = Variable<String>(branchId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  MenuBranchCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return MenuBranchCacheEntriesCompanion(
      tenantId: Value(tenantId),
      scopeKey: Value(scopeKey),
      branchId: Value(branchId),
      sortOrder: Value(sortOrder),
      payloadJson: Value(payloadJson),
    );
  }

  factory MenuBranchCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuBranchCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      branchId: serializer.fromJson<String>(json['branchId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'branchId': serializer.toJson<String>(branchId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  MenuBranchCacheEntry copyWith({
    String? tenantId,
    String? scopeKey,
    String? branchId,
    int? sortOrder,
    String? payloadJson,
  }) => MenuBranchCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    scopeKey: scopeKey ?? this.scopeKey,
    branchId: branchId ?? this.branchId,
    sortOrder: sortOrder ?? this.sortOrder,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  MenuBranchCacheEntry copyWithCompanion(MenuBranchCacheEntriesCompanion data) {
    return MenuBranchCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuBranchCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('branchId: $branchId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, scopeKey, branchId, sortOrder, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuBranchCacheEntry &&
          other.tenantId == this.tenantId &&
          other.scopeKey == this.scopeKey &&
          other.branchId == this.branchId &&
          other.sortOrder == this.sortOrder &&
          other.payloadJson == this.payloadJson);
}

class MenuBranchCacheEntriesCompanion
    extends UpdateCompanion<MenuBranchCacheEntry> {
  final Value<String> tenantId;
  final Value<String> scopeKey;
  final Value<String> branchId;
  final Value<int> sortOrder;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const MenuBranchCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.branchId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuBranchCacheEntriesCompanion.insert({
    required String tenantId,
    required String scopeKey,
    required String branchId,
    required int sortOrder,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scopeKey = Value(scopeKey),
       branchId = Value(branchId),
       sortOrder = Value(sortOrder),
       payloadJson = Value(payloadJson);
  static Insertable<MenuBranchCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? scopeKey,
    Expression<String>? branchId,
    Expression<int>? sortOrder,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (branchId != null) 'branch_id': branchId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuBranchCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scopeKey,
    Value<String>? branchId,
    Value<int>? sortOrder,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return MenuBranchCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      scopeKey: scopeKey ?? this.scopeKey,
      branchId: branchId ?? this.branchId,
      sortOrder: sortOrder ?? this.sortOrder,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MenuBranchCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('branchId: $branchId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceContextCacheEntriesTable extends AttendanceContextCacheEntries
    with
        TableInfo<
          $AttendanceContextCacheEntriesTable,
          AttendanceContextCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceContextCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canCheckInMeta = const VerificationMeta(
    'canCheckIn',
  );
  @override
  late final GeneratedColumn<bool> canCheckIn = GeneratedColumn<bool>(
    'can_check_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_check_in" IN (0, 1))',
    ),
  );
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMessageMeta = const VerificationMeta(
    'reasonMessage',
  );
  @override
  late final GeneratedColumn<String> reasonMessage = GeneratedColumn<String>(
    'reason_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeShiftIdMeta = const VerificationMeta(
    'activeShiftId',
  );
  @override
  late final GeneratedColumn<String> activeShiftId = GeneratedColumn<String>(
    'active_shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeShiftStartAtMeta =
      const VerificationMeta('activeShiftStartAt');
  @override
  late final GeneratedColumn<String> activeShiftStartAt =
      GeneratedColumn<String>(
        'active_shift_start_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _activeShiftEndAtMeta = const VerificationMeta(
    'activeShiftEndAt',
  );
  @override
  late final GeneratedColumn<String> activeShiftEndAt = GeneratedColumn<String>(
    'active_shift_end_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeAttendanceIdMeta =
      const VerificationMeta('activeAttendanceId');
  @override
  late final GeneratedColumn<String> activeAttendanceId =
      GeneratedColumn<String>(
        'active_attendance_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _activeAttendanceStartAtMeta =
      const VerificationMeta('activeAttendanceStartAt');
  @override
  late final GeneratedColumn<String> activeAttendanceStartAt =
      GeneratedColumn<String>(
        'active_attendance_start_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _locationVerificationModeMeta =
      const VerificationMeta('locationVerificationMode');
  @override
  late final GeneratedColumn<String> locationVerificationMode =
      GeneratedColumn<String>(
        'location_verification_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _geofenceCenterLatMeta = const VerificationMeta(
    'geofenceCenterLat',
  );
  @override
  late final GeneratedColumn<double> geofenceCenterLat =
      GeneratedColumn<double>(
        'geofence_center_lat',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _geofenceCenterLngMeta = const VerificationMeta(
    'geofenceCenterLng',
  );
  @override
  late final GeneratedColumn<double> geofenceCenterLng =
      GeneratedColumn<double>(
        'geofence_center_lng',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _geofenceRadiusMMeta = const VerificationMeta(
    'geofenceRadiusM',
  );
  @override
  late final GeneratedColumn<double> geofenceRadiusM = GeneratedColumn<double>(
    'geofence_radius_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    branchId,
    accountId,
    canCheckIn,
    reasonCode,
    reasonMessage,
    activeShiftId,
    activeShiftStartAt,
    activeShiftEndAt,
    activeAttendanceId,
    activeAttendanceStartAt,
    locationVerificationMode,
    geofenceCenterLat,
    geofenceCenterLng,
    geofenceRadiusM,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_context_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceContextCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('can_check_in')) {
      context.handle(
        _canCheckInMeta,
        canCheckIn.isAcceptableOrUnknown(
          data['can_check_in']!,
          _canCheckInMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canCheckInMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    }
    if (data.containsKey('reason_message')) {
      context.handle(
        _reasonMessageMeta,
        reasonMessage.isAcceptableOrUnknown(
          data['reason_message']!,
          _reasonMessageMeta,
        ),
      );
    }
    if (data.containsKey('active_shift_id')) {
      context.handle(
        _activeShiftIdMeta,
        activeShiftId.isAcceptableOrUnknown(
          data['active_shift_id']!,
          _activeShiftIdMeta,
        ),
      );
    }
    if (data.containsKey('active_shift_start_at')) {
      context.handle(
        _activeShiftStartAtMeta,
        activeShiftStartAt.isAcceptableOrUnknown(
          data['active_shift_start_at']!,
          _activeShiftStartAtMeta,
        ),
      );
    }
    if (data.containsKey('active_shift_end_at')) {
      context.handle(
        _activeShiftEndAtMeta,
        activeShiftEndAt.isAcceptableOrUnknown(
          data['active_shift_end_at']!,
          _activeShiftEndAtMeta,
        ),
      );
    }
    if (data.containsKey('active_attendance_id')) {
      context.handle(
        _activeAttendanceIdMeta,
        activeAttendanceId.isAcceptableOrUnknown(
          data['active_attendance_id']!,
          _activeAttendanceIdMeta,
        ),
      );
    }
    if (data.containsKey('active_attendance_start_at')) {
      context.handle(
        _activeAttendanceStartAtMeta,
        activeAttendanceStartAt.isAcceptableOrUnknown(
          data['active_attendance_start_at']!,
          _activeAttendanceStartAtMeta,
        ),
      );
    }
    if (data.containsKey('location_verification_mode')) {
      context.handle(
        _locationVerificationModeMeta,
        locationVerificationMode.isAcceptableOrUnknown(
          data['location_verification_mode']!,
          _locationVerificationModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationVerificationModeMeta);
    }
    if (data.containsKey('geofence_center_lat')) {
      context.handle(
        _geofenceCenterLatMeta,
        geofenceCenterLat.isAcceptableOrUnknown(
          data['geofence_center_lat']!,
          _geofenceCenterLatMeta,
        ),
      );
    }
    if (data.containsKey('geofence_center_lng')) {
      context.handle(
        _geofenceCenterLngMeta,
        geofenceCenterLng.isAcceptableOrUnknown(
          data['geofence_center_lng']!,
          _geofenceCenterLngMeta,
        ),
      );
    }
    if (data.containsKey('geofence_radius_m')) {
      context.handle(
        _geofenceRadiusMMeta,
        geofenceRadiusM.isAcceptableOrUnknown(
          data['geofence_radius_m']!,
          _geofenceRadiusMMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, branchId, accountId};
  @override
  AttendanceContextCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceContextCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      canCheckIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_check_in'],
      )!,
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      ),
      reasonMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_message'],
      ),
      activeShiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_shift_id'],
      ),
      activeShiftStartAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_shift_start_at'],
      ),
      activeShiftEndAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_shift_end_at'],
      ),
      activeAttendanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_attendance_id'],
      ),
      activeAttendanceStartAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_attendance_start_at'],
      ),
      locationVerificationMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_verification_mode'],
      )!,
      geofenceCenterLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}geofence_center_lat'],
      ),
      geofenceCenterLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}geofence_center_lng'],
      ),
      geofenceRadiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}geofence_radius_m'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $AttendanceContextCacheEntriesTable createAlias(String alias) {
    return $AttendanceContextCacheEntriesTable(attachedDatabase, alias);
  }
}

class AttendanceContextCacheEntry extends DataClass
    implements Insertable<AttendanceContextCacheEntry> {
  final String tenantId;
  final String branchId;
  final String accountId;
  final bool canCheckIn;
  final String? reasonCode;
  final String? reasonMessage;
  final String? activeShiftId;
  final String? activeShiftStartAt;
  final String? activeShiftEndAt;
  final String? activeAttendanceId;
  final String? activeAttendanceStartAt;
  final String locationVerificationMode;
  final double? geofenceCenterLat;
  final double? geofenceCenterLng;
  final double? geofenceRadiusM;
  final DateTime cachedAt;
  const AttendanceContextCacheEntry({
    required this.tenantId,
    required this.branchId,
    required this.accountId,
    required this.canCheckIn,
    this.reasonCode,
    this.reasonMessage,
    this.activeShiftId,
    this.activeShiftStartAt,
    this.activeShiftEndAt,
    this.activeAttendanceId,
    this.activeAttendanceStartAt,
    required this.locationVerificationMode,
    this.geofenceCenterLat,
    this.geofenceCenterLng,
    this.geofenceRadiusM,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['account_id'] = Variable<String>(accountId);
    map['can_check_in'] = Variable<bool>(canCheckIn);
    if (!nullToAbsent || reasonCode != null) {
      map['reason_code'] = Variable<String>(reasonCode);
    }
    if (!nullToAbsent || reasonMessage != null) {
      map['reason_message'] = Variable<String>(reasonMessage);
    }
    if (!nullToAbsent || activeShiftId != null) {
      map['active_shift_id'] = Variable<String>(activeShiftId);
    }
    if (!nullToAbsent || activeShiftStartAt != null) {
      map['active_shift_start_at'] = Variable<String>(activeShiftStartAt);
    }
    if (!nullToAbsent || activeShiftEndAt != null) {
      map['active_shift_end_at'] = Variable<String>(activeShiftEndAt);
    }
    if (!nullToAbsent || activeAttendanceId != null) {
      map['active_attendance_id'] = Variable<String>(activeAttendanceId);
    }
    if (!nullToAbsent || activeAttendanceStartAt != null) {
      map['active_attendance_start_at'] = Variable<String>(
        activeAttendanceStartAt,
      );
    }
    map['location_verification_mode'] = Variable<String>(
      locationVerificationMode,
    );
    if (!nullToAbsent || geofenceCenterLat != null) {
      map['geofence_center_lat'] = Variable<double>(geofenceCenterLat);
    }
    if (!nullToAbsent || geofenceCenterLng != null) {
      map['geofence_center_lng'] = Variable<double>(geofenceCenterLng);
    }
    if (!nullToAbsent || geofenceRadiusM != null) {
      map['geofence_radius_m'] = Variable<double>(geofenceRadiusM);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  AttendanceContextCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return AttendanceContextCacheEntriesCompanion(
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      accountId: Value(accountId),
      canCheckIn: Value(canCheckIn),
      reasonCode: reasonCode == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonCode),
      reasonMessage: reasonMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonMessage),
      activeShiftId: activeShiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeShiftId),
      activeShiftStartAt: activeShiftStartAt == null && nullToAbsent
          ? const Value.absent()
          : Value(activeShiftStartAt),
      activeShiftEndAt: activeShiftEndAt == null && nullToAbsent
          ? const Value.absent()
          : Value(activeShiftEndAt),
      activeAttendanceId: activeAttendanceId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeAttendanceId),
      activeAttendanceStartAt: activeAttendanceStartAt == null && nullToAbsent
          ? const Value.absent()
          : Value(activeAttendanceStartAt),
      locationVerificationMode: Value(locationVerificationMode),
      geofenceCenterLat: geofenceCenterLat == null && nullToAbsent
          ? const Value.absent()
          : Value(geofenceCenterLat),
      geofenceCenterLng: geofenceCenterLng == null && nullToAbsent
          ? const Value.absent()
          : Value(geofenceCenterLng),
      geofenceRadiusM: geofenceRadiusM == null && nullToAbsent
          ? const Value.absent()
          : Value(geofenceRadiusM),
      cachedAt: Value(cachedAt),
    );
  }

  factory AttendanceContextCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceContextCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      canCheckIn: serializer.fromJson<bool>(json['canCheckIn']),
      reasonCode: serializer.fromJson<String?>(json['reasonCode']),
      reasonMessage: serializer.fromJson<String?>(json['reasonMessage']),
      activeShiftId: serializer.fromJson<String?>(json['activeShiftId']),
      activeShiftStartAt: serializer.fromJson<String?>(
        json['activeShiftStartAt'],
      ),
      activeShiftEndAt: serializer.fromJson<String?>(json['activeShiftEndAt']),
      activeAttendanceId: serializer.fromJson<String?>(
        json['activeAttendanceId'],
      ),
      activeAttendanceStartAt: serializer.fromJson<String?>(
        json['activeAttendanceStartAt'],
      ),
      locationVerificationMode: serializer.fromJson<String>(
        json['locationVerificationMode'],
      ),
      geofenceCenterLat: serializer.fromJson<double?>(
        json['geofenceCenterLat'],
      ),
      geofenceCenterLng: serializer.fromJson<double?>(
        json['geofenceCenterLng'],
      ),
      geofenceRadiusM: serializer.fromJson<double?>(json['geofenceRadiusM']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'accountId': serializer.toJson<String>(accountId),
      'canCheckIn': serializer.toJson<bool>(canCheckIn),
      'reasonCode': serializer.toJson<String?>(reasonCode),
      'reasonMessage': serializer.toJson<String?>(reasonMessage),
      'activeShiftId': serializer.toJson<String?>(activeShiftId),
      'activeShiftStartAt': serializer.toJson<String?>(activeShiftStartAt),
      'activeShiftEndAt': serializer.toJson<String?>(activeShiftEndAt),
      'activeAttendanceId': serializer.toJson<String?>(activeAttendanceId),
      'activeAttendanceStartAt': serializer.toJson<String?>(
        activeAttendanceStartAt,
      ),
      'locationVerificationMode': serializer.toJson<String>(
        locationVerificationMode,
      ),
      'geofenceCenterLat': serializer.toJson<double?>(geofenceCenterLat),
      'geofenceCenterLng': serializer.toJson<double?>(geofenceCenterLng),
      'geofenceRadiusM': serializer.toJson<double?>(geofenceRadiusM),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  AttendanceContextCacheEntry copyWith({
    String? tenantId,
    String? branchId,
    String? accountId,
    bool? canCheckIn,
    Value<String?> reasonCode = const Value.absent(),
    Value<String?> reasonMessage = const Value.absent(),
    Value<String?> activeShiftId = const Value.absent(),
    Value<String?> activeShiftStartAt = const Value.absent(),
    Value<String?> activeShiftEndAt = const Value.absent(),
    Value<String?> activeAttendanceId = const Value.absent(),
    Value<String?> activeAttendanceStartAt = const Value.absent(),
    String? locationVerificationMode,
    Value<double?> geofenceCenterLat = const Value.absent(),
    Value<double?> geofenceCenterLng = const Value.absent(),
    Value<double?> geofenceRadiusM = const Value.absent(),
    DateTime? cachedAt,
  }) => AttendanceContextCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    accountId: accountId ?? this.accountId,
    canCheckIn: canCheckIn ?? this.canCheckIn,
    reasonCode: reasonCode.present ? reasonCode.value : this.reasonCode,
    reasonMessage: reasonMessage.present
        ? reasonMessage.value
        : this.reasonMessage,
    activeShiftId: activeShiftId.present
        ? activeShiftId.value
        : this.activeShiftId,
    activeShiftStartAt: activeShiftStartAt.present
        ? activeShiftStartAt.value
        : this.activeShiftStartAt,
    activeShiftEndAt: activeShiftEndAt.present
        ? activeShiftEndAt.value
        : this.activeShiftEndAt,
    activeAttendanceId: activeAttendanceId.present
        ? activeAttendanceId.value
        : this.activeAttendanceId,
    activeAttendanceStartAt: activeAttendanceStartAt.present
        ? activeAttendanceStartAt.value
        : this.activeAttendanceStartAt,
    locationVerificationMode:
        locationVerificationMode ?? this.locationVerificationMode,
    geofenceCenterLat: geofenceCenterLat.present
        ? geofenceCenterLat.value
        : this.geofenceCenterLat,
    geofenceCenterLng: geofenceCenterLng.present
        ? geofenceCenterLng.value
        : this.geofenceCenterLng,
    geofenceRadiusM: geofenceRadiusM.present
        ? geofenceRadiusM.value
        : this.geofenceRadiusM,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  AttendanceContextCacheEntry copyWithCompanion(
    AttendanceContextCacheEntriesCompanion data,
  ) {
    return AttendanceContextCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      canCheckIn: data.canCheckIn.present
          ? data.canCheckIn.value
          : this.canCheckIn,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      reasonMessage: data.reasonMessage.present
          ? data.reasonMessage.value
          : this.reasonMessage,
      activeShiftId: data.activeShiftId.present
          ? data.activeShiftId.value
          : this.activeShiftId,
      activeShiftStartAt: data.activeShiftStartAt.present
          ? data.activeShiftStartAt.value
          : this.activeShiftStartAt,
      activeShiftEndAt: data.activeShiftEndAt.present
          ? data.activeShiftEndAt.value
          : this.activeShiftEndAt,
      activeAttendanceId: data.activeAttendanceId.present
          ? data.activeAttendanceId.value
          : this.activeAttendanceId,
      activeAttendanceStartAt: data.activeAttendanceStartAt.present
          ? data.activeAttendanceStartAt.value
          : this.activeAttendanceStartAt,
      locationVerificationMode: data.locationVerificationMode.present
          ? data.locationVerificationMode.value
          : this.locationVerificationMode,
      geofenceCenterLat: data.geofenceCenterLat.present
          ? data.geofenceCenterLat.value
          : this.geofenceCenterLat,
      geofenceCenterLng: data.geofenceCenterLng.present
          ? data.geofenceCenterLng.value
          : this.geofenceCenterLng,
      geofenceRadiusM: data.geofenceRadiusM.present
          ? data.geofenceRadiusM.value
          : this.geofenceRadiusM,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceContextCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('canCheckIn: $canCheckIn, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reasonMessage: $reasonMessage, ')
          ..write('activeShiftId: $activeShiftId, ')
          ..write('activeShiftStartAt: $activeShiftStartAt, ')
          ..write('activeShiftEndAt: $activeShiftEndAt, ')
          ..write('activeAttendanceId: $activeAttendanceId, ')
          ..write('activeAttendanceStartAt: $activeAttendanceStartAt, ')
          ..write('locationVerificationMode: $locationVerificationMode, ')
          ..write('geofenceCenterLat: $geofenceCenterLat, ')
          ..write('geofenceCenterLng: $geofenceCenterLng, ')
          ..write('geofenceRadiusM: $geofenceRadiusM, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    branchId,
    accountId,
    canCheckIn,
    reasonCode,
    reasonMessage,
    activeShiftId,
    activeShiftStartAt,
    activeShiftEndAt,
    activeAttendanceId,
    activeAttendanceStartAt,
    locationVerificationMode,
    geofenceCenterLat,
    geofenceCenterLng,
    geofenceRadiusM,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceContextCacheEntry &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.accountId == this.accountId &&
          other.canCheckIn == this.canCheckIn &&
          other.reasonCode == this.reasonCode &&
          other.reasonMessage == this.reasonMessage &&
          other.activeShiftId == this.activeShiftId &&
          other.activeShiftStartAt == this.activeShiftStartAt &&
          other.activeShiftEndAt == this.activeShiftEndAt &&
          other.activeAttendanceId == this.activeAttendanceId &&
          other.activeAttendanceStartAt == this.activeAttendanceStartAt &&
          other.locationVerificationMode == this.locationVerificationMode &&
          other.geofenceCenterLat == this.geofenceCenterLat &&
          other.geofenceCenterLng == this.geofenceCenterLng &&
          other.geofenceRadiusM == this.geofenceRadiusM &&
          other.cachedAt == this.cachedAt);
}

class AttendanceContextCacheEntriesCompanion
    extends UpdateCompanion<AttendanceContextCacheEntry> {
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<String> accountId;
  final Value<bool> canCheckIn;
  final Value<String?> reasonCode;
  final Value<String?> reasonMessage;
  final Value<String?> activeShiftId;
  final Value<String?> activeShiftStartAt;
  final Value<String?> activeShiftEndAt;
  final Value<String?> activeAttendanceId;
  final Value<String?> activeAttendanceStartAt;
  final Value<String> locationVerificationMode;
  final Value<double?> geofenceCenterLat;
  final Value<double?> geofenceCenterLng;
  final Value<double?> geofenceRadiusM;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const AttendanceContextCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.canCheckIn = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.reasonMessage = const Value.absent(),
    this.activeShiftId = const Value.absent(),
    this.activeShiftStartAt = const Value.absent(),
    this.activeShiftEndAt = const Value.absent(),
    this.activeAttendanceId = const Value.absent(),
    this.activeAttendanceStartAt = const Value.absent(),
    this.locationVerificationMode = const Value.absent(),
    this.geofenceCenterLat = const Value.absent(),
    this.geofenceCenterLng = const Value.absent(),
    this.geofenceRadiusM = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceContextCacheEntriesCompanion.insert({
    required String tenantId,
    required String branchId,
    required String accountId,
    required bool canCheckIn,
    this.reasonCode = const Value.absent(),
    this.reasonMessage = const Value.absent(),
    this.activeShiftId = const Value.absent(),
    this.activeShiftStartAt = const Value.absent(),
    this.activeShiftEndAt = const Value.absent(),
    this.activeAttendanceId = const Value.absent(),
    this.activeAttendanceStartAt = const Value.absent(),
    required String locationVerificationMode,
    this.geofenceCenterLat = const Value.absent(),
    this.geofenceCenterLng = const Value.absent(),
    this.geofenceRadiusM = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       branchId = Value(branchId),
       accountId = Value(accountId),
       canCheckIn = Value(canCheckIn),
       locationVerificationMode = Value(locationVerificationMode),
       cachedAt = Value(cachedAt);
  static Insertable<AttendanceContextCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? accountId,
    Expression<bool>? canCheckIn,
    Expression<String>? reasonCode,
    Expression<String>? reasonMessage,
    Expression<String>? activeShiftId,
    Expression<String>? activeShiftStartAt,
    Expression<String>? activeShiftEndAt,
    Expression<String>? activeAttendanceId,
    Expression<String>? activeAttendanceStartAt,
    Expression<String>? locationVerificationMode,
    Expression<double>? geofenceCenterLat,
    Expression<double>? geofenceCenterLng,
    Expression<double>? geofenceRadiusM,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (accountId != null) 'account_id': accountId,
      if (canCheckIn != null) 'can_check_in': canCheckIn,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (reasonMessage != null) 'reason_message': reasonMessage,
      if (activeShiftId != null) 'active_shift_id': activeShiftId,
      if (activeShiftStartAt != null)
        'active_shift_start_at': activeShiftStartAt,
      if (activeShiftEndAt != null) 'active_shift_end_at': activeShiftEndAt,
      if (activeAttendanceId != null)
        'active_attendance_id': activeAttendanceId,
      if (activeAttendanceStartAt != null)
        'active_attendance_start_at': activeAttendanceStartAt,
      if (locationVerificationMode != null)
        'location_verification_mode': locationVerificationMode,
      if (geofenceCenterLat != null) 'geofence_center_lat': geofenceCenterLat,
      if (geofenceCenterLng != null) 'geofence_center_lng': geofenceCenterLng,
      if (geofenceRadiusM != null) 'geofence_radius_m': geofenceRadiusM,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceContextCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<String>? accountId,
    Value<bool>? canCheckIn,
    Value<String?>? reasonCode,
    Value<String?>? reasonMessage,
    Value<String?>? activeShiftId,
    Value<String?>? activeShiftStartAt,
    Value<String?>? activeShiftEndAt,
    Value<String?>? activeAttendanceId,
    Value<String?>? activeAttendanceStartAt,
    Value<String>? locationVerificationMode,
    Value<double?>? geofenceCenterLat,
    Value<double?>? geofenceCenterLng,
    Value<double?>? geofenceRadiusM,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return AttendanceContextCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      accountId: accountId ?? this.accountId,
      canCheckIn: canCheckIn ?? this.canCheckIn,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonMessage: reasonMessage ?? this.reasonMessage,
      activeShiftId: activeShiftId ?? this.activeShiftId,
      activeShiftStartAt: activeShiftStartAt ?? this.activeShiftStartAt,
      activeShiftEndAt: activeShiftEndAt ?? this.activeShiftEndAt,
      activeAttendanceId: activeAttendanceId ?? this.activeAttendanceId,
      activeAttendanceStartAt:
          activeAttendanceStartAt ?? this.activeAttendanceStartAt,
      locationVerificationMode:
          locationVerificationMode ?? this.locationVerificationMode,
      geofenceCenterLat: geofenceCenterLat ?? this.geofenceCenterLat,
      geofenceCenterLng: geofenceCenterLng ?? this.geofenceCenterLng,
      geofenceRadiusM: geofenceRadiusM ?? this.geofenceRadiusM,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (canCheckIn.present) {
      map['can_check_in'] = Variable<bool>(canCheckIn.value);
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (reasonMessage.present) {
      map['reason_message'] = Variable<String>(reasonMessage.value);
    }
    if (activeShiftId.present) {
      map['active_shift_id'] = Variable<String>(activeShiftId.value);
    }
    if (activeShiftStartAt.present) {
      map['active_shift_start_at'] = Variable<String>(activeShiftStartAt.value);
    }
    if (activeShiftEndAt.present) {
      map['active_shift_end_at'] = Variable<String>(activeShiftEndAt.value);
    }
    if (activeAttendanceId.present) {
      map['active_attendance_id'] = Variable<String>(activeAttendanceId.value);
    }
    if (activeAttendanceStartAt.present) {
      map['active_attendance_start_at'] = Variable<String>(
        activeAttendanceStartAt.value,
      );
    }
    if (locationVerificationMode.present) {
      map['location_verification_mode'] = Variable<String>(
        locationVerificationMode.value,
      );
    }
    if (geofenceCenterLat.present) {
      map['geofence_center_lat'] = Variable<double>(geofenceCenterLat.value);
    }
    if (geofenceCenterLng.present) {
      map['geofence_center_lng'] = Variable<double>(geofenceCenterLng.value);
    }
    if (geofenceRadiusM.present) {
      map['geofence_radius_m'] = Variable<double>(geofenceRadiusM.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceContextCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('canCheckIn: $canCheckIn, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('reasonMessage: $reasonMessage, ')
          ..write('activeShiftId: $activeShiftId, ')
          ..write('activeShiftStartAt: $activeShiftStartAt, ')
          ..write('activeShiftEndAt: $activeShiftEndAt, ')
          ..write('activeAttendanceId: $activeAttendanceId, ')
          ..write('activeAttendanceStartAt: $activeAttendanceStartAt, ')
          ..write('locationVerificationMode: $locationVerificationMode, ')
          ..write('geofenceCenterLat: $geofenceCenterLat, ')
          ..write('geofenceCenterLng: $geofenceCenterLng, ')
          ..write('geofenceRadiusM: $geofenceRadiusM, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceRecordCacheEntriesTable extends AttendanceRecordCacheEntries
    with
        TableInfo<
          $AttendanceRecordCacheEntriesTable,
          AttendanceRecordCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceRecordCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employeeIdMeta = const VerificationMeta(
    'employeeId',
  );
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
    'employee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationLatMeta = const VerificationMeta(
    'locationLat',
  );
  @override
  late final GeneratedColumn<double> locationLat = GeneratedColumn<double>(
    'location_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLngMeta = const VerificationMeta(
    'locationLng',
  );
  @override
  late final GeneratedColumn<double> locationLng = GeneratedColumn<double>(
    'location_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    branchId,
    accountId,
    recordId,
    employeeId,
    type,
    occurredAt,
    createdAt,
    locationLat,
    locationLng,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_record_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceRecordCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
        _employeeIdMeta,
        employeeId.isAcceptableOrUnknown(data['employee_id']!, _employeeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('location_lat')) {
      context.handle(
        _locationLatMeta,
        locationLat.isAcceptableOrUnknown(
          data['location_lat']!,
          _locationLatMeta,
        ),
      );
    }
    if (data.containsKey('location_lng')) {
      context.handle(
        _locationLngMeta,
        locationLng.isAcceptableOrUnknown(
          data['location_lng']!,
          _locationLngMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    tenantId,
    branchId,
    accountId,
    recordId,
  };
  @override
  AttendanceRecordCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceRecordCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      employeeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employee_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      locationLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lat'],
      ),
      locationLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lng'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AttendanceRecordCacheEntriesTable createAlias(String alias) {
    return $AttendanceRecordCacheEntriesTable(attachedDatabase, alias);
  }
}

class AttendanceRecordCacheEntry extends DataClass
    implements Insertable<AttendanceRecordCacheEntry> {
  final String tenantId;
  final String branchId;
  final String accountId;
  final String recordId;
  final String employeeId;
  final String type;
  final DateTime occurredAt;
  final DateTime createdAt;
  final double? locationLat;
  final double? locationLng;
  final int sortOrder;
  const AttendanceRecordCacheEntry({
    required this.tenantId,
    required this.branchId,
    required this.accountId,
    required this.recordId,
    required this.employeeId,
    required this.type,
    required this.occurredAt,
    required this.createdAt,
    this.locationLat,
    this.locationLng,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['account_id'] = Variable<String>(accountId);
    map['record_id'] = Variable<String>(recordId);
    map['employee_id'] = Variable<String>(employeeId);
    map['type'] = Variable<String>(type);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || locationLat != null) {
      map['location_lat'] = Variable<double>(locationLat);
    }
    if (!nullToAbsent || locationLng != null) {
      map['location_lng'] = Variable<double>(locationLng);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AttendanceRecordCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return AttendanceRecordCacheEntriesCompanion(
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      accountId: Value(accountId),
      recordId: Value(recordId),
      employeeId: Value(employeeId),
      type: Value(type),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      locationLat: locationLat == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLat),
      locationLng: locationLng == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLng),
      sortOrder: Value(sortOrder),
    );
  }

  factory AttendanceRecordCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceRecordCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      recordId: serializer.fromJson<String>(json['recordId']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      type: serializer.fromJson<String>(json['type']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      locationLat: serializer.fromJson<double?>(json['locationLat']),
      locationLng: serializer.fromJson<double?>(json['locationLng']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'accountId': serializer.toJson<String>(accountId),
      'recordId': serializer.toJson<String>(recordId),
      'employeeId': serializer.toJson<String>(employeeId),
      'type': serializer.toJson<String>(type),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'locationLat': serializer.toJson<double?>(locationLat),
      'locationLng': serializer.toJson<double?>(locationLng),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AttendanceRecordCacheEntry copyWith({
    String? tenantId,
    String? branchId,
    String? accountId,
    String? recordId,
    String? employeeId,
    String? type,
    DateTime? occurredAt,
    DateTime? createdAt,
    Value<double?> locationLat = const Value.absent(),
    Value<double?> locationLng = const Value.absent(),
    int? sortOrder,
  }) => AttendanceRecordCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    accountId: accountId ?? this.accountId,
    recordId: recordId ?? this.recordId,
    employeeId: employeeId ?? this.employeeId,
    type: type ?? this.type,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
    locationLat: locationLat.present ? locationLat.value : this.locationLat,
    locationLng: locationLng.present ? locationLng.value : this.locationLng,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AttendanceRecordCacheEntry copyWithCompanion(
    AttendanceRecordCacheEntriesCompanion data,
  ) {
    return AttendanceRecordCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      employeeId: data.employeeId.present
          ? data.employeeId.value
          : this.employeeId,
      type: data.type.present ? data.type.value : this.type,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      locationLat: data.locationLat.present
          ? data.locationLat.value
          : this.locationLat,
      locationLng: data.locationLng.present
          ? data.locationLng.value
          : this.locationLng,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('recordId: $recordId, ')
          ..write('employeeId: $employeeId, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLng: $locationLng, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    branchId,
    accountId,
    recordId,
    employeeId,
    type,
    occurredAt,
    createdAt,
    locationLat,
    locationLng,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceRecordCacheEntry &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.accountId == this.accountId &&
          other.recordId == this.recordId &&
          other.employeeId == this.employeeId &&
          other.type == this.type &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.locationLat == this.locationLat &&
          other.locationLng == this.locationLng &&
          other.sortOrder == this.sortOrder);
}

class AttendanceRecordCacheEntriesCompanion
    extends UpdateCompanion<AttendanceRecordCacheEntry> {
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<String> accountId;
  final Value<String> recordId;
  final Value<String> employeeId;
  final Value<String> type;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  final Value<double?> locationLat;
  final Value<double?> locationLng;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AttendanceRecordCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.type = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.locationLat = const Value.absent(),
    this.locationLng = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceRecordCacheEntriesCompanion.insert({
    required String tenantId,
    required String branchId,
    required String accountId,
    required String recordId,
    required String employeeId,
    required String type,
    required DateTime occurredAt,
    required DateTime createdAt,
    this.locationLat = const Value.absent(),
    this.locationLng = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       branchId = Value(branchId),
       accountId = Value(accountId),
       recordId = Value(recordId),
       employeeId = Value(employeeId),
       type = Value(type),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt),
       sortOrder = Value(sortOrder);
  static Insertable<AttendanceRecordCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<String>? accountId,
    Expression<String>? recordId,
    Expression<String>? employeeId,
    Expression<String>? type,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
    Expression<double>? locationLat,
    Expression<double>? locationLng,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (accountId != null) 'account_id': accountId,
      if (recordId != null) 'record_id': recordId,
      if (employeeId != null) 'employee_id': employeeId,
      if (type != null) 'type': type,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceRecordCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<String>? accountId,
    Value<String>? recordId,
    Value<String>? employeeId,
    Value<String>? type,
    Value<DateTime>? occurredAt,
    Value<DateTime>? createdAt,
    Value<double?>? locationLat,
    Value<double?>? locationLng,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AttendanceRecordCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      accountId: accountId ?? this.accountId,
      recordId: recordId ?? this.recordId,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (locationLat.present) {
      map['location_lat'] = Variable<double>(locationLat.value);
    }
    if (locationLng.present) {
      map['location_lng'] = Variable<double>(locationLng.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('accountId: $accountId, ')
          ..write('recordId: $recordId, ')
          ..write('employeeId: $employeeId, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLng: $locationLng, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffShiftScopeEntriesTable extends StaffShiftScopeEntries
    with TableInfo<$StaffShiftScopeEntriesTable, StaffShiftScopeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffShiftScopeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _membershipIdMeta = const VerificationMeta(
    'membershipId',
  );
  @override
  late final GeneratedColumn<String> membershipId = GeneratedColumn<String>(
    'membership_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fromDateMeta = const VerificationMeta(
    'fromDate',
  );
  @override
  late final GeneratedColumn<String> fromDate = GeneratedColumn<String>(
    'from_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toDateMeta = const VerificationMeta('toDate');
  @override
  late final GeneratedColumn<String> toDate = GeneratedColumn<String>(
    'to_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    scopeKey,
    branchId,
    membershipId,
    fromDate,
    toDate,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_shift_scope_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffShiftScopeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('membership_id')) {
      context.handle(
        _membershipIdMeta,
        membershipId.isAcceptableOrUnknown(
          data['membership_id']!,
          _membershipIdMeta,
        ),
      );
    }
    if (data.containsKey('from_date')) {
      context.handle(
        _fromDateMeta,
        fromDate.isAcceptableOrUnknown(data['from_date']!, _fromDateMeta),
      );
    } else if (isInserting) {
      context.missing(_fromDateMeta);
    }
    if (data.containsKey('to_date')) {
      context.handle(
        _toDateMeta,
        toDate.isAcceptableOrUnknown(data['to_date']!, _toDateMeta),
      );
    } else if (isInserting) {
      context.missing(_toDateMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, scopeKey};
  @override
  StaffShiftScopeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffShiftScopeEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      membershipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}membership_id'],
      )!,
      fromDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_date'],
      )!,
      toDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_date'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $StaffShiftScopeEntriesTable createAlias(String alias) {
    return $StaffShiftScopeEntriesTable(attachedDatabase, alias);
  }
}

class StaffShiftScopeEntry extends DataClass
    implements Insertable<StaffShiftScopeEntry> {
  final String tenantId;
  final String scopeKey;
  final String branchId;
  final String membershipId;
  final String fromDate;
  final String toDate;
  final DateTime cachedAt;
  const StaffShiftScopeEntry({
    required this.tenantId,
    required this.scopeKey,
    required this.branchId,
    required this.membershipId,
    required this.fromDate,
    required this.toDate,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['branch_id'] = Variable<String>(branchId);
    map['membership_id'] = Variable<String>(membershipId);
    map['from_date'] = Variable<String>(fromDate);
    map['to_date'] = Variable<String>(toDate);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  StaffShiftScopeEntriesCompanion toCompanion(bool nullToAbsent) {
    return StaffShiftScopeEntriesCompanion(
      tenantId: Value(tenantId),
      scopeKey: Value(scopeKey),
      branchId: Value(branchId),
      membershipId: Value(membershipId),
      fromDate: Value(fromDate),
      toDate: Value(toDate),
      cachedAt: Value(cachedAt),
    );
  }

  factory StaffShiftScopeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffShiftScopeEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      branchId: serializer.fromJson<String>(json['branchId']),
      membershipId: serializer.fromJson<String>(json['membershipId']),
      fromDate: serializer.fromJson<String>(json['fromDate']),
      toDate: serializer.fromJson<String>(json['toDate']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'branchId': serializer.toJson<String>(branchId),
      'membershipId': serializer.toJson<String>(membershipId),
      'fromDate': serializer.toJson<String>(fromDate),
      'toDate': serializer.toJson<String>(toDate),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  StaffShiftScopeEntry copyWith({
    String? tenantId,
    String? scopeKey,
    String? branchId,
    String? membershipId,
    String? fromDate,
    String? toDate,
    DateTime? cachedAt,
  }) => StaffShiftScopeEntry(
    tenantId: tenantId ?? this.tenantId,
    scopeKey: scopeKey ?? this.scopeKey,
    branchId: branchId ?? this.branchId,
    membershipId: membershipId ?? this.membershipId,
    fromDate: fromDate ?? this.fromDate,
    toDate: toDate ?? this.toDate,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  StaffShiftScopeEntry copyWithCompanion(StaffShiftScopeEntriesCompanion data) {
    return StaffShiftScopeEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      membershipId: data.membershipId.present
          ? data.membershipId.value
          : this.membershipId,
      fromDate: data.fromDate.present ? data.fromDate.value : this.fromDate,
      toDate: data.toDate.present ? data.toDate.value : this.toDate,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftScopeEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('branchId: $branchId, ')
          ..write('membershipId: $membershipId, ')
          ..write('fromDate: $fromDate, ')
          ..write('toDate: $toDate, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    scopeKey,
    branchId,
    membershipId,
    fromDate,
    toDate,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffShiftScopeEntry &&
          other.tenantId == this.tenantId &&
          other.scopeKey == this.scopeKey &&
          other.branchId == this.branchId &&
          other.membershipId == this.membershipId &&
          other.fromDate == this.fromDate &&
          other.toDate == this.toDate &&
          other.cachedAt == this.cachedAt);
}

class StaffShiftScopeEntriesCompanion
    extends UpdateCompanion<StaffShiftScopeEntry> {
  final Value<String> tenantId;
  final Value<String> scopeKey;
  final Value<String> branchId;
  final Value<String> membershipId;
  final Value<String> fromDate;
  final Value<String> toDate;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const StaffShiftScopeEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.branchId = const Value.absent(),
    this.membershipId = const Value.absent(),
    this.fromDate = const Value.absent(),
    this.toDate = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffShiftScopeEntriesCompanion.insert({
    required String tenantId,
    required String scopeKey,
    required String branchId,
    this.membershipId = const Value.absent(),
    required String fromDate,
    required String toDate,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scopeKey = Value(scopeKey),
       branchId = Value(branchId),
       fromDate = Value(fromDate),
       toDate = Value(toDate),
       cachedAt = Value(cachedAt);
  static Insertable<StaffShiftScopeEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? scopeKey,
    Expression<String>? branchId,
    Expression<String>? membershipId,
    Expression<String>? fromDate,
    Expression<String>? toDate,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (branchId != null) 'branch_id': branchId,
      if (membershipId != null) 'membership_id': membershipId,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffShiftScopeEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scopeKey,
    Value<String>? branchId,
    Value<String>? membershipId,
    Value<String>? fromDate,
    Value<String>? toDate,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return StaffShiftScopeEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      scopeKey: scopeKey ?? this.scopeKey,
      branchId: branchId ?? this.branchId,
      membershipId: membershipId ?? this.membershipId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (membershipId.present) {
      map['membership_id'] = Variable<String>(membershipId.value);
    }
    if (fromDate.present) {
      map['from_date'] = Variable<String>(fromDate.value);
    }
    if (toDate.present) {
      map['to_date'] = Variable<String>(toDate.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftScopeEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('branchId: $branchId, ')
          ..write('membershipId: $membershipId, ')
          ..write('fromDate: $fromDate, ')
          ..write('toDate: $toDate, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffShiftBranchCacheEntriesTable extends StaffShiftBranchCacheEntries
    with
        TableInfo<
          $StaffShiftBranchCacheEntriesTable,
          StaffShiftBranchCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffShiftBranchCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchNameMeta = const VerificationMeta(
    'branchName',
  );
  @override
  late final GeneratedColumn<String> branchName = GeneratedColumn<String>(
    'branch_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    branchId,
    sortOrder,
    branchName,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_shift_branch_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffShiftBranchCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('branch_name')) {
      context.handle(
        _branchNameMeta,
        branchName.isAcceptableOrUnknown(data['branch_name']!, _branchNameMeta),
      );
    } else if (isInserting) {
      context.missing(_branchNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, branchId};
  @override
  StaffShiftBranchCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffShiftBranchCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      branchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $StaffShiftBranchCacheEntriesTable createAlias(String alias) {
    return $StaffShiftBranchCacheEntriesTable(attachedDatabase, alias);
  }
}

class StaffShiftBranchCacheEntry extends DataClass
    implements Insertable<StaffShiftBranchCacheEntry> {
  final String tenantId;
  final String branchId;
  final int sortOrder;
  final String branchName;
  final String status;
  const StaffShiftBranchCacheEntry({
    required this.tenantId,
    required this.branchId,
    required this.sortOrder,
    required this.branchName,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['branch_id'] = Variable<String>(branchId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['branch_name'] = Variable<String>(branchName);
    map['status'] = Variable<String>(status);
    return map;
  }

  StaffShiftBranchCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return StaffShiftBranchCacheEntriesCompanion(
      tenantId: Value(tenantId),
      branchId: Value(branchId),
      sortOrder: Value(sortOrder),
      branchName: Value(branchName),
      status: Value(status),
    );
  }

  factory StaffShiftBranchCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffShiftBranchCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      branchName: serializer.fromJson<String>(json['branchName']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'branchId': serializer.toJson<String>(branchId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'branchName': serializer.toJson<String>(branchName),
      'status': serializer.toJson<String>(status),
    };
  }

  StaffShiftBranchCacheEntry copyWith({
    String? tenantId,
    String? branchId,
    int? sortOrder,
    String? branchName,
    String? status,
  }) => StaffShiftBranchCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    branchId: branchId ?? this.branchId,
    sortOrder: sortOrder ?? this.sortOrder,
    branchName: branchName ?? this.branchName,
    status: status ?? this.status,
  );
  StaffShiftBranchCacheEntry copyWithCompanion(
    StaffShiftBranchCacheEntriesCompanion data,
  ) {
    return StaffShiftBranchCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      branchName: data.branchName.present
          ? data.branchName.value
          : this.branchName,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftBranchCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('branchName: $branchName, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, branchId, sortOrder, branchName, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffShiftBranchCacheEntry &&
          other.tenantId == this.tenantId &&
          other.branchId == this.branchId &&
          other.sortOrder == this.sortOrder &&
          other.branchName == this.branchName &&
          other.status == this.status);
}

class StaffShiftBranchCacheEntriesCompanion
    extends UpdateCompanion<StaffShiftBranchCacheEntry> {
  final Value<String> tenantId;
  final Value<String> branchId;
  final Value<int> sortOrder;
  final Value<String> branchName;
  final Value<String> status;
  final Value<int> rowid;
  const StaffShiftBranchCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.branchName = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffShiftBranchCacheEntriesCompanion.insert({
    required String tenantId,
    required String branchId,
    required int sortOrder,
    required String branchName,
    required String status,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       branchId = Value(branchId),
       sortOrder = Value(sortOrder),
       branchName = Value(branchName),
       status = Value(status);
  static Insertable<StaffShiftBranchCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? branchId,
    Expression<int>? sortOrder,
    Expression<String>? branchName,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (branchId != null) 'branch_id': branchId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (branchName != null) 'branch_name': branchName,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffShiftBranchCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? branchId,
    Value<int>? sortOrder,
    Value<String>? branchName,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return StaffShiftBranchCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      sortOrder: sortOrder ?? this.sortOrder,
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (branchName.present) {
      map['branch_name'] = Variable<String>(branchName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftBranchCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('branchId: $branchId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('branchName: $branchName, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffShiftMembershipCacheEntriesTable
    extends StaffShiftMembershipCacheEntries
    with
        TableInfo<
          $StaffShiftMembershipCacheEntriesTable,
          StaffShiftMembershipCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffShiftMembershipCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _membershipIdMeta = const VerificationMeta(
    'membershipId',
  );
  @override
  late final GeneratedColumn<String> membershipId = GeneratedColumn<String>(
    'membership_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleKeyMeta = const VerificationMeta(
    'roleKey',
  );
  @override
  late final GeneratedColumn<String> roleKey = GeneratedColumn<String>(
    'role_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _membershipStatusMeta = const VerificationMeta(
    'membershipStatus',
  );
  @override
  late final GeneratedColumn<String> membershipStatus = GeneratedColumn<String>(
    'membership_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _staffProfileStatusMeta =
      const VerificationMeta('staffProfileStatus');
  @override
  late final GeneratedColumn<String> staffProfileStatus =
      GeneratedColumn<String>(
        'staff_profile_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _invitedAtMeta = const VerificationMeta(
    'invitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> invitedAt = GeneratedColumn<DateTime>(
    'invited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acceptedAtMeta = const VerificationMeta(
    'acceptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acceptedAt = GeneratedColumn<DateTime>(
    'accepted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rejectedAtMeta = const VerificationMeta(
    'rejectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> rejectedAt = GeneratedColumn<DateTime>(
    'rejected_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingBranchIdsJsonMeta =
      const VerificationMeta('pendingBranchIdsJson');
  @override
  late final GeneratedColumn<String> pendingBranchIdsJson =
      GeneratedColumn<String>(
        'pending_branch_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _activeBranchIdsJsonMeta =
      const VerificationMeta('activeBranchIdsJson');
  @override
  late final GeneratedColumn<String> activeBranchIdsJson =
      GeneratedColumn<String>(
        'active_branch_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    membershipId,
    sortOrder,
    accountId,
    roleKey,
    membershipStatus,
    phone,
    firstName,
    lastName,
    staffProfileStatus,
    invitedAt,
    acceptedAt,
    rejectedAt,
    revokedAt,
    pendingBranchIdsJson,
    activeBranchIdsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_shift_membership_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffShiftMembershipCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('membership_id')) {
      context.handle(
        _membershipIdMeta,
        membershipId.isAcceptableOrUnknown(
          data['membership_id']!,
          _membershipIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_membershipIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('role_key')) {
      context.handle(
        _roleKeyMeta,
        roleKey.isAcceptableOrUnknown(data['role_key']!, _roleKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_roleKeyMeta);
    }
    if (data.containsKey('membership_status')) {
      context.handle(
        _membershipStatusMeta,
        membershipStatus.isAcceptableOrUnknown(
          data['membership_status']!,
          _membershipStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_membershipStatusMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('staff_profile_status')) {
      context.handle(
        _staffProfileStatusMeta,
        staffProfileStatus.isAcceptableOrUnknown(
          data['staff_profile_status']!,
          _staffProfileStatusMeta,
        ),
      );
    }
    if (data.containsKey('invited_at')) {
      context.handle(
        _invitedAtMeta,
        invitedAt.isAcceptableOrUnknown(data['invited_at']!, _invitedAtMeta),
      );
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
        _acceptedAtMeta,
        acceptedAt.isAcceptableOrUnknown(data['accepted_at']!, _acceptedAtMeta),
      );
    }
    if (data.containsKey('rejected_at')) {
      context.handle(
        _rejectedAtMeta,
        rejectedAt.isAcceptableOrUnknown(data['rejected_at']!, _rejectedAtMeta),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    if (data.containsKey('pending_branch_ids_json')) {
      context.handle(
        _pendingBranchIdsJsonMeta,
        pendingBranchIdsJson.isAcceptableOrUnknown(
          data['pending_branch_ids_json']!,
          _pendingBranchIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pendingBranchIdsJsonMeta);
    }
    if (data.containsKey('active_branch_ids_json')) {
      context.handle(
        _activeBranchIdsJsonMeta,
        activeBranchIdsJson.isAcceptableOrUnknown(
          data['active_branch_ids_json']!,
          _activeBranchIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activeBranchIdsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, membershipId};
  @override
  StaffShiftMembershipCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffShiftMembershipCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      membershipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}membership_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      roleKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_key'],
      )!,
      membershipStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}membership_status'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      staffProfileStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_profile_status'],
      ),
      invitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}invited_at'],
      ),
      acceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}accepted_at'],
      ),
      rejectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rejected_at'],
      ),
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
      pendingBranchIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_branch_ids_json'],
      )!,
      activeBranchIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_branch_ids_json'],
      )!,
    );
  }

  @override
  $StaffShiftMembershipCacheEntriesTable createAlias(String alias) {
    return $StaffShiftMembershipCacheEntriesTable(attachedDatabase, alias);
  }
}

class StaffShiftMembershipCacheEntry extends DataClass
    implements Insertable<StaffShiftMembershipCacheEntry> {
  final String tenantId;
  final String membershipId;
  final int sortOrder;
  final String accountId;
  final String roleKey;
  final String membershipStatus;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? staffProfileStatus;
  final DateTime? invitedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? revokedAt;
  final String pendingBranchIdsJson;
  final String activeBranchIdsJson;
  const StaffShiftMembershipCacheEntry({
    required this.tenantId,
    required this.membershipId,
    required this.sortOrder,
    required this.accountId,
    required this.roleKey,
    required this.membershipStatus,
    required this.phone,
    this.firstName,
    this.lastName,
    this.staffProfileStatus,
    this.invitedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.revokedAt,
    required this.pendingBranchIdsJson,
    required this.activeBranchIdsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['membership_id'] = Variable<String>(membershipId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['account_id'] = Variable<String>(accountId);
    map['role_key'] = Variable<String>(roleKey);
    map['membership_status'] = Variable<String>(membershipStatus);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = Variable<String>(firstName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    if (!nullToAbsent || staffProfileStatus != null) {
      map['staff_profile_status'] = Variable<String>(staffProfileStatus);
    }
    if (!nullToAbsent || invitedAt != null) {
      map['invited_at'] = Variable<DateTime>(invitedAt);
    }
    if (!nullToAbsent || acceptedAt != null) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt);
    }
    if (!nullToAbsent || rejectedAt != null) {
      map['rejected_at'] = Variable<DateTime>(rejectedAt);
    }
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    map['pending_branch_ids_json'] = Variable<String>(pendingBranchIdsJson);
    map['active_branch_ids_json'] = Variable<String>(activeBranchIdsJson);
    return map;
  }

  StaffShiftMembershipCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return StaffShiftMembershipCacheEntriesCompanion(
      tenantId: Value(tenantId),
      membershipId: Value(membershipId),
      sortOrder: Value(sortOrder),
      accountId: Value(accountId),
      roleKey: Value(roleKey),
      membershipStatus: Value(membershipStatus),
      phone: Value(phone),
      firstName: firstName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      staffProfileStatus: staffProfileStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(staffProfileStatus),
      invitedAt: invitedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(invitedAt),
      acceptedAt: acceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedAt),
      rejectedAt: rejectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectedAt),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
      pendingBranchIdsJson: Value(pendingBranchIdsJson),
      activeBranchIdsJson: Value(activeBranchIdsJson),
    );
  }

  factory StaffShiftMembershipCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffShiftMembershipCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      membershipId: serializer.fromJson<String>(json['membershipId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      accountId: serializer.fromJson<String>(json['accountId']),
      roleKey: serializer.fromJson<String>(json['roleKey']),
      membershipStatus: serializer.fromJson<String>(json['membershipStatus']),
      phone: serializer.fromJson<String>(json['phone']),
      firstName: serializer.fromJson<String?>(json['firstName']),
      lastName: serializer.fromJson<String?>(json['lastName']),
      staffProfileStatus: serializer.fromJson<String?>(
        json['staffProfileStatus'],
      ),
      invitedAt: serializer.fromJson<DateTime?>(json['invitedAt']),
      acceptedAt: serializer.fromJson<DateTime?>(json['acceptedAt']),
      rejectedAt: serializer.fromJson<DateTime?>(json['rejectedAt']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
      pendingBranchIdsJson: serializer.fromJson<String>(
        json['pendingBranchIdsJson'],
      ),
      activeBranchIdsJson: serializer.fromJson<String>(
        json['activeBranchIdsJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'membershipId': serializer.toJson<String>(membershipId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'accountId': serializer.toJson<String>(accountId),
      'roleKey': serializer.toJson<String>(roleKey),
      'membershipStatus': serializer.toJson<String>(membershipStatus),
      'phone': serializer.toJson<String>(phone),
      'firstName': serializer.toJson<String?>(firstName),
      'lastName': serializer.toJson<String?>(lastName),
      'staffProfileStatus': serializer.toJson<String?>(staffProfileStatus),
      'invitedAt': serializer.toJson<DateTime?>(invitedAt),
      'acceptedAt': serializer.toJson<DateTime?>(acceptedAt),
      'rejectedAt': serializer.toJson<DateTime?>(rejectedAt),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
      'pendingBranchIdsJson': serializer.toJson<String>(pendingBranchIdsJson),
      'activeBranchIdsJson': serializer.toJson<String>(activeBranchIdsJson),
    };
  }

  StaffShiftMembershipCacheEntry copyWith({
    String? tenantId,
    String? membershipId,
    int? sortOrder,
    String? accountId,
    String? roleKey,
    String? membershipStatus,
    String? phone,
    Value<String?> firstName = const Value.absent(),
    Value<String?> lastName = const Value.absent(),
    Value<String?> staffProfileStatus = const Value.absent(),
    Value<DateTime?> invitedAt = const Value.absent(),
    Value<DateTime?> acceptedAt = const Value.absent(),
    Value<DateTime?> rejectedAt = const Value.absent(),
    Value<DateTime?> revokedAt = const Value.absent(),
    String? pendingBranchIdsJson,
    String? activeBranchIdsJson,
  }) => StaffShiftMembershipCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    membershipId: membershipId ?? this.membershipId,
    sortOrder: sortOrder ?? this.sortOrder,
    accountId: accountId ?? this.accountId,
    roleKey: roleKey ?? this.roleKey,
    membershipStatus: membershipStatus ?? this.membershipStatus,
    phone: phone ?? this.phone,
    firstName: firstName.present ? firstName.value : this.firstName,
    lastName: lastName.present ? lastName.value : this.lastName,
    staffProfileStatus: staffProfileStatus.present
        ? staffProfileStatus.value
        : this.staffProfileStatus,
    invitedAt: invitedAt.present ? invitedAt.value : this.invitedAt,
    acceptedAt: acceptedAt.present ? acceptedAt.value : this.acceptedAt,
    rejectedAt: rejectedAt.present ? rejectedAt.value : this.rejectedAt,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
    pendingBranchIdsJson: pendingBranchIdsJson ?? this.pendingBranchIdsJson,
    activeBranchIdsJson: activeBranchIdsJson ?? this.activeBranchIdsJson,
  );
  StaffShiftMembershipCacheEntry copyWithCompanion(
    StaffShiftMembershipCacheEntriesCompanion data,
  ) {
    return StaffShiftMembershipCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      membershipId: data.membershipId.present
          ? data.membershipId.value
          : this.membershipId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      roleKey: data.roleKey.present ? data.roleKey.value : this.roleKey,
      membershipStatus: data.membershipStatus.present
          ? data.membershipStatus.value
          : this.membershipStatus,
      phone: data.phone.present ? data.phone.value : this.phone,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      staffProfileStatus: data.staffProfileStatus.present
          ? data.staffProfileStatus.value
          : this.staffProfileStatus,
      invitedAt: data.invitedAt.present ? data.invitedAt.value : this.invitedAt,
      acceptedAt: data.acceptedAt.present
          ? data.acceptedAt.value
          : this.acceptedAt,
      rejectedAt: data.rejectedAt.present
          ? data.rejectedAt.value
          : this.rejectedAt,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
      pendingBranchIdsJson: data.pendingBranchIdsJson.present
          ? data.pendingBranchIdsJson.value
          : this.pendingBranchIdsJson,
      activeBranchIdsJson: data.activeBranchIdsJson.present
          ? data.activeBranchIdsJson.value
          : this.activeBranchIdsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftMembershipCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('membershipId: $membershipId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('accountId: $accountId, ')
          ..write('roleKey: $roleKey, ')
          ..write('membershipStatus: $membershipStatus, ')
          ..write('phone: $phone, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('staffProfileStatus: $staffProfileStatus, ')
          ..write('invitedAt: $invitedAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('rejectedAt: $rejectedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('pendingBranchIdsJson: $pendingBranchIdsJson, ')
          ..write('activeBranchIdsJson: $activeBranchIdsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    membershipId,
    sortOrder,
    accountId,
    roleKey,
    membershipStatus,
    phone,
    firstName,
    lastName,
    staffProfileStatus,
    invitedAt,
    acceptedAt,
    rejectedAt,
    revokedAt,
    pendingBranchIdsJson,
    activeBranchIdsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffShiftMembershipCacheEntry &&
          other.tenantId == this.tenantId &&
          other.membershipId == this.membershipId &&
          other.sortOrder == this.sortOrder &&
          other.accountId == this.accountId &&
          other.roleKey == this.roleKey &&
          other.membershipStatus == this.membershipStatus &&
          other.phone == this.phone &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.staffProfileStatus == this.staffProfileStatus &&
          other.invitedAt == this.invitedAt &&
          other.acceptedAt == this.acceptedAt &&
          other.rejectedAt == this.rejectedAt &&
          other.revokedAt == this.revokedAt &&
          other.pendingBranchIdsJson == this.pendingBranchIdsJson &&
          other.activeBranchIdsJson == this.activeBranchIdsJson);
}

class StaffShiftMembershipCacheEntriesCompanion
    extends UpdateCompanion<StaffShiftMembershipCacheEntry> {
  final Value<String> tenantId;
  final Value<String> membershipId;
  final Value<int> sortOrder;
  final Value<String> accountId;
  final Value<String> roleKey;
  final Value<String> membershipStatus;
  final Value<String> phone;
  final Value<String?> firstName;
  final Value<String?> lastName;
  final Value<String?> staffProfileStatus;
  final Value<DateTime?> invitedAt;
  final Value<DateTime?> acceptedAt;
  final Value<DateTime?> rejectedAt;
  final Value<DateTime?> revokedAt;
  final Value<String> pendingBranchIdsJson;
  final Value<String> activeBranchIdsJson;
  final Value<int> rowid;
  const StaffShiftMembershipCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.membershipId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.accountId = const Value.absent(),
    this.roleKey = const Value.absent(),
    this.membershipStatus = const Value.absent(),
    this.phone = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.staffProfileStatus = const Value.absent(),
    this.invitedAt = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.rejectedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.pendingBranchIdsJson = const Value.absent(),
    this.activeBranchIdsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffShiftMembershipCacheEntriesCompanion.insert({
    required String tenantId,
    required String membershipId,
    required int sortOrder,
    required String accountId,
    required String roleKey,
    required String membershipStatus,
    required String phone,
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.staffProfileStatus = const Value.absent(),
    this.invitedAt = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.rejectedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    required String pendingBranchIdsJson,
    required String activeBranchIdsJson,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       membershipId = Value(membershipId),
       sortOrder = Value(sortOrder),
       accountId = Value(accountId),
       roleKey = Value(roleKey),
       membershipStatus = Value(membershipStatus),
       phone = Value(phone),
       pendingBranchIdsJson = Value(pendingBranchIdsJson),
       activeBranchIdsJson = Value(activeBranchIdsJson);
  static Insertable<StaffShiftMembershipCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? membershipId,
    Expression<int>? sortOrder,
    Expression<String>? accountId,
    Expression<String>? roleKey,
    Expression<String>? membershipStatus,
    Expression<String>? phone,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? staffProfileStatus,
    Expression<DateTime>? invitedAt,
    Expression<DateTime>? acceptedAt,
    Expression<DateTime>? rejectedAt,
    Expression<DateTime>? revokedAt,
    Expression<String>? pendingBranchIdsJson,
    Expression<String>? activeBranchIdsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (membershipId != null) 'membership_id': membershipId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (accountId != null) 'account_id': accountId,
      if (roleKey != null) 'role_key': roleKey,
      if (membershipStatus != null) 'membership_status': membershipStatus,
      if (phone != null) 'phone': phone,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (staffProfileStatus != null)
        'staff_profile_status': staffProfileStatus,
      if (invitedAt != null) 'invited_at': invitedAt,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (rejectedAt != null) 'rejected_at': rejectedAt,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (pendingBranchIdsJson != null)
        'pending_branch_ids_json': pendingBranchIdsJson,
      if (activeBranchIdsJson != null)
        'active_branch_ids_json': activeBranchIdsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffShiftMembershipCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? membershipId,
    Value<int>? sortOrder,
    Value<String>? accountId,
    Value<String>? roleKey,
    Value<String>? membershipStatus,
    Value<String>? phone,
    Value<String?>? firstName,
    Value<String?>? lastName,
    Value<String?>? staffProfileStatus,
    Value<DateTime?>? invitedAt,
    Value<DateTime?>? acceptedAt,
    Value<DateTime?>? rejectedAt,
    Value<DateTime?>? revokedAt,
    Value<String>? pendingBranchIdsJson,
    Value<String>? activeBranchIdsJson,
    Value<int>? rowid,
  }) {
    return StaffShiftMembershipCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      membershipId: membershipId ?? this.membershipId,
      sortOrder: sortOrder ?? this.sortOrder,
      accountId: accountId ?? this.accountId,
      roleKey: roleKey ?? this.roleKey,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      staffProfileStatus: staffProfileStatus ?? this.staffProfileStatus,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      pendingBranchIdsJson: pendingBranchIdsJson ?? this.pendingBranchIdsJson,
      activeBranchIdsJson: activeBranchIdsJson ?? this.activeBranchIdsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (membershipId.present) {
      map['membership_id'] = Variable<String>(membershipId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (roleKey.present) {
      map['role_key'] = Variable<String>(roleKey.value);
    }
    if (membershipStatus.present) {
      map['membership_status'] = Variable<String>(membershipStatus.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (staffProfileStatus.present) {
      map['staff_profile_status'] = Variable<String>(staffProfileStatus.value);
    }
    if (invitedAt.present) {
      map['invited_at'] = Variable<DateTime>(invitedAt.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt.value);
    }
    if (rejectedAt.present) {
      map['rejected_at'] = Variable<DateTime>(rejectedAt.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (pendingBranchIdsJson.present) {
      map['pending_branch_ids_json'] = Variable<String>(
        pendingBranchIdsJson.value,
      );
    }
    if (activeBranchIdsJson.present) {
      map['active_branch_ids_json'] = Variable<String>(
        activeBranchIdsJson.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftMembershipCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('membershipId: $membershipId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('accountId: $accountId, ')
          ..write('roleKey: $roleKey, ')
          ..write('membershipStatus: $membershipStatus, ')
          ..write('phone: $phone, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('staffProfileStatus: $staffProfileStatus, ')
          ..write('invitedAt: $invitedAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('rejectedAt: $rejectedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('pendingBranchIdsJson: $pendingBranchIdsJson, ')
          ..write('activeBranchIdsJson: $activeBranchIdsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffShiftPatternCacheEntriesTable extends StaffShiftPatternCacheEntries
    with
        TableInfo<
          $StaffShiftPatternCacheEntriesTable,
          StaffShiftPatternCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffShiftPatternCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternIdMeta = const VerificationMeta(
    'patternId',
  );
  @override
  late final GeneratedColumn<String> patternId = GeneratedColumn<String>(
    'pattern_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _membershipIdMeta = const VerificationMeta(
    'membershipId',
  );
  @override
  late final GeneratedColumn<String> membershipId = GeneratedColumn<String>(
    'membership_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysOfWeekJsonMeta = const VerificationMeta(
    'daysOfWeekJson',
  );
  @override
  late final GeneratedColumn<String> daysOfWeekJson = GeneratedColumn<String>(
    'days_of_week_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedStartTimeMeta = const VerificationMeta(
    'plannedStartTime',
  );
  @override
  late final GeneratedColumn<String> plannedStartTime = GeneratedColumn<String>(
    'planned_start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedEndTimeMeta = const VerificationMeta(
    'plannedEndTime',
  );
  @override
  late final GeneratedColumn<String> plannedEndTime = GeneratedColumn<String>(
    'planned_end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveFrom =
      GeneratedColumn<DateTime>(
        'effective_from',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _effectiveToMeta = const VerificationMeta(
    'effectiveTo',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveTo = GeneratedColumn<DateTime>(
    'effective_to',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    scopeKey,
    patternId,
    sortOrder,
    membershipId,
    branchId,
    daysOfWeekJson,
    plannedStartTime,
    plannedEndTime,
    status,
    effectiveFrom,
    effectiveTo,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_shift_pattern_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffShiftPatternCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('pattern_id')) {
      context.handle(
        _patternIdMeta,
        patternId.isAcceptableOrUnknown(data['pattern_id']!, _patternIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patternIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('membership_id')) {
      context.handle(
        _membershipIdMeta,
        membershipId.isAcceptableOrUnknown(
          data['membership_id']!,
          _membershipIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_membershipIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('days_of_week_json')) {
      context.handle(
        _daysOfWeekJsonMeta,
        daysOfWeekJson.isAcceptableOrUnknown(
          data['days_of_week_json']!,
          _daysOfWeekJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_daysOfWeekJsonMeta);
    }
    if (data.containsKey('planned_start_time')) {
      context.handle(
        _plannedStartTimeMeta,
        plannedStartTime.isAcceptableOrUnknown(
          data['planned_start_time']!,
          _plannedStartTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedStartTimeMeta);
    }
    if (data.containsKey('planned_end_time')) {
      context.handle(
        _plannedEndTimeMeta,
        plannedEndTime.isAcceptableOrUnknown(
          data['planned_end_time']!,
          _plannedEndTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedEndTimeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    }
    if (data.containsKey('effective_to')) {
      context.handle(
        _effectiveToMeta,
        effectiveTo.isAcceptableOrUnknown(
          data['effective_to']!,
          _effectiveToMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, scopeKey, patternId};
  @override
  StaffShiftPatternCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffShiftPatternCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      patternId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      membershipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}membership_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      daysOfWeekJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days_of_week_json'],
      )!,
      plannedStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_start_time'],
      )!,
      plannedEndTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_end_time'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_from'],
      ),
      effectiveTo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_to'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StaffShiftPatternCacheEntriesTable createAlias(String alias) {
    return $StaffShiftPatternCacheEntriesTable(attachedDatabase, alias);
  }
}

class StaffShiftPatternCacheEntry extends DataClass
    implements Insertable<StaffShiftPatternCacheEntry> {
  final String tenantId;
  final String scopeKey;
  final String patternId;
  final int sortOrder;
  final String membershipId;
  final String branchId;
  final String daysOfWeekJson;
  final String plannedStartTime;
  final String plannedEndTime;
  final String status;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StaffShiftPatternCacheEntry({
    required this.tenantId,
    required this.scopeKey,
    required this.patternId,
    required this.sortOrder,
    required this.membershipId,
    required this.branchId,
    required this.daysOfWeekJson,
    required this.plannedStartTime,
    required this.plannedEndTime,
    required this.status,
    this.effectiveFrom,
    this.effectiveTo,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['pattern_id'] = Variable<String>(patternId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['membership_id'] = Variable<String>(membershipId);
    map['branch_id'] = Variable<String>(branchId);
    map['days_of_week_json'] = Variable<String>(daysOfWeekJson);
    map['planned_start_time'] = Variable<String>(plannedStartTime);
    map['planned_end_time'] = Variable<String>(plannedEndTime);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || effectiveFrom != null) {
      map['effective_from'] = Variable<DateTime>(effectiveFrom);
    }
    if (!nullToAbsent || effectiveTo != null) {
      map['effective_to'] = Variable<DateTime>(effectiveTo);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StaffShiftPatternCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return StaffShiftPatternCacheEntriesCompanion(
      tenantId: Value(tenantId),
      scopeKey: Value(scopeKey),
      patternId: Value(patternId),
      sortOrder: Value(sortOrder),
      membershipId: Value(membershipId),
      branchId: Value(branchId),
      daysOfWeekJson: Value(daysOfWeekJson),
      plannedStartTime: Value(plannedStartTime),
      plannedEndTime: Value(plannedEndTime),
      status: Value(status),
      effectiveFrom: effectiveFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveFrom),
      effectiveTo: effectiveTo == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveTo),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StaffShiftPatternCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffShiftPatternCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      patternId: serializer.fromJson<String>(json['patternId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      membershipId: serializer.fromJson<String>(json['membershipId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      daysOfWeekJson: serializer.fromJson<String>(json['daysOfWeekJson']),
      plannedStartTime: serializer.fromJson<String>(json['plannedStartTime']),
      plannedEndTime: serializer.fromJson<String>(json['plannedEndTime']),
      status: serializer.fromJson<String>(json['status']),
      effectiveFrom: serializer.fromJson<DateTime?>(json['effectiveFrom']),
      effectiveTo: serializer.fromJson<DateTime?>(json['effectiveTo']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'patternId': serializer.toJson<String>(patternId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'membershipId': serializer.toJson<String>(membershipId),
      'branchId': serializer.toJson<String>(branchId),
      'daysOfWeekJson': serializer.toJson<String>(daysOfWeekJson),
      'plannedStartTime': serializer.toJson<String>(plannedStartTime),
      'plannedEndTime': serializer.toJson<String>(plannedEndTime),
      'status': serializer.toJson<String>(status),
      'effectiveFrom': serializer.toJson<DateTime?>(effectiveFrom),
      'effectiveTo': serializer.toJson<DateTime?>(effectiveTo),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StaffShiftPatternCacheEntry copyWith({
    String? tenantId,
    String? scopeKey,
    String? patternId,
    int? sortOrder,
    String? membershipId,
    String? branchId,
    String? daysOfWeekJson,
    String? plannedStartTime,
    String? plannedEndTime,
    String? status,
    Value<DateTime?> effectiveFrom = const Value.absent(),
    Value<DateTime?> effectiveTo = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StaffShiftPatternCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    scopeKey: scopeKey ?? this.scopeKey,
    patternId: patternId ?? this.patternId,
    sortOrder: sortOrder ?? this.sortOrder,
    membershipId: membershipId ?? this.membershipId,
    branchId: branchId ?? this.branchId,
    daysOfWeekJson: daysOfWeekJson ?? this.daysOfWeekJson,
    plannedStartTime: plannedStartTime ?? this.plannedStartTime,
    plannedEndTime: plannedEndTime ?? this.plannedEndTime,
    status: status ?? this.status,
    effectiveFrom: effectiveFrom.present
        ? effectiveFrom.value
        : this.effectiveFrom,
    effectiveTo: effectiveTo.present ? effectiveTo.value : this.effectiveTo,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StaffShiftPatternCacheEntry copyWithCompanion(
    StaffShiftPatternCacheEntriesCompanion data,
  ) {
    return StaffShiftPatternCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      patternId: data.patternId.present ? data.patternId.value : this.patternId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      membershipId: data.membershipId.present
          ? data.membershipId.value
          : this.membershipId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      daysOfWeekJson: data.daysOfWeekJson.present
          ? data.daysOfWeekJson.value
          : this.daysOfWeekJson,
      plannedStartTime: data.plannedStartTime.present
          ? data.plannedStartTime.value
          : this.plannedStartTime,
      plannedEndTime: data.plannedEndTime.present
          ? data.plannedEndTime.value
          : this.plannedEndTime,
      status: data.status.present ? data.status.value : this.status,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      effectiveTo: data.effectiveTo.present
          ? data.effectiveTo.value
          : this.effectiveTo,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftPatternCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('patternId: $patternId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('membershipId: $membershipId, ')
          ..write('branchId: $branchId, ')
          ..write('daysOfWeekJson: $daysOfWeekJson, ')
          ..write('plannedStartTime: $plannedStartTime, ')
          ..write('plannedEndTime: $plannedEndTime, ')
          ..write('status: $status, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveTo: $effectiveTo, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    scopeKey,
    patternId,
    sortOrder,
    membershipId,
    branchId,
    daysOfWeekJson,
    plannedStartTime,
    plannedEndTime,
    status,
    effectiveFrom,
    effectiveTo,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffShiftPatternCacheEntry &&
          other.tenantId == this.tenantId &&
          other.scopeKey == this.scopeKey &&
          other.patternId == this.patternId &&
          other.sortOrder == this.sortOrder &&
          other.membershipId == this.membershipId &&
          other.branchId == this.branchId &&
          other.daysOfWeekJson == this.daysOfWeekJson &&
          other.plannedStartTime == this.plannedStartTime &&
          other.plannedEndTime == this.plannedEndTime &&
          other.status == this.status &&
          other.effectiveFrom == this.effectiveFrom &&
          other.effectiveTo == this.effectiveTo &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StaffShiftPatternCacheEntriesCompanion
    extends UpdateCompanion<StaffShiftPatternCacheEntry> {
  final Value<String> tenantId;
  final Value<String> scopeKey;
  final Value<String> patternId;
  final Value<int> sortOrder;
  final Value<String> membershipId;
  final Value<String> branchId;
  final Value<String> daysOfWeekJson;
  final Value<String> plannedStartTime;
  final Value<String> plannedEndTime;
  final Value<String> status;
  final Value<DateTime?> effectiveFrom;
  final Value<DateTime?> effectiveTo;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StaffShiftPatternCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.patternId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.membershipId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.daysOfWeekJson = const Value.absent(),
    this.plannedStartTime = const Value.absent(),
    this.plannedEndTime = const Value.absent(),
    this.status = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.effectiveTo = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffShiftPatternCacheEntriesCompanion.insert({
    required String tenantId,
    required String scopeKey,
    required String patternId,
    required int sortOrder,
    required String membershipId,
    required String branchId,
    required String daysOfWeekJson,
    required String plannedStartTime,
    required String plannedEndTime,
    required String status,
    this.effectiveFrom = const Value.absent(),
    this.effectiveTo = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scopeKey = Value(scopeKey),
       patternId = Value(patternId),
       sortOrder = Value(sortOrder),
       membershipId = Value(membershipId),
       branchId = Value(branchId),
       daysOfWeekJson = Value(daysOfWeekJson),
       plannedStartTime = Value(plannedStartTime),
       plannedEndTime = Value(plannedEndTime),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StaffShiftPatternCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? scopeKey,
    Expression<String>? patternId,
    Expression<int>? sortOrder,
    Expression<String>? membershipId,
    Expression<String>? branchId,
    Expression<String>? daysOfWeekJson,
    Expression<String>? plannedStartTime,
    Expression<String>? plannedEndTime,
    Expression<String>? status,
    Expression<DateTime>? effectiveFrom,
    Expression<DateTime>? effectiveTo,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (patternId != null) 'pattern_id': patternId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (membershipId != null) 'membership_id': membershipId,
      if (branchId != null) 'branch_id': branchId,
      if (daysOfWeekJson != null) 'days_of_week_json': daysOfWeekJson,
      if (plannedStartTime != null) 'planned_start_time': plannedStartTime,
      if (plannedEndTime != null) 'planned_end_time': plannedEndTime,
      if (status != null) 'status': status,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (effectiveTo != null) 'effective_to': effectiveTo,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffShiftPatternCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scopeKey,
    Value<String>? patternId,
    Value<int>? sortOrder,
    Value<String>? membershipId,
    Value<String>? branchId,
    Value<String>? daysOfWeekJson,
    Value<String>? plannedStartTime,
    Value<String>? plannedEndTime,
    Value<String>? status,
    Value<DateTime?>? effectiveFrom,
    Value<DateTime?>? effectiveTo,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StaffShiftPatternCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      scopeKey: scopeKey ?? this.scopeKey,
      patternId: patternId ?? this.patternId,
      sortOrder: sortOrder ?? this.sortOrder,
      membershipId: membershipId ?? this.membershipId,
      branchId: branchId ?? this.branchId,
      daysOfWeekJson: daysOfWeekJson ?? this.daysOfWeekJson,
      plannedStartTime: plannedStartTime ?? this.plannedStartTime,
      plannedEndTime: plannedEndTime ?? this.plannedEndTime,
      status: status ?? this.status,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (patternId.present) {
      map['pattern_id'] = Variable<String>(patternId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (membershipId.present) {
      map['membership_id'] = Variable<String>(membershipId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (daysOfWeekJson.present) {
      map['days_of_week_json'] = Variable<String>(daysOfWeekJson.value);
    }
    if (plannedStartTime.present) {
      map['planned_start_time'] = Variable<String>(plannedStartTime.value);
    }
    if (plannedEndTime.present) {
      map['planned_end_time'] = Variable<String>(plannedEndTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<DateTime>(effectiveFrom.value);
    }
    if (effectiveTo.present) {
      map['effective_to'] = Variable<DateTime>(effectiveTo.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftPatternCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('patternId: $patternId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('membershipId: $membershipId, ')
          ..write('branchId: $branchId, ')
          ..write('daysOfWeekJson: $daysOfWeekJson, ')
          ..write('plannedStartTime: $plannedStartTime, ')
          ..write('plannedEndTime: $plannedEndTime, ')
          ..write('status: $status, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveTo: $effectiveTo, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StaffShiftInstanceCacheEntriesTable
    extends StaffShiftInstanceCacheEntries
    with
        TableInfo<
          $StaffShiftInstanceCacheEntriesTable,
          StaffShiftInstanceCacheEntry
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StaffShiftInstanceCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  @override
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _membershipIdMeta = const VerificationMeta(
    'membershipId',
  );
  @override
  late final GeneratedColumn<String> membershipId = GeneratedColumn<String>(
    'membership_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternIdMeta = const VerificationMeta(
    'patternId',
  );
  @override
  late final GeneratedColumn<String> patternId = GeneratedColumn<String>(
    'pattern_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedStartTimeMeta = const VerificationMeta(
    'plannedStartTime',
  );
  @override
  late final GeneratedColumn<String> plannedStartTime = GeneratedColumn<String>(
    'planned_start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedEndTimeMeta = const VerificationMeta(
    'plannedEndTime',
  );
  @override
  late final GeneratedColumn<String> plannedEndTime = GeneratedColumn<String>(
    'planned_end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    scopeKey,
    instanceId,
    sortOrder,
    membershipId,
    branchId,
    patternId,
    date,
    plannedStartTime,
    plannedEndTime,
    status,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staff_shift_instance_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<StaffShiftInstanceCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('membership_id')) {
      context.handle(
        _membershipIdMeta,
        membershipId.isAcceptableOrUnknown(
          data['membership_id']!,
          _membershipIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_membershipIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('pattern_id')) {
      context.handle(
        _patternIdMeta,
        patternId.isAcceptableOrUnknown(data['pattern_id']!, _patternIdMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('planned_start_time')) {
      context.handle(
        _plannedStartTimeMeta,
        plannedStartTime.isAcceptableOrUnknown(
          data['planned_start_time']!,
          _plannedStartTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedStartTimeMeta);
    }
    if (data.containsKey('planned_end_time')) {
      context.handle(
        _plannedEndTimeMeta,
        plannedEndTime.isAcceptableOrUnknown(
          data['planned_end_time']!,
          _plannedEndTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedEndTimeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, scopeKey, instanceId};
  @override
  StaffShiftInstanceCacheEntry map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StaffShiftInstanceCacheEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      membershipId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}membership_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_id'],
      )!,
      patternId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern_id'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      plannedStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_start_time'],
      )!,
      plannedEndTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_end_time'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StaffShiftInstanceCacheEntriesTable createAlias(String alias) {
    return $StaffShiftInstanceCacheEntriesTable(attachedDatabase, alias);
  }
}

class StaffShiftInstanceCacheEntry extends DataClass
    implements Insertable<StaffShiftInstanceCacheEntry> {
  final String tenantId;
  final String scopeKey;
  final String instanceId;
  final int sortOrder;
  final String membershipId;
  final String branchId;
  final String? patternId;
  final DateTime date;
  final String plannedStartTime;
  final String plannedEndTime;
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StaffShiftInstanceCacheEntry({
    required this.tenantId,
    required this.scopeKey,
    required this.instanceId,
    required this.sortOrder,
    required this.membershipId,
    required this.branchId,
    this.patternId,
    required this.date,
    required this.plannedStartTime,
    required this.plannedEndTime,
    required this.status,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['instance_id'] = Variable<String>(instanceId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['membership_id'] = Variable<String>(membershipId);
    map['branch_id'] = Variable<String>(branchId);
    if (!nullToAbsent || patternId != null) {
      map['pattern_id'] = Variable<String>(patternId);
    }
    map['date'] = Variable<DateTime>(date);
    map['planned_start_time'] = Variable<String>(plannedStartTime);
    map['planned_end_time'] = Variable<String>(plannedEndTime);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StaffShiftInstanceCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return StaffShiftInstanceCacheEntriesCompanion(
      tenantId: Value(tenantId),
      scopeKey: Value(scopeKey),
      instanceId: Value(instanceId),
      sortOrder: Value(sortOrder),
      membershipId: Value(membershipId),
      branchId: Value(branchId),
      patternId: patternId == null && nullToAbsent
          ? const Value.absent()
          : Value(patternId),
      date: Value(date),
      plannedStartTime: Value(plannedStartTime),
      plannedEndTime: Value(plannedEndTime),
      status: Value(status),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StaffShiftInstanceCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StaffShiftInstanceCacheEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      instanceId: serializer.fromJson<String>(json['instanceId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      membershipId: serializer.fromJson<String>(json['membershipId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      patternId: serializer.fromJson<String?>(json['patternId']),
      date: serializer.fromJson<DateTime>(json['date']),
      plannedStartTime: serializer.fromJson<String>(json['plannedStartTime']),
      plannedEndTime: serializer.fromJson<String>(json['plannedEndTime']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'instanceId': serializer.toJson<String>(instanceId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'membershipId': serializer.toJson<String>(membershipId),
      'branchId': serializer.toJson<String>(branchId),
      'patternId': serializer.toJson<String?>(patternId),
      'date': serializer.toJson<DateTime>(date),
      'plannedStartTime': serializer.toJson<String>(plannedStartTime),
      'plannedEndTime': serializer.toJson<String>(plannedEndTime),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StaffShiftInstanceCacheEntry copyWith({
    String? tenantId,
    String? scopeKey,
    String? instanceId,
    int? sortOrder,
    String? membershipId,
    String? branchId,
    Value<String?> patternId = const Value.absent(),
    DateTime? date,
    String? plannedStartTime,
    String? plannedEndTime,
    String? status,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StaffShiftInstanceCacheEntry(
    tenantId: tenantId ?? this.tenantId,
    scopeKey: scopeKey ?? this.scopeKey,
    instanceId: instanceId ?? this.instanceId,
    sortOrder: sortOrder ?? this.sortOrder,
    membershipId: membershipId ?? this.membershipId,
    branchId: branchId ?? this.branchId,
    patternId: patternId.present ? patternId.value : this.patternId,
    date: date ?? this.date,
    plannedStartTime: plannedStartTime ?? this.plannedStartTime,
    plannedEndTime: plannedEndTime ?? this.plannedEndTime,
    status: status ?? this.status,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StaffShiftInstanceCacheEntry copyWithCompanion(
    StaffShiftInstanceCacheEntriesCompanion data,
  ) {
    return StaffShiftInstanceCacheEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      membershipId: data.membershipId.present
          ? data.membershipId.value
          : this.membershipId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      patternId: data.patternId.present ? data.patternId.value : this.patternId,
      date: data.date.present ? data.date.value : this.date,
      plannedStartTime: data.plannedStartTime.present
          ? data.plannedStartTime.value
          : this.plannedStartTime,
      plannedEndTime: data.plannedEndTime.present
          ? data.plannedEndTime.value
          : this.plannedEndTime,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftInstanceCacheEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('membershipId: $membershipId, ')
          ..write('branchId: $branchId, ')
          ..write('patternId: $patternId, ')
          ..write('date: $date, ')
          ..write('plannedStartTime: $plannedStartTime, ')
          ..write('plannedEndTime: $plannedEndTime, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    scopeKey,
    instanceId,
    sortOrder,
    membershipId,
    branchId,
    patternId,
    date,
    plannedStartTime,
    plannedEndTime,
    status,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaffShiftInstanceCacheEntry &&
          other.tenantId == this.tenantId &&
          other.scopeKey == this.scopeKey &&
          other.instanceId == this.instanceId &&
          other.sortOrder == this.sortOrder &&
          other.membershipId == this.membershipId &&
          other.branchId == this.branchId &&
          other.patternId == this.patternId &&
          other.date == this.date &&
          other.plannedStartTime == this.plannedStartTime &&
          other.plannedEndTime == this.plannedEndTime &&
          other.status == this.status &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StaffShiftInstanceCacheEntriesCompanion
    extends UpdateCompanion<StaffShiftInstanceCacheEntry> {
  final Value<String> tenantId;
  final Value<String> scopeKey;
  final Value<String> instanceId;
  final Value<int> sortOrder;
  final Value<String> membershipId;
  final Value<String> branchId;
  final Value<String?> patternId;
  final Value<DateTime> date;
  final Value<String> plannedStartTime;
  final Value<String> plannedEndTime;
  final Value<String> status;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StaffShiftInstanceCacheEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.membershipId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.patternId = const Value.absent(),
    this.date = const Value.absent(),
    this.plannedStartTime = const Value.absent(),
    this.plannedEndTime = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StaffShiftInstanceCacheEntriesCompanion.insert({
    required String tenantId,
    required String scopeKey,
    required String instanceId,
    required int sortOrder,
    required String membershipId,
    required String branchId,
    this.patternId = const Value.absent(),
    required DateTime date,
    required String plannedStartTime,
    required String plannedEndTime,
    required String status,
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scopeKey = Value(scopeKey),
       instanceId = Value(instanceId),
       sortOrder = Value(sortOrder),
       membershipId = Value(membershipId),
       branchId = Value(branchId),
       date = Value(date),
       plannedStartTime = Value(plannedStartTime),
       plannedEndTime = Value(plannedEndTime),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StaffShiftInstanceCacheEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? scopeKey,
    Expression<String>? instanceId,
    Expression<int>? sortOrder,
    Expression<String>? membershipId,
    Expression<String>? branchId,
    Expression<String>? patternId,
    Expression<DateTime>? date,
    Expression<String>? plannedStartTime,
    Expression<String>? plannedEndTime,
    Expression<String>? status,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (instanceId != null) 'instance_id': instanceId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (membershipId != null) 'membership_id': membershipId,
      if (branchId != null) 'branch_id': branchId,
      if (patternId != null) 'pattern_id': patternId,
      if (date != null) 'date': date,
      if (plannedStartTime != null) 'planned_start_time': plannedStartTime,
      if (plannedEndTime != null) 'planned_end_time': plannedEndTime,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StaffShiftInstanceCacheEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scopeKey,
    Value<String>? instanceId,
    Value<int>? sortOrder,
    Value<String>? membershipId,
    Value<String>? branchId,
    Value<String?>? patternId,
    Value<DateTime>? date,
    Value<String>? plannedStartTime,
    Value<String>? plannedEndTime,
    Value<String>? status,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StaffShiftInstanceCacheEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      scopeKey: scopeKey ?? this.scopeKey,
      instanceId: instanceId ?? this.instanceId,
      sortOrder: sortOrder ?? this.sortOrder,
      membershipId: membershipId ?? this.membershipId,
      branchId: branchId ?? this.branchId,
      patternId: patternId ?? this.patternId,
      date: date ?? this.date,
      plannedStartTime: plannedStartTime ?? this.plannedStartTime,
      plannedEndTime: plannedEndTime ?? this.plannedEndTime,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (membershipId.present) {
      map['membership_id'] = Variable<String>(membershipId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (patternId.present) {
      map['pattern_id'] = Variable<String>(patternId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (plannedStartTime.present) {
      map['planned_start_time'] = Variable<String>(plannedStartTime.value);
    }
    if (plannedEndTime.present) {
      map['planned_end_time'] = Variable<String>(plannedEndTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StaffShiftInstanceCacheEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('membershipId: $membershipId, ')
          ..write('branchId: $branchId, ')
          ..write('patternId: $patternId, ')
          ..write('date: $date, ')
          ..write('plannedStartTime: $plannedStartTime, ')
          ..write('plannedEndTime: $plannedEndTime, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncCheckpointEntriesTable syncCheckpointEntries =
      $SyncCheckpointEntriesTable(this);
  late final $OfflineCommandQueueEntriesTable offlineCommandQueueEntries =
      $OfflineCommandQueueEntriesTable(this);
  late final $SaleOutageOrderEntriesTable saleOutageOrderEntries =
      $SaleOutageOrderEntriesTable(this);
  late final $PolicyCacheEntriesTable policyCacheEntries =
      $PolicyCacheEntriesTable(this);
  late final $CashSessionSnapshotEntriesTable cashSessionSnapshotEntries =
      $CashSessionSnapshotEntriesTable(this);
  late final $CashSessionMovementCacheEntriesTable
  cashSessionMovementCacheEntries = $CashSessionMovementCacheEntriesTable(this);
  late final $CashSessionSaleCacheEntriesTable cashSessionSaleCacheEntries =
      $CashSessionSaleCacheEntriesTable(this);
  late final $MenuCacheScopesTable menuCacheScopes = $MenuCacheScopesTable(
    this,
  );
  late final $MenuItemCacheEntriesTable menuItemCacheEntries =
      $MenuItemCacheEntriesTable(this);
  late final $MenuCategoryCacheEntriesTable menuCategoryCacheEntries =
      $MenuCategoryCacheEntriesTable(this);
  late final $MenuModifierGroupCacheEntriesTable menuModifierGroupCacheEntries =
      $MenuModifierGroupCacheEntriesTable(this);
  late final $MenuBranchCacheEntriesTable menuBranchCacheEntries =
      $MenuBranchCacheEntriesTable(this);
  late final $AttendanceContextCacheEntriesTable attendanceContextCacheEntries =
      $AttendanceContextCacheEntriesTable(this);
  late final $AttendanceRecordCacheEntriesTable attendanceRecordCacheEntries =
      $AttendanceRecordCacheEntriesTable(this);
  late final $StaffShiftScopeEntriesTable staffShiftScopeEntries =
      $StaffShiftScopeEntriesTable(this);
  late final $StaffShiftBranchCacheEntriesTable staffShiftBranchCacheEntries =
      $StaffShiftBranchCacheEntriesTable(this);
  late final $StaffShiftMembershipCacheEntriesTable
  staffShiftMembershipCacheEntries = $StaffShiftMembershipCacheEntriesTable(
    this,
  );
  late final $StaffShiftPatternCacheEntriesTable staffShiftPatternCacheEntries =
      $StaffShiftPatternCacheEntriesTable(this);
  late final $StaffShiftInstanceCacheEntriesTable
  staffShiftInstanceCacheEntries = $StaffShiftInstanceCacheEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syncCheckpointEntries,
    offlineCommandQueueEntries,
    saleOutageOrderEntries,
    policyCacheEntries,
    cashSessionSnapshotEntries,
    cashSessionMovementCacheEntries,
    cashSessionSaleCacheEntries,
    menuCacheScopes,
    menuItemCacheEntries,
    menuCategoryCacheEntries,
    menuModifierGroupCacheEntries,
    menuBranchCacheEntries,
    attendanceContextCacheEntries,
    attendanceRecordCacheEntries,
    staffShiftScopeEntries,
    staffShiftBranchCacheEntries,
    staffShiftMembershipCacheEntries,
    staffShiftPatternCacheEntries,
    staffShiftInstanceCacheEntries,
  ];
}

typedef $$SyncCheckpointEntriesTableCreateCompanionBuilder =
    SyncCheckpointEntriesCompanion Function({
      required String deviceId,
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> accountId,
      required String moduleScopeSetKey,
      Value<String?> cursor,
      Value<DateTime?> lastPullAt,
      Value<DateTime?> lastSuccessfulPullAt,
      Value<String?> lastPullStatus,
      Value<String?> lastErrorCode,
      Value<int> rowid,
    });
typedef $$SyncCheckpointEntriesTableUpdateCompanionBuilder =
    SyncCheckpointEntriesCompanion Function({
      Value<String> deviceId,
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> accountId,
      Value<String> moduleScopeSetKey,
      Value<String?> cursor,
      Value<DateTime?> lastPullAt,
      Value<DateTime?> lastSuccessfulPullAt,
      Value<String?> lastPullStatus,
      Value<String?> lastErrorCode,
      Value<int> rowid,
    });

class $$SyncCheckpointEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCheckpointEntriesTable> {
  $$SyncCheckpointEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moduleScopeSetKey => $composableBuilder(
    column: $table.moduleScopeSetKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessfulPullAt => $composableBuilder(
    column: $table.lastSuccessfulPullAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastPullStatus => $composableBuilder(
    column: $table.lastPullStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCheckpointEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCheckpointEntriesTable> {
  $$SyncCheckpointEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moduleScopeSetKey => $composableBuilder(
    column: $table.moduleScopeSetKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessfulPullAt => $composableBuilder(
    column: $table.lastSuccessfulPullAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastPullStatus => $composableBuilder(
    column: $table.lastPullStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCheckpointEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCheckpointEntriesTable> {
  $$SyncCheckpointEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get moduleScopeSetKey => $composableBuilder(
    column: $table.moduleScopeSetKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessfulPullAt => $composableBuilder(
    column: $table.lastSuccessfulPullAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastPullStatus => $composableBuilder(
    column: $table.lastPullStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );
}

class $$SyncCheckpointEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCheckpointEntriesTable,
          SyncCheckpointEntry,
          $$SyncCheckpointEntriesTableFilterComposer,
          $$SyncCheckpointEntriesTableOrderingComposer,
          $$SyncCheckpointEntriesTableAnnotationComposer,
          $$SyncCheckpointEntriesTableCreateCompanionBuilder,
          $$SyncCheckpointEntriesTableUpdateCompanionBuilder,
          (
            SyncCheckpointEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncCheckpointEntriesTable,
              SyncCheckpointEntry
            >,
          ),
          SyncCheckpointEntry,
          PrefetchHooks Function()
        > {
  $$SyncCheckpointEntriesTableTableManager(
    _$AppDatabase db,
    $SyncCheckpointEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCheckpointEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SyncCheckpointEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncCheckpointEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> moduleScopeSetKey = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<DateTime?> lastSuccessfulPullAt = const Value.absent(),
                Value<String?> lastPullStatus = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCheckpointEntriesCompanion(
                deviceId: deviceId,
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                moduleScopeSetKey: moduleScopeSetKey,
                cursor: cursor,
                lastPullAt: lastPullAt,
                lastSuccessfulPullAt: lastSuccessfulPullAt,
                lastPullStatus: lastPullStatus,
                lastErrorCode: lastErrorCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                required String moduleScopeSetKey,
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<DateTime?> lastSuccessfulPullAt = const Value.absent(),
                Value<String?> lastPullStatus = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCheckpointEntriesCompanion.insert(
                deviceId: deviceId,
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                moduleScopeSetKey: moduleScopeSetKey,
                cursor: cursor,
                lastPullAt: lastPullAt,
                lastSuccessfulPullAt: lastSuccessfulPullAt,
                lastPullStatus: lastPullStatus,
                lastErrorCode: lastErrorCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCheckpointEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCheckpointEntriesTable,
      SyncCheckpointEntry,
      $$SyncCheckpointEntriesTableFilterComposer,
      $$SyncCheckpointEntriesTableOrderingComposer,
      $$SyncCheckpointEntriesTableAnnotationComposer,
      $$SyncCheckpointEntriesTableCreateCompanionBuilder,
      $$SyncCheckpointEntriesTableUpdateCompanionBuilder,
      (
        SyncCheckpointEntry,
        BaseReferences<
          _$AppDatabase,
          $SyncCheckpointEntriesTable,
          SyncCheckpointEntry
        >,
      ),
      SyncCheckpointEntry,
      PrefetchHooks Function()
    >;
typedef $$OfflineCommandQueueEntriesTableCreateCompanionBuilder =
    OfflineCommandQueueEntriesCompanion Function({
      required String clientOpId,
      required String operationType,
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> accountId,
      required DateTime occurredAt,
      required String payloadJson,
      Value<String?> dependsOnClientOpId,
      required String status,
      Value<int> retryCount,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      Value<int> rowid,
    });
typedef $$OfflineCommandQueueEntriesTableUpdateCompanionBuilder =
    OfflineCommandQueueEntriesCompanion Function({
      Value<String> clientOpId,
      Value<String> operationType,
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> accountId,
      Value<DateTime> occurredAt,
      Value<String> payloadJson,
      Value<String?> dependsOnClientOpId,
      Value<String> status,
      Value<int> retryCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      Value<int> rowid,
    });

class $$OfflineCommandQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineCommandQueueEntriesTable> {
  $$OfflineCommandQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOnClientOpId => $composableBuilder(
    column: $table.dependsOnClientOpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineCommandQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineCommandQueueEntriesTable> {
  $$OfflineCommandQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOnClientOpId => $composableBuilder(
    column: $table.dependsOnClientOpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineCommandQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineCommandQueueEntriesTable> {
  $$OfflineCommandQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependsOnClientOpId => $composableBuilder(
    column: $table.dependsOnClientOpId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => column,
  );
}

class $$OfflineCommandQueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineCommandQueueEntriesTable,
          OfflineCommandQueueEntry,
          $$OfflineCommandQueueEntriesTableFilterComposer,
          $$OfflineCommandQueueEntriesTableOrderingComposer,
          $$OfflineCommandQueueEntriesTableAnnotationComposer,
          $$OfflineCommandQueueEntriesTableCreateCompanionBuilder,
          $$OfflineCommandQueueEntriesTableUpdateCompanionBuilder,
          (
            OfflineCommandQueueEntry,
            BaseReferences<
              _$AppDatabase,
              $OfflineCommandQueueEntriesTable,
              OfflineCommandQueueEntry
            >,
          ),
          OfflineCommandQueueEntry,
          PrefetchHooks Function()
        > {
  $$OfflineCommandQueueEntriesTableTableManager(
    _$AppDatabase db,
    $OfflineCommandQueueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineCommandQueueEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OfflineCommandQueueEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OfflineCommandQueueEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> clientOpId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> dependsOnClientOpId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineCommandQueueEntriesCompanion(
                clientOpId: clientOpId,
                operationType: operationType,
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                occurredAt: occurredAt,
                payloadJson: payloadJson,
                dependsOnClientOpId: dependsOnClientOpId,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastAttemptAt: lastAttemptAt,
                lastSyncedAt: lastSyncedAt,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientOpId,
                required String operationType,
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                required DateTime occurredAt,
                required String payloadJson,
                Value<String?> dependsOnClientOpId = const Value.absent(),
                required String status,
                Value<int> retryCount = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineCommandQueueEntriesCompanion.insert(
                clientOpId: clientOpId,
                operationType: operationType,
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                occurredAt: occurredAt,
                payloadJson: payloadJson,
                dependsOnClientOpId: dependsOnClientOpId,
                status: status,
                retryCount: retryCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastAttemptAt: lastAttemptAt,
                lastSyncedAt: lastSyncedAt,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineCommandQueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineCommandQueueEntriesTable,
      OfflineCommandQueueEntry,
      $$OfflineCommandQueueEntriesTableFilterComposer,
      $$OfflineCommandQueueEntriesTableOrderingComposer,
      $$OfflineCommandQueueEntriesTableAnnotationComposer,
      $$OfflineCommandQueueEntriesTableCreateCompanionBuilder,
      $$OfflineCommandQueueEntriesTableUpdateCompanionBuilder,
      (
        OfflineCommandQueueEntry,
        BaseReferences<
          _$AppDatabase,
          $OfflineCommandQueueEntriesTable,
          OfflineCommandQueueEntry
        >,
      ),
      OfflineCommandQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$SaleOutageOrderEntriesTableCreateCompanionBuilder =
    SaleOutageOrderEntriesCompanion Function({
      required String localIntentId,
      required String orderNumber,
      required String tenantId,
      required String branchId,
      required String accountId,
      required String saleType,
      required String paymentMethodRequested,
      required String tenderCurrency,
      Value<double> cashReceivedUsd,
      Value<double> cashReceivedKhr,
      required double totalUsd,
      required double totalKhr,
      required String linesJson,
      required String state,
      required String sourceMode,
      Value<String?> backendOrderId,
      Value<DateTime?> materializedAt,
      Value<String?> claimedPaymentMethod,
      Value<double?> claimedTenderAmount,
      Value<String?> proofImageUrl,
      Value<String?> customerReference,
      Value<String?> note,
      Value<DateTime?> claimRecordedAt,
      Value<String?> backendClaimId,
      Value<DateTime?> claimSubmittedAt,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SaleOutageOrderEntriesTableUpdateCompanionBuilder =
    SaleOutageOrderEntriesCompanion Function({
      Value<String> localIntentId,
      Value<String> orderNumber,
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> accountId,
      Value<String> saleType,
      Value<String> paymentMethodRequested,
      Value<String> tenderCurrency,
      Value<double> cashReceivedUsd,
      Value<double> cashReceivedKhr,
      Value<double> totalUsd,
      Value<double> totalKhr,
      Value<String> linesJson,
      Value<String> state,
      Value<String> sourceMode,
      Value<String?> backendOrderId,
      Value<DateTime?> materializedAt,
      Value<String?> claimedPaymentMethod,
      Value<double?> claimedTenderAmount,
      Value<String?> proofImageUrl,
      Value<String?> customerReference,
      Value<String?> note,
      Value<DateTime?> claimRecordedAt,
      Value<String?> backendClaimId,
      Value<DateTime?> claimSubmittedAt,
      Value<String?> lastErrorCode,
      Value<String?> lastErrorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SaleOutageOrderEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SaleOutageOrderEntriesTable> {
  $$SaleOutageOrderEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localIntentId => $composableBuilder(
    column: $table.localIntentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleType => $composableBuilder(
    column: $table.saleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethodRequested => $composableBuilder(
    column: $table.paymentMethodRequested,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenderCurrency => $composableBuilder(
    column: $table.tenderCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashReceivedUsd => $composableBuilder(
    column: $table.cashReceivedUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashReceivedKhr => $composableBuilder(
    column: $table.cashReceivedKhr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalUsd => $composableBuilder(
    column: $table.totalUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalKhr => $composableBuilder(
    column: $table.totalKhr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceMode => $composableBuilder(
    column: $table.sourceMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backendOrderId => $composableBuilder(
    column: $table.backendOrderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get materializedAt => $composableBuilder(
    column: $table.materializedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimedPaymentMethod => $composableBuilder(
    column: $table.claimedPaymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get claimedTenderAmount => $composableBuilder(
    column: $table.claimedTenderAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proofImageUrl => $composableBuilder(
    column: $table.proofImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerReference => $composableBuilder(
    column: $table.customerReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get claimRecordedAt => $composableBuilder(
    column: $table.claimRecordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backendClaimId => $composableBuilder(
    column: $table.backendClaimId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get claimSubmittedAt => $composableBuilder(
    column: $table.claimSubmittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SaleOutageOrderEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleOutageOrderEntriesTable> {
  $$SaleOutageOrderEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localIntentId => $composableBuilder(
    column: $table.localIntentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleType => $composableBuilder(
    column: $table.saleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethodRequested => $composableBuilder(
    column: $table.paymentMethodRequested,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenderCurrency => $composableBuilder(
    column: $table.tenderCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashReceivedUsd => $composableBuilder(
    column: $table.cashReceivedUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashReceivedKhr => $composableBuilder(
    column: $table.cashReceivedKhr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalUsd => $composableBuilder(
    column: $table.totalUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalKhr => $composableBuilder(
    column: $table.totalKhr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceMode => $composableBuilder(
    column: $table.sourceMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backendOrderId => $composableBuilder(
    column: $table.backendOrderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get materializedAt => $composableBuilder(
    column: $table.materializedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimedPaymentMethod => $composableBuilder(
    column: $table.claimedPaymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get claimedTenderAmount => $composableBuilder(
    column: $table.claimedTenderAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proofImageUrl => $composableBuilder(
    column: $table.proofImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerReference => $composableBuilder(
    column: $table.customerReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get claimRecordedAt => $composableBuilder(
    column: $table.claimRecordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backendClaimId => $composableBuilder(
    column: $table.backendClaimId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get claimSubmittedAt => $composableBuilder(
    column: $table.claimSubmittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SaleOutageOrderEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleOutageOrderEntriesTable> {
  $$SaleOutageOrderEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localIntentId => $composableBuilder(
    column: $table.localIntentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get saleType =>
      $composableBuilder(column: $table.saleType, builder: (column) => column);

  GeneratedColumn<String> get paymentMethodRequested => $composableBuilder(
    column: $table.paymentMethodRequested,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenderCurrency => $composableBuilder(
    column: $table.tenderCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashReceivedUsd => $composableBuilder(
    column: $table.cashReceivedUsd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashReceivedKhr => $composableBuilder(
    column: $table.cashReceivedKhr,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalUsd =>
      $composableBuilder(column: $table.totalUsd, builder: (column) => column);

  GeneratedColumn<double> get totalKhr =>
      $composableBuilder(column: $table.totalKhr, builder: (column) => column);

  GeneratedColumn<String> get linesJson =>
      $composableBuilder(column: $table.linesJson, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get sourceMode => $composableBuilder(
    column: $table.sourceMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backendOrderId => $composableBuilder(
    column: $table.backendOrderId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get materializedAt => $composableBuilder(
    column: $table.materializedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get claimedPaymentMethod => $composableBuilder(
    column: $table.claimedPaymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get claimedTenderAmount => $composableBuilder(
    column: $table.claimedTenderAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get proofImageUrl => $composableBuilder(
    column: $table.proofImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerReference => $composableBuilder(
    column: $table.customerReference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get claimRecordedAt => $composableBuilder(
    column: $table.claimRecordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backendClaimId => $composableBuilder(
    column: $table.backendClaimId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get claimSubmittedAt => $composableBuilder(
    column: $table.claimSubmittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorMessage => $composableBuilder(
    column: $table.lastErrorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SaleOutageOrderEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleOutageOrderEntriesTable,
          SaleOutageOrderEntry,
          $$SaleOutageOrderEntriesTableFilterComposer,
          $$SaleOutageOrderEntriesTableOrderingComposer,
          $$SaleOutageOrderEntriesTableAnnotationComposer,
          $$SaleOutageOrderEntriesTableCreateCompanionBuilder,
          $$SaleOutageOrderEntriesTableUpdateCompanionBuilder,
          (
            SaleOutageOrderEntry,
            BaseReferences<
              _$AppDatabase,
              $SaleOutageOrderEntriesTable,
              SaleOutageOrderEntry
            >,
          ),
          SaleOutageOrderEntry,
          PrefetchHooks Function()
        > {
  $$SaleOutageOrderEntriesTableTableManager(
    _$AppDatabase db,
    $SaleOutageOrderEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleOutageOrderEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SaleOutageOrderEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SaleOutageOrderEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localIntentId = const Value.absent(),
                Value<String> orderNumber = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> saleType = const Value.absent(),
                Value<String> paymentMethodRequested = const Value.absent(),
                Value<String> tenderCurrency = const Value.absent(),
                Value<double> cashReceivedUsd = const Value.absent(),
                Value<double> cashReceivedKhr = const Value.absent(),
                Value<double> totalUsd = const Value.absent(),
                Value<double> totalKhr = const Value.absent(),
                Value<String> linesJson = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> sourceMode = const Value.absent(),
                Value<String?> backendOrderId = const Value.absent(),
                Value<DateTime?> materializedAt = const Value.absent(),
                Value<String?> claimedPaymentMethod = const Value.absent(),
                Value<double?> claimedTenderAmount = const Value.absent(),
                Value<String?> proofImageUrl = const Value.absent(),
                Value<String?> customerReference = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> claimRecordedAt = const Value.absent(),
                Value<String?> backendClaimId = const Value.absent(),
                Value<DateTime?> claimSubmittedAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaleOutageOrderEntriesCompanion(
                localIntentId: localIntentId,
                orderNumber: orderNumber,
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                saleType: saleType,
                paymentMethodRequested: paymentMethodRequested,
                tenderCurrency: tenderCurrency,
                cashReceivedUsd: cashReceivedUsd,
                cashReceivedKhr: cashReceivedKhr,
                totalUsd: totalUsd,
                totalKhr: totalKhr,
                linesJson: linesJson,
                state: state,
                sourceMode: sourceMode,
                backendOrderId: backendOrderId,
                materializedAt: materializedAt,
                claimedPaymentMethod: claimedPaymentMethod,
                claimedTenderAmount: claimedTenderAmount,
                proofImageUrl: proofImageUrl,
                customerReference: customerReference,
                note: note,
                claimRecordedAt: claimRecordedAt,
                backendClaimId: backendClaimId,
                claimSubmittedAt: claimSubmittedAt,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localIntentId,
                required String orderNumber,
                required String tenantId,
                required String branchId,
                required String accountId,
                required String saleType,
                required String paymentMethodRequested,
                required String tenderCurrency,
                Value<double> cashReceivedUsd = const Value.absent(),
                Value<double> cashReceivedKhr = const Value.absent(),
                required double totalUsd,
                required double totalKhr,
                required String linesJson,
                required String state,
                required String sourceMode,
                Value<String?> backendOrderId = const Value.absent(),
                Value<DateTime?> materializedAt = const Value.absent(),
                Value<String?> claimedPaymentMethod = const Value.absent(),
                Value<double?> claimedTenderAmount = const Value.absent(),
                Value<String?> proofImageUrl = const Value.absent(),
                Value<String?> customerReference = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> claimRecordedAt = const Value.absent(),
                Value<String?> backendClaimId = const Value.absent(),
                Value<DateTime?> claimSubmittedAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> lastErrorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SaleOutageOrderEntriesCompanion.insert(
                localIntentId: localIntentId,
                orderNumber: orderNumber,
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                saleType: saleType,
                paymentMethodRequested: paymentMethodRequested,
                tenderCurrency: tenderCurrency,
                cashReceivedUsd: cashReceivedUsd,
                cashReceivedKhr: cashReceivedKhr,
                totalUsd: totalUsd,
                totalKhr: totalKhr,
                linesJson: linesJson,
                state: state,
                sourceMode: sourceMode,
                backendOrderId: backendOrderId,
                materializedAt: materializedAt,
                claimedPaymentMethod: claimedPaymentMethod,
                claimedTenderAmount: claimedTenderAmount,
                proofImageUrl: proofImageUrl,
                customerReference: customerReference,
                note: note,
                claimRecordedAt: claimRecordedAt,
                backendClaimId: backendClaimId,
                claimSubmittedAt: claimSubmittedAt,
                lastErrorCode: lastErrorCode,
                lastErrorMessage: lastErrorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SaleOutageOrderEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleOutageOrderEntriesTable,
      SaleOutageOrderEntry,
      $$SaleOutageOrderEntriesTableFilterComposer,
      $$SaleOutageOrderEntriesTableOrderingComposer,
      $$SaleOutageOrderEntriesTableAnnotationComposer,
      $$SaleOutageOrderEntriesTableCreateCompanionBuilder,
      $$SaleOutageOrderEntriesTableUpdateCompanionBuilder,
      (
        SaleOutageOrderEntry,
        BaseReferences<
          _$AppDatabase,
          $SaleOutageOrderEntriesTable,
          SaleOutageOrderEntry
        >,
      ),
      SaleOutageOrderEntry,
      PrefetchHooks Function()
    >;
typedef $$PolicyCacheEntriesTableCreateCompanionBuilder =
    PolicyCacheEntriesCompanion Function({
      required String tenantId,
      required String branchId,
      required bool saleVatEnabled,
      required double saleVatRatePercent,
      required double saleFxRateKhrPerUsd,
      required bool saleKhrRoundingEnabled,
      required String saleKhrRoundingMode,
      required String saleKhrRoundingGranularity,
      required bool saleAllowPayLater,
      Value<bool> saleAllowManualExternalPaymentClaim,
      required String createdAt,
      required String updatedAt,
      required DateTime cachedAt,
      Value<String?> syncCursorApplied,
      Value<DateTime?> lastPullAt,
      Value<int> rowid,
    });
typedef $$PolicyCacheEntriesTableUpdateCompanionBuilder =
    PolicyCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> branchId,
      Value<bool> saleVatEnabled,
      Value<double> saleVatRatePercent,
      Value<double> saleFxRateKhrPerUsd,
      Value<bool> saleKhrRoundingEnabled,
      Value<String> saleKhrRoundingMode,
      Value<String> saleKhrRoundingGranularity,
      Value<bool> saleAllowPayLater,
      Value<bool> saleAllowManualExternalPaymentClaim,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<DateTime> cachedAt,
      Value<String?> syncCursorApplied,
      Value<DateTime?> lastPullAt,
      Value<int> rowid,
    });

class $$PolicyCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PolicyCacheEntriesTable> {
  $$PolicyCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saleVatEnabled => $composableBuilder(
    column: $table.saleVatEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saleVatRatePercent => $composableBuilder(
    column: $table.saleVatRatePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saleFxRateKhrPerUsd => $composableBuilder(
    column: $table.saleFxRateKhrPerUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saleKhrRoundingEnabled => $composableBuilder(
    column: $table.saleKhrRoundingEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleKhrRoundingMode => $composableBuilder(
    column: $table.saleKhrRoundingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleKhrRoundingGranularity => $composableBuilder(
    column: $table.saleKhrRoundingGranularity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saleAllowPayLater => $composableBuilder(
    column: $table.saleAllowPayLater,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saleAllowManualExternalPaymentClaim =>
      $composableBuilder(
        column: $table.saleAllowManualExternalPaymentClaim,
        builder: (column) => ColumnFilters(column),
      );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncCursorApplied => $composableBuilder(
    column: $table.syncCursorApplied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PolicyCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PolicyCacheEntriesTable> {
  $$PolicyCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saleVatEnabled => $composableBuilder(
    column: $table.saleVatEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saleVatRatePercent => $composableBuilder(
    column: $table.saleVatRatePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saleFxRateKhrPerUsd => $composableBuilder(
    column: $table.saleFxRateKhrPerUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saleKhrRoundingEnabled => $composableBuilder(
    column: $table.saleKhrRoundingEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleKhrRoundingMode => $composableBuilder(
    column: $table.saleKhrRoundingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleKhrRoundingGranularity => $composableBuilder(
    column: $table.saleKhrRoundingGranularity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saleAllowPayLater => $composableBuilder(
    column: $table.saleAllowPayLater,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saleAllowManualExternalPaymentClaim =>
      $composableBuilder(
        column: $table.saleAllowManualExternalPaymentClaim,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncCursorApplied => $composableBuilder(
    column: $table.syncCursorApplied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PolicyCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PolicyCacheEntriesTable> {
  $$PolicyCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<bool> get saleVatEnabled => $composableBuilder(
    column: $table.saleVatEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<double> get saleVatRatePercent => $composableBuilder(
    column: $table.saleVatRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get saleFxRateKhrPerUsd => $composableBuilder(
    column: $table.saleFxRateKhrPerUsd,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get saleKhrRoundingEnabled => $composableBuilder(
    column: $table.saleKhrRoundingEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saleKhrRoundingMode => $composableBuilder(
    column: $table.saleKhrRoundingMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saleKhrRoundingGranularity => $composableBuilder(
    column: $table.saleKhrRoundingGranularity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get saleAllowPayLater => $composableBuilder(
    column: $table.saleAllowPayLater,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get saleAllowManualExternalPaymentClaim =>
      $composableBuilder(
        column: $table.saleAllowManualExternalPaymentClaim,
        builder: (column) => column,
      );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<String> get syncCursorApplied => $composableBuilder(
    column: $table.syncCursorApplied,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => column,
  );
}

class $$PolicyCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PolicyCacheEntriesTable,
          PolicyCacheEntry,
          $$PolicyCacheEntriesTableFilterComposer,
          $$PolicyCacheEntriesTableOrderingComposer,
          $$PolicyCacheEntriesTableAnnotationComposer,
          $$PolicyCacheEntriesTableCreateCompanionBuilder,
          $$PolicyCacheEntriesTableUpdateCompanionBuilder,
          (
            PolicyCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $PolicyCacheEntriesTable,
              PolicyCacheEntry
            >,
          ),
          PolicyCacheEntry,
          PrefetchHooks Function()
        > {
  $$PolicyCacheEntriesTableTableManager(
    _$AppDatabase db,
    $PolicyCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PolicyCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PolicyCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PolicyCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<bool> saleVatEnabled = const Value.absent(),
                Value<double> saleVatRatePercent = const Value.absent(),
                Value<double> saleFxRateKhrPerUsd = const Value.absent(),
                Value<bool> saleKhrRoundingEnabled = const Value.absent(),
                Value<String> saleKhrRoundingMode = const Value.absent(),
                Value<String> saleKhrRoundingGranularity = const Value.absent(),
                Value<bool> saleAllowPayLater = const Value.absent(),
                Value<bool> saleAllowManualExternalPaymentClaim =
                    const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<String?> syncCursorApplied = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PolicyCacheEntriesCompanion(
                tenantId: tenantId,
                branchId: branchId,
                saleVatEnabled: saleVatEnabled,
                saleVatRatePercent: saleVatRatePercent,
                saleFxRateKhrPerUsd: saleFxRateKhrPerUsd,
                saleKhrRoundingEnabled: saleKhrRoundingEnabled,
                saleKhrRoundingMode: saleKhrRoundingMode,
                saleKhrRoundingGranularity: saleKhrRoundingGranularity,
                saleAllowPayLater: saleAllowPayLater,
                saleAllowManualExternalPaymentClaim:
                    saleAllowManualExternalPaymentClaim,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                syncCursorApplied: syncCursorApplied,
                lastPullAt: lastPullAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String branchId,
                required bool saleVatEnabled,
                required double saleVatRatePercent,
                required double saleFxRateKhrPerUsd,
                required bool saleKhrRoundingEnabled,
                required String saleKhrRoundingMode,
                required String saleKhrRoundingGranularity,
                required bool saleAllowPayLater,
                Value<bool> saleAllowManualExternalPaymentClaim =
                    const Value.absent(),
                required String createdAt,
                required String updatedAt,
                required DateTime cachedAt,
                Value<String?> syncCursorApplied = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PolicyCacheEntriesCompanion.insert(
                tenantId: tenantId,
                branchId: branchId,
                saleVatEnabled: saleVatEnabled,
                saleVatRatePercent: saleVatRatePercent,
                saleFxRateKhrPerUsd: saleFxRateKhrPerUsd,
                saleKhrRoundingEnabled: saleKhrRoundingEnabled,
                saleKhrRoundingMode: saleKhrRoundingMode,
                saleKhrRoundingGranularity: saleKhrRoundingGranularity,
                saleAllowPayLater: saleAllowPayLater,
                saleAllowManualExternalPaymentClaim:
                    saleAllowManualExternalPaymentClaim,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
                syncCursorApplied: syncCursorApplied,
                lastPullAt: lastPullAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PolicyCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PolicyCacheEntriesTable,
      PolicyCacheEntry,
      $$PolicyCacheEntriesTableFilterComposer,
      $$PolicyCacheEntriesTableOrderingComposer,
      $$PolicyCacheEntriesTableAnnotationComposer,
      $$PolicyCacheEntriesTableCreateCompanionBuilder,
      $$PolicyCacheEntriesTableUpdateCompanionBuilder,
      (
        PolicyCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $PolicyCacheEntriesTable,
          PolicyCacheEntry
        >,
      ),
      PolicyCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$CashSessionSnapshotEntriesTableCreateCompanionBuilder =
    CashSessionSnapshotEntriesCompanion Function({
      required String tenantId,
      required String branchId,
      required String sessionId,
      required String openedByAccountId,
      required String openedByName,
      Value<DateTime?> openedAt,
      required String status,
      required double openingFloatUsd,
      required double openingFloatKhr,
      Value<DateTime?> closedAt,
      Value<String?> closedByAccountId,
      Value<String?> closedByName,
      Value<String?> closeNote,
      required double totalPaidInUsd,
      required double totalPaidOutUsd,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CashSessionSnapshotEntriesTableUpdateCompanionBuilder =
    CashSessionSnapshotEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> sessionId,
      Value<String> openedByAccountId,
      Value<String> openedByName,
      Value<DateTime?> openedAt,
      Value<String> status,
      Value<double> openingFloatUsd,
      Value<double> openingFloatKhr,
      Value<DateTime?> closedAt,
      Value<String?> closedByAccountId,
      Value<String?> closedByName,
      Value<String?> closeNote,
      Value<double> totalPaidInUsd,
      Value<double> totalPaidOutUsd,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CashSessionSnapshotEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CashSessionSnapshotEntriesTable> {
  $$CashSessionSnapshotEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedByAccountId => $composableBuilder(
    column: $table.openedByAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedByName => $composableBuilder(
    column: $table.openedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get openingFloatUsd => $composableBuilder(
    column: $table.openingFloatUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get openingFloatKhr => $composableBuilder(
    column: $table.openingFloatKhr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedByAccountId => $composableBuilder(
    column: $table.closedByAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedByName => $composableBuilder(
    column: $table.closedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closeNote => $composableBuilder(
    column: $table.closeNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPaidInUsd => $composableBuilder(
    column: $table.totalPaidInUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPaidOutUsd => $composableBuilder(
    column: $table.totalPaidOutUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashSessionSnapshotEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CashSessionSnapshotEntriesTable> {
  $$CashSessionSnapshotEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedByAccountId => $composableBuilder(
    column: $table.openedByAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedByName => $composableBuilder(
    column: $table.openedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get openingFloatUsd => $composableBuilder(
    column: $table.openingFloatUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get openingFloatKhr => $composableBuilder(
    column: $table.openingFloatKhr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedByAccountId => $composableBuilder(
    column: $table.closedByAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedByName => $composableBuilder(
    column: $table.closedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closeNote => $composableBuilder(
    column: $table.closeNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPaidInUsd => $composableBuilder(
    column: $table.totalPaidInUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPaidOutUsd => $composableBuilder(
    column: $table.totalPaidOutUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashSessionSnapshotEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashSessionSnapshotEntriesTable> {
  $$CashSessionSnapshotEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get openedByAccountId => $composableBuilder(
    column: $table.openedByAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openedByName => $composableBuilder(
    column: $table.openedByName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get openingFloatUsd => $composableBuilder(
    column: $table.openingFloatUsd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get openingFloatKhr => $composableBuilder(
    column: $table.openingFloatKhr,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get closedByAccountId => $composableBuilder(
    column: $table.closedByAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get closedByName => $composableBuilder(
    column: $table.closedByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get closeNote =>
      $composableBuilder(column: $table.closeNote, builder: (column) => column);

  GeneratedColumn<double> get totalPaidInUsd => $composableBuilder(
    column: $table.totalPaidInUsd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPaidOutUsd => $composableBuilder(
    column: $table.totalPaidOutUsd,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CashSessionSnapshotEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashSessionSnapshotEntriesTable,
          CashSessionSnapshotEntry,
          $$CashSessionSnapshotEntriesTableFilterComposer,
          $$CashSessionSnapshotEntriesTableOrderingComposer,
          $$CashSessionSnapshotEntriesTableAnnotationComposer,
          $$CashSessionSnapshotEntriesTableCreateCompanionBuilder,
          $$CashSessionSnapshotEntriesTableUpdateCompanionBuilder,
          (
            CashSessionSnapshotEntry,
            BaseReferences<
              _$AppDatabase,
              $CashSessionSnapshotEntriesTable,
              CashSessionSnapshotEntry
            >,
          ),
          CashSessionSnapshotEntry,
          PrefetchHooks Function()
        > {
  $$CashSessionSnapshotEntriesTableTableManager(
    _$AppDatabase db,
    $CashSessionSnapshotEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashSessionSnapshotEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CashSessionSnapshotEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CashSessionSnapshotEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> openedByAccountId = const Value.absent(),
                Value<String> openedByName = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> openingFloatUsd = const Value.absent(),
                Value<double> openingFloatKhr = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> closedByAccountId = const Value.absent(),
                Value<String?> closedByName = const Value.absent(),
                Value<String?> closeNote = const Value.absent(),
                Value<double> totalPaidInUsd = const Value.absent(),
                Value<double> totalPaidOutUsd = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashSessionSnapshotEntriesCompanion(
                tenantId: tenantId,
                branchId: branchId,
                sessionId: sessionId,
                openedByAccountId: openedByAccountId,
                openedByName: openedByName,
                openedAt: openedAt,
                status: status,
                openingFloatUsd: openingFloatUsd,
                openingFloatKhr: openingFloatKhr,
                closedAt: closedAt,
                closedByAccountId: closedByAccountId,
                closedByName: closedByName,
                closeNote: closeNote,
                totalPaidInUsd: totalPaidInUsd,
                totalPaidOutUsd: totalPaidOutUsd,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String branchId,
                required String sessionId,
                required String openedByAccountId,
                required String openedByName,
                Value<DateTime?> openedAt = const Value.absent(),
                required String status,
                required double openingFloatUsd,
                required double openingFloatKhr,
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> closedByAccountId = const Value.absent(),
                Value<String?> closedByName = const Value.absent(),
                Value<String?> closeNote = const Value.absent(),
                required double totalPaidInUsd,
                required double totalPaidOutUsd,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CashSessionSnapshotEntriesCompanion.insert(
                tenantId: tenantId,
                branchId: branchId,
                sessionId: sessionId,
                openedByAccountId: openedByAccountId,
                openedByName: openedByName,
                openedAt: openedAt,
                status: status,
                openingFloatUsd: openingFloatUsd,
                openingFloatKhr: openingFloatKhr,
                closedAt: closedAt,
                closedByAccountId: closedByAccountId,
                closedByName: closedByName,
                closeNote: closeNote,
                totalPaidInUsd: totalPaidInUsd,
                totalPaidOutUsd: totalPaidOutUsd,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashSessionSnapshotEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashSessionSnapshotEntriesTable,
      CashSessionSnapshotEntry,
      $$CashSessionSnapshotEntriesTableFilterComposer,
      $$CashSessionSnapshotEntriesTableOrderingComposer,
      $$CashSessionSnapshotEntriesTableAnnotationComposer,
      $$CashSessionSnapshotEntriesTableCreateCompanionBuilder,
      $$CashSessionSnapshotEntriesTableUpdateCompanionBuilder,
      (
        CashSessionSnapshotEntry,
        BaseReferences<
          _$AppDatabase,
          $CashSessionSnapshotEntriesTable,
          CashSessionSnapshotEntry
        >,
      ),
      CashSessionSnapshotEntry,
      PrefetchHooks Function()
    >;
typedef $$CashSessionMovementCacheEntriesTableCreateCompanionBuilder =
    CashSessionMovementCacheEntriesCompanion Function({
      required String tenantId,
      required String branchId,
      required String sessionId,
      required String movementId,
      required String movementType,
      required double amountUsd,
      required double amountKhr,
      Value<String?> reason,
      required String sourceRefType,
      Value<String?> sourceRefId,
      required String recordedByAccountId,
      Value<DateTime?> occurredAt,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$CashSessionMovementCacheEntriesTableUpdateCompanionBuilder =
    CashSessionMovementCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> sessionId,
      Value<String> movementId,
      Value<String> movementType,
      Value<double> amountUsd,
      Value<double> amountKhr,
      Value<String?> reason,
      Value<String> sourceRefType,
      Value<String?> sourceRefId,
      Value<String> recordedByAccountId,
      Value<DateTime?> occurredAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$CashSessionMovementCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CashSessionMovementCacheEntriesTable> {
  $$CashSessionMovementCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementId => $composableBuilder(
    column: $table.movementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountUsd => $composableBuilder(
    column: $table.amountUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountKhr => $composableBuilder(
    column: $table.amountKhr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRefType => $composableBuilder(
    column: $table.sourceRefType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRefId => $composableBuilder(
    column: $table.sourceRefId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedByAccountId => $composableBuilder(
    column: $table.recordedByAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashSessionMovementCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CashSessionMovementCacheEntriesTable> {
  $$CashSessionMovementCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementId => $composableBuilder(
    column: $table.movementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountUsd => $composableBuilder(
    column: $table.amountUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountKhr => $composableBuilder(
    column: $table.amountKhr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRefType => $composableBuilder(
    column: $table.sourceRefType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRefId => $composableBuilder(
    column: $table.sourceRefId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedByAccountId => $composableBuilder(
    column: $table.recordedByAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashSessionMovementCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashSessionMovementCacheEntriesTable> {
  $$CashSessionMovementCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get movementId => $composableBuilder(
    column: $table.movementId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amountUsd =>
      $composableBuilder(column: $table.amountUsd, builder: (column) => column);

  GeneratedColumn<double> get amountKhr =>
      $composableBuilder(column: $table.amountKhr, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get sourceRefType => $composableBuilder(
    column: $table.sourceRefType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRefId => $composableBuilder(
    column: $table.sourceRefId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordedByAccountId => $composableBuilder(
    column: $table.recordedByAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CashSessionMovementCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashSessionMovementCacheEntriesTable,
          CashSessionMovementCacheEntry,
          $$CashSessionMovementCacheEntriesTableFilterComposer,
          $$CashSessionMovementCacheEntriesTableOrderingComposer,
          $$CashSessionMovementCacheEntriesTableAnnotationComposer,
          $$CashSessionMovementCacheEntriesTableCreateCompanionBuilder,
          $$CashSessionMovementCacheEntriesTableUpdateCompanionBuilder,
          (
            CashSessionMovementCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $CashSessionMovementCacheEntriesTable,
              CashSessionMovementCacheEntry
            >,
          ),
          CashSessionMovementCacheEntry,
          PrefetchHooks Function()
        > {
  $$CashSessionMovementCacheEntriesTableTableManager(
    _$AppDatabase db,
    $CashSessionMovementCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashSessionMovementCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CashSessionMovementCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CashSessionMovementCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> movementId = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<double> amountUsd = const Value.absent(),
                Value<double> amountKhr = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String> sourceRefType = const Value.absent(),
                Value<String?> sourceRefId = const Value.absent(),
                Value<String> recordedByAccountId = const Value.absent(),
                Value<DateTime?> occurredAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashSessionMovementCacheEntriesCompanion(
                tenantId: tenantId,
                branchId: branchId,
                sessionId: sessionId,
                movementId: movementId,
                movementType: movementType,
                amountUsd: amountUsd,
                amountKhr: amountKhr,
                reason: reason,
                sourceRefType: sourceRefType,
                sourceRefId: sourceRefId,
                recordedByAccountId: recordedByAccountId,
                occurredAt: occurredAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String branchId,
                required String sessionId,
                required String movementId,
                required String movementType,
                required double amountUsd,
                required double amountKhr,
                Value<String?> reason = const Value.absent(),
                required String sourceRefType,
                Value<String?> sourceRefId = const Value.absent(),
                required String recordedByAccountId,
                Value<DateTime?> occurredAt = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => CashSessionMovementCacheEntriesCompanion.insert(
                tenantId: tenantId,
                branchId: branchId,
                sessionId: sessionId,
                movementId: movementId,
                movementType: movementType,
                amountUsd: amountUsd,
                amountKhr: amountKhr,
                reason: reason,
                sourceRefType: sourceRefType,
                sourceRefId: sourceRefId,
                recordedByAccountId: recordedByAccountId,
                occurredAt: occurredAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashSessionMovementCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashSessionMovementCacheEntriesTable,
      CashSessionMovementCacheEntry,
      $$CashSessionMovementCacheEntriesTableFilterComposer,
      $$CashSessionMovementCacheEntriesTableOrderingComposer,
      $$CashSessionMovementCacheEntriesTableAnnotationComposer,
      $$CashSessionMovementCacheEntriesTableCreateCompanionBuilder,
      $$CashSessionMovementCacheEntriesTableUpdateCompanionBuilder,
      (
        CashSessionMovementCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $CashSessionMovementCacheEntriesTable,
          CashSessionMovementCacheEntry
        >,
      ),
      CashSessionMovementCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$CashSessionSaleCacheEntriesTableCreateCompanionBuilder =
    CashSessionSaleCacheEntriesCompanion Function({
      required String tenantId,
      required String branchId,
      required String sessionId,
      required String saleId,
      required String status,
      required String paymentMethod,
      required String saleType,
      Value<DateTime?> finalizedAt,
      required int totalItems,
      required double grandTotalUsd,
      required double grandTotalKhr,
      required String cashierAccountId,
      required String cashierName,
      Value<DateTime?> voidedAt,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$CashSessionSaleCacheEntriesTableUpdateCompanionBuilder =
    CashSessionSaleCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> sessionId,
      Value<String> saleId,
      Value<String> status,
      Value<String> paymentMethod,
      Value<String> saleType,
      Value<DateTime?> finalizedAt,
      Value<int> totalItems,
      Value<double> grandTotalUsd,
      Value<double> grandTotalKhr,
      Value<String> cashierAccountId,
      Value<String> cashierName,
      Value<DateTime?> voidedAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$CashSessionSaleCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CashSessionSaleCacheEntriesTable> {
  $$CashSessionSaleCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleType => $composableBuilder(
    column: $table.saleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalItems => $composableBuilder(
    column: $table.totalItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grandTotalUsd => $composableBuilder(
    column: $table.grandTotalUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grandTotalKhr => $composableBuilder(
    column: $table.grandTotalKhr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierAccountId => $composableBuilder(
    column: $table.cashierAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashSessionSaleCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CashSessionSaleCacheEntriesTable> {
  $$CashSessionSaleCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleType => $composableBuilder(
    column: $table.saleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalItems => $composableBuilder(
    column: $table.totalItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grandTotalUsd => $composableBuilder(
    column: $table.grandTotalUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grandTotalKhr => $composableBuilder(
    column: $table.grandTotalKhr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierAccountId => $composableBuilder(
    column: $table.cashierAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get voidedAt => $composableBuilder(
    column: $table.voidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashSessionSaleCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashSessionSaleCacheEntriesTable> {
  $$CashSessionSaleCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saleType =>
      $composableBuilder(column: $table.saleType, builder: (column) => column);

  GeneratedColumn<DateTime> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalItems => $composableBuilder(
    column: $table.totalItems,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grandTotalUsd => $composableBuilder(
    column: $table.grandTotalUsd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grandTotalKhr => $composableBuilder(
    column: $table.grandTotalKhr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashierAccountId => $composableBuilder(
    column: $table.cashierAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get voidedAt =>
      $composableBuilder(column: $table.voidedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CashSessionSaleCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashSessionSaleCacheEntriesTable,
          CashSessionSaleCacheEntry,
          $$CashSessionSaleCacheEntriesTableFilterComposer,
          $$CashSessionSaleCacheEntriesTableOrderingComposer,
          $$CashSessionSaleCacheEntriesTableAnnotationComposer,
          $$CashSessionSaleCacheEntriesTableCreateCompanionBuilder,
          $$CashSessionSaleCacheEntriesTableUpdateCompanionBuilder,
          (
            CashSessionSaleCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $CashSessionSaleCacheEntriesTable,
              CashSessionSaleCacheEntry
            >,
          ),
          CashSessionSaleCacheEntry,
          PrefetchHooks Function()
        > {
  $$CashSessionSaleCacheEntriesTableTableManager(
    _$AppDatabase db,
    $CashSessionSaleCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashSessionSaleCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CashSessionSaleCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CashSessionSaleCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> saleType = const Value.absent(),
                Value<DateTime?> finalizedAt = const Value.absent(),
                Value<int> totalItems = const Value.absent(),
                Value<double> grandTotalUsd = const Value.absent(),
                Value<double> grandTotalKhr = const Value.absent(),
                Value<String> cashierAccountId = const Value.absent(),
                Value<String> cashierName = const Value.absent(),
                Value<DateTime?> voidedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashSessionSaleCacheEntriesCompanion(
                tenantId: tenantId,
                branchId: branchId,
                sessionId: sessionId,
                saleId: saleId,
                status: status,
                paymentMethod: paymentMethod,
                saleType: saleType,
                finalizedAt: finalizedAt,
                totalItems: totalItems,
                grandTotalUsd: grandTotalUsd,
                grandTotalKhr: grandTotalKhr,
                cashierAccountId: cashierAccountId,
                cashierName: cashierName,
                voidedAt: voidedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String branchId,
                required String sessionId,
                required String saleId,
                required String status,
                required String paymentMethod,
                required String saleType,
                Value<DateTime?> finalizedAt = const Value.absent(),
                required int totalItems,
                required double grandTotalUsd,
                required double grandTotalKhr,
                required String cashierAccountId,
                required String cashierName,
                Value<DateTime?> voidedAt = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => CashSessionSaleCacheEntriesCompanion.insert(
                tenantId: tenantId,
                branchId: branchId,
                sessionId: sessionId,
                saleId: saleId,
                status: status,
                paymentMethod: paymentMethod,
                saleType: saleType,
                finalizedAt: finalizedAt,
                totalItems: totalItems,
                grandTotalUsd: grandTotalUsd,
                grandTotalKhr: grandTotalKhr,
                cashierAccountId: cashierAccountId,
                cashierName: cashierName,
                voidedAt: voidedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashSessionSaleCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashSessionSaleCacheEntriesTable,
      CashSessionSaleCacheEntry,
      $$CashSessionSaleCacheEntriesTableFilterComposer,
      $$CashSessionSaleCacheEntriesTableOrderingComposer,
      $$CashSessionSaleCacheEntriesTableAnnotationComposer,
      $$CashSessionSaleCacheEntriesTableCreateCompanionBuilder,
      $$CashSessionSaleCacheEntriesTableUpdateCompanionBuilder,
      (
        CashSessionSaleCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $CashSessionSaleCacheEntriesTable,
          CashSessionSaleCacheEntry
        >,
      ),
      CashSessionSaleCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$MenuCacheScopesTableCreateCompanionBuilder =
    MenuCacheScopesCompanion Function({
      required String tenantId,
      required String scopeKey,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$MenuCacheScopesTableUpdateCompanionBuilder =
    MenuCacheScopesCompanion Function({
      Value<String> tenantId,
      Value<String> scopeKey,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$MenuCacheScopesTableFilterComposer
    extends Composer<_$AppDatabase, $MenuCacheScopesTable> {
  $$MenuCacheScopesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuCacheScopesTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuCacheScopesTable> {
  $$MenuCacheScopesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuCacheScopesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuCacheScopesTable> {
  $$MenuCacheScopesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$MenuCacheScopesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuCacheScopesTable,
          MenuCacheScope,
          $$MenuCacheScopesTableFilterComposer,
          $$MenuCacheScopesTableOrderingComposer,
          $$MenuCacheScopesTableAnnotationComposer,
          $$MenuCacheScopesTableCreateCompanionBuilder,
          $$MenuCacheScopesTableUpdateCompanionBuilder,
          (
            MenuCacheScope,
            BaseReferences<
              _$AppDatabase,
              $MenuCacheScopesTable,
              MenuCacheScope
            >,
          ),
          MenuCacheScope,
          PrefetchHooks Function()
        > {
  $$MenuCacheScopesTableTableManager(
    _$AppDatabase db,
    $MenuCacheScopesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuCacheScopesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuCacheScopesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuCacheScopesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuCacheScopesCompanion(
                tenantId: tenantId,
                scopeKey: scopeKey,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scopeKey,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => MenuCacheScopesCompanion.insert(
                tenantId: tenantId,
                scopeKey: scopeKey,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MenuCacheScopesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuCacheScopesTable,
      MenuCacheScope,
      $$MenuCacheScopesTableFilterComposer,
      $$MenuCacheScopesTableOrderingComposer,
      $$MenuCacheScopesTableAnnotationComposer,
      $$MenuCacheScopesTableCreateCompanionBuilder,
      $$MenuCacheScopesTableUpdateCompanionBuilder,
      (
        MenuCacheScope,
        BaseReferences<_$AppDatabase, $MenuCacheScopesTable, MenuCacheScope>,
      ),
      MenuCacheScope,
      PrefetchHooks Function()
    >;
typedef $$MenuItemCacheEntriesTableCreateCompanionBuilder =
    MenuItemCacheEntriesCompanion Function({
      required String tenantId,
      required String scopeKey,
      required String itemId,
      required int sortOrder,
      required String payloadJson,
      Value<int> rowid,
    });
typedef $$MenuItemCacheEntriesTableUpdateCompanionBuilder =
    MenuItemCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> scopeKey,
      Value<String> itemId,
      Value<int> sortOrder,
      Value<String> payloadJson,
      Value<int> rowid,
    });

class $$MenuItemCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MenuItemCacheEntriesTable> {
  $$MenuItemCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuItemCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuItemCacheEntriesTable> {
  $$MenuItemCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuItemCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuItemCacheEntriesTable> {
  $$MenuItemCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$MenuItemCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuItemCacheEntriesTable,
          MenuItemCacheEntry,
          $$MenuItemCacheEntriesTableFilterComposer,
          $$MenuItemCacheEntriesTableOrderingComposer,
          $$MenuItemCacheEntriesTableAnnotationComposer,
          $$MenuItemCacheEntriesTableCreateCompanionBuilder,
          $$MenuItemCacheEntriesTableUpdateCompanionBuilder,
          (
            MenuItemCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $MenuItemCacheEntriesTable,
              MenuItemCacheEntry
            >,
          ),
          MenuItemCacheEntry,
          PrefetchHooks Function()
        > {
  $$MenuItemCacheEntriesTableTableManager(
    _$AppDatabase db,
    $MenuItemCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuItemCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuItemCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MenuItemCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuItemCacheEntriesCompanion(
                tenantId: tenantId,
                scopeKey: scopeKey,
                itemId: itemId,
                sortOrder: sortOrder,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scopeKey,
                required String itemId,
                required int sortOrder,
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => MenuItemCacheEntriesCompanion.insert(
                tenantId: tenantId,
                scopeKey: scopeKey,
                itemId: itemId,
                sortOrder: sortOrder,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MenuItemCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuItemCacheEntriesTable,
      MenuItemCacheEntry,
      $$MenuItemCacheEntriesTableFilterComposer,
      $$MenuItemCacheEntriesTableOrderingComposer,
      $$MenuItemCacheEntriesTableAnnotationComposer,
      $$MenuItemCacheEntriesTableCreateCompanionBuilder,
      $$MenuItemCacheEntriesTableUpdateCompanionBuilder,
      (
        MenuItemCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $MenuItemCacheEntriesTable,
          MenuItemCacheEntry
        >,
      ),
      MenuItemCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$MenuCategoryCacheEntriesTableCreateCompanionBuilder =
    MenuCategoryCacheEntriesCompanion Function({
      required String tenantId,
      required String scopeKey,
      required String categoryId,
      required int sortOrder,
      required String payloadJson,
      Value<int> rowid,
    });
typedef $$MenuCategoryCacheEntriesTableUpdateCompanionBuilder =
    MenuCategoryCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> scopeKey,
      Value<String> categoryId,
      Value<int> sortOrder,
      Value<String> payloadJson,
      Value<int> rowid,
    });

class $$MenuCategoryCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MenuCategoryCacheEntriesTable> {
  $$MenuCategoryCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuCategoryCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuCategoryCacheEntriesTable> {
  $$MenuCategoryCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuCategoryCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuCategoryCacheEntriesTable> {
  $$MenuCategoryCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$MenuCategoryCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuCategoryCacheEntriesTable,
          MenuCategoryCacheEntry,
          $$MenuCategoryCacheEntriesTableFilterComposer,
          $$MenuCategoryCacheEntriesTableOrderingComposer,
          $$MenuCategoryCacheEntriesTableAnnotationComposer,
          $$MenuCategoryCacheEntriesTableCreateCompanionBuilder,
          $$MenuCategoryCacheEntriesTableUpdateCompanionBuilder,
          (
            MenuCategoryCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $MenuCategoryCacheEntriesTable,
              MenuCategoryCacheEntry
            >,
          ),
          MenuCategoryCacheEntry,
          PrefetchHooks Function()
        > {
  $$MenuCategoryCacheEntriesTableTableManager(
    _$AppDatabase db,
    $MenuCategoryCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuCategoryCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MenuCategoryCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MenuCategoryCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuCategoryCacheEntriesCompanion(
                tenantId: tenantId,
                scopeKey: scopeKey,
                categoryId: categoryId,
                sortOrder: sortOrder,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scopeKey,
                required String categoryId,
                required int sortOrder,
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => MenuCategoryCacheEntriesCompanion.insert(
                tenantId: tenantId,
                scopeKey: scopeKey,
                categoryId: categoryId,
                sortOrder: sortOrder,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MenuCategoryCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuCategoryCacheEntriesTable,
      MenuCategoryCacheEntry,
      $$MenuCategoryCacheEntriesTableFilterComposer,
      $$MenuCategoryCacheEntriesTableOrderingComposer,
      $$MenuCategoryCacheEntriesTableAnnotationComposer,
      $$MenuCategoryCacheEntriesTableCreateCompanionBuilder,
      $$MenuCategoryCacheEntriesTableUpdateCompanionBuilder,
      (
        MenuCategoryCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $MenuCategoryCacheEntriesTable,
          MenuCategoryCacheEntry
        >,
      ),
      MenuCategoryCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$MenuModifierGroupCacheEntriesTableCreateCompanionBuilder =
    MenuModifierGroupCacheEntriesCompanion Function({
      required String tenantId,
      required String scopeKey,
      required String groupId,
      required int sortOrder,
      required String payloadJson,
      Value<int> rowid,
    });
typedef $$MenuModifierGroupCacheEntriesTableUpdateCompanionBuilder =
    MenuModifierGroupCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> scopeKey,
      Value<String> groupId,
      Value<int> sortOrder,
      Value<String> payloadJson,
      Value<int> rowid,
    });

class $$MenuModifierGroupCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MenuModifierGroupCacheEntriesTable> {
  $$MenuModifierGroupCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuModifierGroupCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuModifierGroupCacheEntriesTable> {
  $$MenuModifierGroupCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuModifierGroupCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuModifierGroupCacheEntriesTable> {
  $$MenuModifierGroupCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$MenuModifierGroupCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuModifierGroupCacheEntriesTable,
          MenuModifierGroupCacheEntry,
          $$MenuModifierGroupCacheEntriesTableFilterComposer,
          $$MenuModifierGroupCacheEntriesTableOrderingComposer,
          $$MenuModifierGroupCacheEntriesTableAnnotationComposer,
          $$MenuModifierGroupCacheEntriesTableCreateCompanionBuilder,
          $$MenuModifierGroupCacheEntriesTableUpdateCompanionBuilder,
          (
            MenuModifierGroupCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $MenuModifierGroupCacheEntriesTable,
              MenuModifierGroupCacheEntry
            >,
          ),
          MenuModifierGroupCacheEntry,
          PrefetchHooks Function()
        > {
  $$MenuModifierGroupCacheEntriesTableTableManager(
    _$AppDatabase db,
    $MenuModifierGroupCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuModifierGroupCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MenuModifierGroupCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MenuModifierGroupCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuModifierGroupCacheEntriesCompanion(
                tenantId: tenantId,
                scopeKey: scopeKey,
                groupId: groupId,
                sortOrder: sortOrder,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scopeKey,
                required String groupId,
                required int sortOrder,
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => MenuModifierGroupCacheEntriesCompanion.insert(
                tenantId: tenantId,
                scopeKey: scopeKey,
                groupId: groupId,
                sortOrder: sortOrder,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MenuModifierGroupCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuModifierGroupCacheEntriesTable,
      MenuModifierGroupCacheEntry,
      $$MenuModifierGroupCacheEntriesTableFilterComposer,
      $$MenuModifierGroupCacheEntriesTableOrderingComposer,
      $$MenuModifierGroupCacheEntriesTableAnnotationComposer,
      $$MenuModifierGroupCacheEntriesTableCreateCompanionBuilder,
      $$MenuModifierGroupCacheEntriesTableUpdateCompanionBuilder,
      (
        MenuModifierGroupCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $MenuModifierGroupCacheEntriesTable,
          MenuModifierGroupCacheEntry
        >,
      ),
      MenuModifierGroupCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$MenuBranchCacheEntriesTableCreateCompanionBuilder =
    MenuBranchCacheEntriesCompanion Function({
      required String tenantId,
      required String scopeKey,
      required String branchId,
      required int sortOrder,
      required String payloadJson,
      Value<int> rowid,
    });
typedef $$MenuBranchCacheEntriesTableUpdateCompanionBuilder =
    MenuBranchCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> scopeKey,
      Value<String> branchId,
      Value<int> sortOrder,
      Value<String> payloadJson,
      Value<int> rowid,
    });

class $$MenuBranchCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MenuBranchCacheEntriesTable> {
  $$MenuBranchCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MenuBranchCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuBranchCacheEntriesTable> {
  $$MenuBranchCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MenuBranchCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuBranchCacheEntriesTable> {
  $$MenuBranchCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$MenuBranchCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuBranchCacheEntriesTable,
          MenuBranchCacheEntry,
          $$MenuBranchCacheEntriesTableFilterComposer,
          $$MenuBranchCacheEntriesTableOrderingComposer,
          $$MenuBranchCacheEntriesTableAnnotationComposer,
          $$MenuBranchCacheEntriesTableCreateCompanionBuilder,
          $$MenuBranchCacheEntriesTableUpdateCompanionBuilder,
          (
            MenuBranchCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $MenuBranchCacheEntriesTable,
              MenuBranchCacheEntry
            >,
          ),
          MenuBranchCacheEntry,
          PrefetchHooks Function()
        > {
  $$MenuBranchCacheEntriesTableTableManager(
    _$AppDatabase db,
    $MenuBranchCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuBranchCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MenuBranchCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MenuBranchCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuBranchCacheEntriesCompanion(
                tenantId: tenantId,
                scopeKey: scopeKey,
                branchId: branchId,
                sortOrder: sortOrder,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scopeKey,
                required String branchId,
                required int sortOrder,
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => MenuBranchCacheEntriesCompanion.insert(
                tenantId: tenantId,
                scopeKey: scopeKey,
                branchId: branchId,
                sortOrder: sortOrder,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MenuBranchCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuBranchCacheEntriesTable,
      MenuBranchCacheEntry,
      $$MenuBranchCacheEntriesTableFilterComposer,
      $$MenuBranchCacheEntriesTableOrderingComposer,
      $$MenuBranchCacheEntriesTableAnnotationComposer,
      $$MenuBranchCacheEntriesTableCreateCompanionBuilder,
      $$MenuBranchCacheEntriesTableUpdateCompanionBuilder,
      (
        MenuBranchCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $MenuBranchCacheEntriesTable,
          MenuBranchCacheEntry
        >,
      ),
      MenuBranchCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$AttendanceContextCacheEntriesTableCreateCompanionBuilder =
    AttendanceContextCacheEntriesCompanion Function({
      required String tenantId,
      required String branchId,
      required String accountId,
      required bool canCheckIn,
      Value<String?> reasonCode,
      Value<String?> reasonMessage,
      Value<String?> activeShiftId,
      Value<String?> activeShiftStartAt,
      Value<String?> activeShiftEndAt,
      Value<String?> activeAttendanceId,
      Value<String?> activeAttendanceStartAt,
      required String locationVerificationMode,
      Value<double?> geofenceCenterLat,
      Value<double?> geofenceCenterLng,
      Value<double?> geofenceRadiusM,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$AttendanceContextCacheEntriesTableUpdateCompanionBuilder =
    AttendanceContextCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> accountId,
      Value<bool> canCheckIn,
      Value<String?> reasonCode,
      Value<String?> reasonMessage,
      Value<String?> activeShiftId,
      Value<String?> activeShiftStartAt,
      Value<String?> activeShiftEndAt,
      Value<String?> activeAttendanceId,
      Value<String?> activeAttendanceStartAt,
      Value<String> locationVerificationMode,
      Value<double?> geofenceCenterLat,
      Value<double?> geofenceCenterLng,
      Value<double?> geofenceRadiusM,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$AttendanceContextCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceContextCacheEntriesTable> {
  $$AttendanceContextCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canCheckIn => $composableBuilder(
    column: $table.canCheckIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonMessage => $composableBuilder(
    column: $table.reasonMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeShiftId => $composableBuilder(
    column: $table.activeShiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeShiftStartAt => $composableBuilder(
    column: $table.activeShiftStartAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeShiftEndAt => $composableBuilder(
    column: $table.activeShiftEndAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeAttendanceId => $composableBuilder(
    column: $table.activeAttendanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeAttendanceStartAt => $composableBuilder(
    column: $table.activeAttendanceStartAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationVerificationMode => $composableBuilder(
    column: $table.locationVerificationMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get geofenceCenterLat => $composableBuilder(
    column: $table.geofenceCenterLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get geofenceCenterLng => $composableBuilder(
    column: $table.geofenceCenterLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get geofenceRadiusM => $composableBuilder(
    column: $table.geofenceRadiusM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceContextCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceContextCacheEntriesTable> {
  $$AttendanceContextCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canCheckIn => $composableBuilder(
    column: $table.canCheckIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonMessage => $composableBuilder(
    column: $table.reasonMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeShiftId => $composableBuilder(
    column: $table.activeShiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeShiftStartAt => $composableBuilder(
    column: $table.activeShiftStartAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeShiftEndAt => $composableBuilder(
    column: $table.activeShiftEndAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeAttendanceId => $composableBuilder(
    column: $table.activeAttendanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeAttendanceStartAt => $composableBuilder(
    column: $table.activeAttendanceStartAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationVerificationMode => $composableBuilder(
    column: $table.locationVerificationMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get geofenceCenterLat => $composableBuilder(
    column: $table.geofenceCenterLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get geofenceCenterLng => $composableBuilder(
    column: $table.geofenceCenterLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get geofenceRadiusM => $composableBuilder(
    column: $table.geofenceRadiusM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceContextCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceContextCacheEntriesTable> {
  $$AttendanceContextCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<bool> get canCheckIn => $composableBuilder(
    column: $table.canCheckIn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reasonMessage => $composableBuilder(
    column: $table.reasonMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeShiftId => $composableBuilder(
    column: $table.activeShiftId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeShiftStartAt => $composableBuilder(
    column: $table.activeShiftStartAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeShiftEndAt => $composableBuilder(
    column: $table.activeShiftEndAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeAttendanceId => $composableBuilder(
    column: $table.activeAttendanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeAttendanceStartAt => $composableBuilder(
    column: $table.activeAttendanceStartAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationVerificationMode => $composableBuilder(
    column: $table.locationVerificationMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get geofenceCenterLat => $composableBuilder(
    column: $table.geofenceCenterLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get geofenceCenterLng => $composableBuilder(
    column: $table.geofenceCenterLng,
    builder: (column) => column,
  );

  GeneratedColumn<double> get geofenceRadiusM => $composableBuilder(
    column: $table.geofenceRadiusM,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$AttendanceContextCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceContextCacheEntriesTable,
          AttendanceContextCacheEntry,
          $$AttendanceContextCacheEntriesTableFilterComposer,
          $$AttendanceContextCacheEntriesTableOrderingComposer,
          $$AttendanceContextCacheEntriesTableAnnotationComposer,
          $$AttendanceContextCacheEntriesTableCreateCompanionBuilder,
          $$AttendanceContextCacheEntriesTableUpdateCompanionBuilder,
          (
            AttendanceContextCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $AttendanceContextCacheEntriesTable,
              AttendanceContextCacheEntry
            >,
          ),
          AttendanceContextCacheEntry,
          PrefetchHooks Function()
        > {
  $$AttendanceContextCacheEntriesTableTableManager(
    _$AppDatabase db,
    $AttendanceContextCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceContextCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AttendanceContextCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceContextCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<bool> canCheckIn = const Value.absent(),
                Value<String?> reasonCode = const Value.absent(),
                Value<String?> reasonMessage = const Value.absent(),
                Value<String?> activeShiftId = const Value.absent(),
                Value<String?> activeShiftStartAt = const Value.absent(),
                Value<String?> activeShiftEndAt = const Value.absent(),
                Value<String?> activeAttendanceId = const Value.absent(),
                Value<String?> activeAttendanceStartAt = const Value.absent(),
                Value<String> locationVerificationMode = const Value.absent(),
                Value<double?> geofenceCenterLat = const Value.absent(),
                Value<double?> geofenceCenterLng = const Value.absent(),
                Value<double?> geofenceRadiusM = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceContextCacheEntriesCompanion(
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                canCheckIn: canCheckIn,
                reasonCode: reasonCode,
                reasonMessage: reasonMessage,
                activeShiftId: activeShiftId,
                activeShiftStartAt: activeShiftStartAt,
                activeShiftEndAt: activeShiftEndAt,
                activeAttendanceId: activeAttendanceId,
                activeAttendanceStartAt: activeAttendanceStartAt,
                locationVerificationMode: locationVerificationMode,
                geofenceCenterLat: geofenceCenterLat,
                geofenceCenterLng: geofenceCenterLng,
                geofenceRadiusM: geofenceRadiusM,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String branchId,
                required String accountId,
                required bool canCheckIn,
                Value<String?> reasonCode = const Value.absent(),
                Value<String?> reasonMessage = const Value.absent(),
                Value<String?> activeShiftId = const Value.absent(),
                Value<String?> activeShiftStartAt = const Value.absent(),
                Value<String?> activeShiftEndAt = const Value.absent(),
                Value<String?> activeAttendanceId = const Value.absent(),
                Value<String?> activeAttendanceStartAt = const Value.absent(),
                required String locationVerificationMode,
                Value<double?> geofenceCenterLat = const Value.absent(),
                Value<double?> geofenceCenterLng = const Value.absent(),
                Value<double?> geofenceRadiusM = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => AttendanceContextCacheEntriesCompanion.insert(
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                canCheckIn: canCheckIn,
                reasonCode: reasonCode,
                reasonMessage: reasonMessage,
                activeShiftId: activeShiftId,
                activeShiftStartAt: activeShiftStartAt,
                activeShiftEndAt: activeShiftEndAt,
                activeAttendanceId: activeAttendanceId,
                activeAttendanceStartAt: activeAttendanceStartAt,
                locationVerificationMode: locationVerificationMode,
                geofenceCenterLat: geofenceCenterLat,
                geofenceCenterLng: geofenceCenterLng,
                geofenceRadiusM: geofenceRadiusM,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceContextCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceContextCacheEntriesTable,
      AttendanceContextCacheEntry,
      $$AttendanceContextCacheEntriesTableFilterComposer,
      $$AttendanceContextCacheEntriesTableOrderingComposer,
      $$AttendanceContextCacheEntriesTableAnnotationComposer,
      $$AttendanceContextCacheEntriesTableCreateCompanionBuilder,
      $$AttendanceContextCacheEntriesTableUpdateCompanionBuilder,
      (
        AttendanceContextCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $AttendanceContextCacheEntriesTable,
          AttendanceContextCacheEntry
        >,
      ),
      AttendanceContextCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$AttendanceRecordCacheEntriesTableCreateCompanionBuilder =
    AttendanceRecordCacheEntriesCompanion Function({
      required String tenantId,
      required String branchId,
      required String accountId,
      required String recordId,
      required String employeeId,
      required String type,
      required DateTime occurredAt,
      required DateTime createdAt,
      Value<double?> locationLat,
      Value<double?> locationLng,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$AttendanceRecordCacheEntriesTableUpdateCompanionBuilder =
    AttendanceRecordCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> branchId,
      Value<String> accountId,
      Value<String> recordId,
      Value<String> employeeId,
      Value<String> type,
      Value<DateTime> occurredAt,
      Value<DateTime> createdAt,
      Value<double?> locationLat,
      Value<double?> locationLng,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$AttendanceRecordCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceRecordCacheEntriesTable> {
  $$AttendanceRecordCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLng => $composableBuilder(
    column: $table.locationLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceRecordCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceRecordCacheEntriesTable> {
  $$AttendanceRecordCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLng => $composableBuilder(
    column: $table.locationLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceRecordCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceRecordCacheEntriesTable> {
  $$AttendanceRecordCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
    column: $table.employeeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationLng => $composableBuilder(
    column: $table.locationLng,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$AttendanceRecordCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceRecordCacheEntriesTable,
          AttendanceRecordCacheEntry,
          $$AttendanceRecordCacheEntriesTableFilterComposer,
          $$AttendanceRecordCacheEntriesTableOrderingComposer,
          $$AttendanceRecordCacheEntriesTableAnnotationComposer,
          $$AttendanceRecordCacheEntriesTableCreateCompanionBuilder,
          $$AttendanceRecordCacheEntriesTableUpdateCompanionBuilder,
          (
            AttendanceRecordCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $AttendanceRecordCacheEntriesTable,
              AttendanceRecordCacheEntry
            >,
          ),
          AttendanceRecordCacheEntry,
          PrefetchHooks Function()
        > {
  $$AttendanceRecordCacheEntriesTableTableManager(
    _$AppDatabase db,
    $AttendanceRecordCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceRecordCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AttendanceRecordCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttendanceRecordCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> employeeId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<double?> locationLat = const Value.absent(),
                Value<double?> locationLng = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceRecordCacheEntriesCompanion(
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                recordId: recordId,
                employeeId: employeeId,
                type: type,
                occurredAt: occurredAt,
                createdAt: createdAt,
                locationLat: locationLat,
                locationLng: locationLng,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String branchId,
                required String accountId,
                required String recordId,
                required String employeeId,
                required String type,
                required DateTime occurredAt,
                required DateTime createdAt,
                Value<double?> locationLat = const Value.absent(),
                Value<double?> locationLng = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => AttendanceRecordCacheEntriesCompanion.insert(
                tenantId: tenantId,
                branchId: branchId,
                accountId: accountId,
                recordId: recordId,
                employeeId: employeeId,
                type: type,
                occurredAt: occurredAt,
                createdAt: createdAt,
                locationLat: locationLat,
                locationLng: locationLng,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceRecordCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceRecordCacheEntriesTable,
      AttendanceRecordCacheEntry,
      $$AttendanceRecordCacheEntriesTableFilterComposer,
      $$AttendanceRecordCacheEntriesTableOrderingComposer,
      $$AttendanceRecordCacheEntriesTableAnnotationComposer,
      $$AttendanceRecordCacheEntriesTableCreateCompanionBuilder,
      $$AttendanceRecordCacheEntriesTableUpdateCompanionBuilder,
      (
        AttendanceRecordCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $AttendanceRecordCacheEntriesTable,
          AttendanceRecordCacheEntry
        >,
      ),
      AttendanceRecordCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$StaffShiftScopeEntriesTableCreateCompanionBuilder =
    StaffShiftScopeEntriesCompanion Function({
      required String tenantId,
      required String scopeKey,
      required String branchId,
      Value<String> membershipId,
      required String fromDate,
      required String toDate,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$StaffShiftScopeEntriesTableUpdateCompanionBuilder =
    StaffShiftScopeEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> scopeKey,
      Value<String> branchId,
      Value<String> membershipId,
      Value<String> fromDate,
      Value<String> toDate,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$StaffShiftScopeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $StaffShiftScopeEntriesTable> {
  $$StaffShiftScopeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromDate => $composableBuilder(
    column: $table.fromDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toDate => $composableBuilder(
    column: $table.toDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaffShiftScopeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffShiftScopeEntriesTable> {
  $$StaffShiftScopeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromDate => $composableBuilder(
    column: $table.fromDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toDate => $composableBuilder(
    column: $table.toDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffShiftScopeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffShiftScopeEntriesTable> {
  $$StaffShiftScopeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromDate =>
      $composableBuilder(column: $table.fromDate, builder: (column) => column);

  GeneratedColumn<String> get toDate =>
      $composableBuilder(column: $table.toDate, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$StaffShiftScopeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffShiftScopeEntriesTable,
          StaffShiftScopeEntry,
          $$StaffShiftScopeEntriesTableFilterComposer,
          $$StaffShiftScopeEntriesTableOrderingComposer,
          $$StaffShiftScopeEntriesTableAnnotationComposer,
          $$StaffShiftScopeEntriesTableCreateCompanionBuilder,
          $$StaffShiftScopeEntriesTableUpdateCompanionBuilder,
          (
            StaffShiftScopeEntry,
            BaseReferences<
              _$AppDatabase,
              $StaffShiftScopeEntriesTable,
              StaffShiftScopeEntry
            >,
          ),
          StaffShiftScopeEntry,
          PrefetchHooks Function()
        > {
  $$StaffShiftScopeEntriesTableTableManager(
    _$AppDatabase db,
    $StaffShiftScopeEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffShiftScopeEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$StaffShiftScopeEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StaffShiftScopeEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> membershipId = const Value.absent(),
                Value<String> fromDate = const Value.absent(),
                Value<String> toDate = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftScopeEntriesCompanion(
                tenantId: tenantId,
                scopeKey: scopeKey,
                branchId: branchId,
                membershipId: membershipId,
                fromDate: fromDate,
                toDate: toDate,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scopeKey,
                required String branchId,
                Value<String> membershipId = const Value.absent(),
                required String fromDate,
                required String toDate,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftScopeEntriesCompanion.insert(
                tenantId: tenantId,
                scopeKey: scopeKey,
                branchId: branchId,
                membershipId: membershipId,
                fromDate: fromDate,
                toDate: toDate,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaffShiftScopeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffShiftScopeEntriesTable,
      StaffShiftScopeEntry,
      $$StaffShiftScopeEntriesTableFilterComposer,
      $$StaffShiftScopeEntriesTableOrderingComposer,
      $$StaffShiftScopeEntriesTableAnnotationComposer,
      $$StaffShiftScopeEntriesTableCreateCompanionBuilder,
      $$StaffShiftScopeEntriesTableUpdateCompanionBuilder,
      (
        StaffShiftScopeEntry,
        BaseReferences<
          _$AppDatabase,
          $StaffShiftScopeEntriesTable,
          StaffShiftScopeEntry
        >,
      ),
      StaffShiftScopeEntry,
      PrefetchHooks Function()
    >;
typedef $$StaffShiftBranchCacheEntriesTableCreateCompanionBuilder =
    StaffShiftBranchCacheEntriesCompanion Function({
      required String tenantId,
      required String branchId,
      required int sortOrder,
      required String branchName,
      required String status,
      Value<int> rowid,
    });
typedef $$StaffShiftBranchCacheEntriesTableUpdateCompanionBuilder =
    StaffShiftBranchCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> branchId,
      Value<int> sortOrder,
      Value<String> branchName,
      Value<String> status,
      Value<int> rowid,
    });

class $$StaffShiftBranchCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $StaffShiftBranchCacheEntriesTable> {
  $$StaffShiftBranchCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaffShiftBranchCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffShiftBranchCacheEntriesTable> {
  $$StaffShiftBranchCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffShiftBranchCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffShiftBranchCacheEntriesTable> {
  $$StaffShiftBranchCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$StaffShiftBranchCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffShiftBranchCacheEntriesTable,
          StaffShiftBranchCacheEntry,
          $$StaffShiftBranchCacheEntriesTableFilterComposer,
          $$StaffShiftBranchCacheEntriesTableOrderingComposer,
          $$StaffShiftBranchCacheEntriesTableAnnotationComposer,
          $$StaffShiftBranchCacheEntriesTableCreateCompanionBuilder,
          $$StaffShiftBranchCacheEntriesTableUpdateCompanionBuilder,
          (
            StaffShiftBranchCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $StaffShiftBranchCacheEntriesTable,
              StaffShiftBranchCacheEntry
            >,
          ),
          StaffShiftBranchCacheEntry,
          PrefetchHooks Function()
        > {
  $$StaffShiftBranchCacheEntriesTableTableManager(
    _$AppDatabase db,
    $StaffShiftBranchCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffShiftBranchCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$StaffShiftBranchCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StaffShiftBranchCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> branchName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftBranchCacheEntriesCompanion(
                tenantId: tenantId,
                branchId: branchId,
                sortOrder: sortOrder,
                branchName: branchName,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String branchId,
                required int sortOrder,
                required String branchName,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftBranchCacheEntriesCompanion.insert(
                tenantId: tenantId,
                branchId: branchId,
                sortOrder: sortOrder,
                branchName: branchName,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaffShiftBranchCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffShiftBranchCacheEntriesTable,
      StaffShiftBranchCacheEntry,
      $$StaffShiftBranchCacheEntriesTableFilterComposer,
      $$StaffShiftBranchCacheEntriesTableOrderingComposer,
      $$StaffShiftBranchCacheEntriesTableAnnotationComposer,
      $$StaffShiftBranchCacheEntriesTableCreateCompanionBuilder,
      $$StaffShiftBranchCacheEntriesTableUpdateCompanionBuilder,
      (
        StaffShiftBranchCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $StaffShiftBranchCacheEntriesTable,
          StaffShiftBranchCacheEntry
        >,
      ),
      StaffShiftBranchCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$StaffShiftMembershipCacheEntriesTableCreateCompanionBuilder =
    StaffShiftMembershipCacheEntriesCompanion Function({
      required String tenantId,
      required String membershipId,
      required int sortOrder,
      required String accountId,
      required String roleKey,
      required String membershipStatus,
      required String phone,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> staffProfileStatus,
      Value<DateTime?> invitedAt,
      Value<DateTime?> acceptedAt,
      Value<DateTime?> rejectedAt,
      Value<DateTime?> revokedAt,
      required String pendingBranchIdsJson,
      required String activeBranchIdsJson,
      Value<int> rowid,
    });
typedef $$StaffShiftMembershipCacheEntriesTableUpdateCompanionBuilder =
    StaffShiftMembershipCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> membershipId,
      Value<int> sortOrder,
      Value<String> accountId,
      Value<String> roleKey,
      Value<String> membershipStatus,
      Value<String> phone,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> staffProfileStatus,
      Value<DateTime?> invitedAt,
      Value<DateTime?> acceptedAt,
      Value<DateTime?> rejectedAt,
      Value<DateTime?> revokedAt,
      Value<String> pendingBranchIdsJson,
      Value<String> activeBranchIdsJson,
      Value<int> rowid,
    });

class $$StaffShiftMembershipCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $StaffShiftMembershipCacheEntriesTable> {
  $$StaffShiftMembershipCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleKey => $composableBuilder(
    column: $table.roleKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get membershipStatus => $composableBuilder(
    column: $table.membershipStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staffProfileStatus => $composableBuilder(
    column: $table.staffProfileStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get invitedAt => $composableBuilder(
    column: $table.invitedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingBranchIdsJson => $composableBuilder(
    column: $table.pendingBranchIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeBranchIdsJson => $composableBuilder(
    column: $table.activeBranchIdsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaffShiftMembershipCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffShiftMembershipCacheEntriesTable> {
  $$StaffShiftMembershipCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleKey => $composableBuilder(
    column: $table.roleKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get membershipStatus => $composableBuilder(
    column: $table.membershipStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staffProfileStatus => $composableBuilder(
    column: $table.staffProfileStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get invitedAt => $composableBuilder(
    column: $table.invitedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingBranchIdsJson => $composableBuilder(
    column: $table.pendingBranchIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeBranchIdsJson => $composableBuilder(
    column: $table.activeBranchIdsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffShiftMembershipCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffShiftMembershipCacheEntriesTable> {
  $$StaffShiftMembershipCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get roleKey =>
      $composableBuilder(column: $table.roleKey, builder: (column) => column);

  GeneratedColumn<String> get membershipStatus => $composableBuilder(
    column: $table.membershipStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get staffProfileStatus => $composableBuilder(
    column: $table.staffProfileStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get invitedAt =>
      $composableBuilder(column: $table.invitedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  GeneratedColumn<String> get pendingBranchIdsJson => $composableBuilder(
    column: $table.pendingBranchIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeBranchIdsJson => $composableBuilder(
    column: $table.activeBranchIdsJson,
    builder: (column) => column,
  );
}

class $$StaffShiftMembershipCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffShiftMembershipCacheEntriesTable,
          StaffShiftMembershipCacheEntry,
          $$StaffShiftMembershipCacheEntriesTableFilterComposer,
          $$StaffShiftMembershipCacheEntriesTableOrderingComposer,
          $$StaffShiftMembershipCacheEntriesTableAnnotationComposer,
          $$StaffShiftMembershipCacheEntriesTableCreateCompanionBuilder,
          $$StaffShiftMembershipCacheEntriesTableUpdateCompanionBuilder,
          (
            StaffShiftMembershipCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $StaffShiftMembershipCacheEntriesTable,
              StaffShiftMembershipCacheEntry
            >,
          ),
          StaffShiftMembershipCacheEntry,
          PrefetchHooks Function()
        > {
  $$StaffShiftMembershipCacheEntriesTableTableManager(
    _$AppDatabase db,
    $StaffShiftMembershipCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffShiftMembershipCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$StaffShiftMembershipCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StaffShiftMembershipCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> membershipId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> roleKey = const Value.absent(),
                Value<String> membershipStatus = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> staffProfileStatus = const Value.absent(),
                Value<DateTime?> invitedAt = const Value.absent(),
                Value<DateTime?> acceptedAt = const Value.absent(),
                Value<DateTime?> rejectedAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<String> pendingBranchIdsJson = const Value.absent(),
                Value<String> activeBranchIdsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftMembershipCacheEntriesCompanion(
                tenantId: tenantId,
                membershipId: membershipId,
                sortOrder: sortOrder,
                accountId: accountId,
                roleKey: roleKey,
                membershipStatus: membershipStatus,
                phone: phone,
                firstName: firstName,
                lastName: lastName,
                staffProfileStatus: staffProfileStatus,
                invitedAt: invitedAt,
                acceptedAt: acceptedAt,
                rejectedAt: rejectedAt,
                revokedAt: revokedAt,
                pendingBranchIdsJson: pendingBranchIdsJson,
                activeBranchIdsJson: activeBranchIdsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String membershipId,
                required int sortOrder,
                required String accountId,
                required String roleKey,
                required String membershipStatus,
                required String phone,
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> staffProfileStatus = const Value.absent(),
                Value<DateTime?> invitedAt = const Value.absent(),
                Value<DateTime?> acceptedAt = const Value.absent(),
                Value<DateTime?> rejectedAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                required String pendingBranchIdsJson,
                required String activeBranchIdsJson,
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftMembershipCacheEntriesCompanion.insert(
                tenantId: tenantId,
                membershipId: membershipId,
                sortOrder: sortOrder,
                accountId: accountId,
                roleKey: roleKey,
                membershipStatus: membershipStatus,
                phone: phone,
                firstName: firstName,
                lastName: lastName,
                staffProfileStatus: staffProfileStatus,
                invitedAt: invitedAt,
                acceptedAt: acceptedAt,
                rejectedAt: rejectedAt,
                revokedAt: revokedAt,
                pendingBranchIdsJson: pendingBranchIdsJson,
                activeBranchIdsJson: activeBranchIdsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaffShiftMembershipCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffShiftMembershipCacheEntriesTable,
      StaffShiftMembershipCacheEntry,
      $$StaffShiftMembershipCacheEntriesTableFilterComposer,
      $$StaffShiftMembershipCacheEntriesTableOrderingComposer,
      $$StaffShiftMembershipCacheEntriesTableAnnotationComposer,
      $$StaffShiftMembershipCacheEntriesTableCreateCompanionBuilder,
      $$StaffShiftMembershipCacheEntriesTableUpdateCompanionBuilder,
      (
        StaffShiftMembershipCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $StaffShiftMembershipCacheEntriesTable,
          StaffShiftMembershipCacheEntry
        >,
      ),
      StaffShiftMembershipCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$StaffShiftPatternCacheEntriesTableCreateCompanionBuilder =
    StaffShiftPatternCacheEntriesCompanion Function({
      required String tenantId,
      required String scopeKey,
      required String patternId,
      required int sortOrder,
      required String membershipId,
      required String branchId,
      required String daysOfWeekJson,
      required String plannedStartTime,
      required String plannedEndTime,
      required String status,
      Value<DateTime?> effectiveFrom,
      Value<DateTime?> effectiveTo,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StaffShiftPatternCacheEntriesTableUpdateCompanionBuilder =
    StaffShiftPatternCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> scopeKey,
      Value<String> patternId,
      Value<int> sortOrder,
      Value<String> membershipId,
      Value<String> branchId,
      Value<String> daysOfWeekJson,
      Value<String> plannedStartTime,
      Value<String> plannedEndTime,
      Value<String> status,
      Value<DateTime?> effectiveFrom,
      Value<DateTime?> effectiveTo,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StaffShiftPatternCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $StaffShiftPatternCacheEntriesTable> {
  $$StaffShiftPatternCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get daysOfWeekJson => $composableBuilder(
    column: $table.daysOfWeekJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedStartTime => $composableBuilder(
    column: $table.plannedStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedEndTime => $composableBuilder(
    column: $table.plannedEndTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaffShiftPatternCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffShiftPatternCacheEntriesTable> {
  $$StaffShiftPatternCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get daysOfWeekJson => $composableBuilder(
    column: $table.daysOfWeekJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedStartTime => $composableBuilder(
    column: $table.plannedStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedEndTime => $composableBuilder(
    column: $table.plannedEndTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffShiftPatternCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffShiftPatternCacheEntriesTable> {
  $$StaffShiftPatternCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get patternId =>
      $composableBuilder(column: $table.patternId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get daysOfWeekJson => $composableBuilder(
    column: $table.daysOfWeekJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plannedStartTime => $composableBuilder(
    column: $table.plannedStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plannedEndTime => $composableBuilder(
    column: $table.plannedEndTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StaffShiftPatternCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffShiftPatternCacheEntriesTable,
          StaffShiftPatternCacheEntry,
          $$StaffShiftPatternCacheEntriesTableFilterComposer,
          $$StaffShiftPatternCacheEntriesTableOrderingComposer,
          $$StaffShiftPatternCacheEntriesTableAnnotationComposer,
          $$StaffShiftPatternCacheEntriesTableCreateCompanionBuilder,
          $$StaffShiftPatternCacheEntriesTableUpdateCompanionBuilder,
          (
            StaffShiftPatternCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $StaffShiftPatternCacheEntriesTable,
              StaffShiftPatternCacheEntry
            >,
          ),
          StaffShiftPatternCacheEntry,
          PrefetchHooks Function()
        > {
  $$StaffShiftPatternCacheEntriesTableTableManager(
    _$AppDatabase db,
    $StaffShiftPatternCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffShiftPatternCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$StaffShiftPatternCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StaffShiftPatternCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> patternId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> membershipId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String> daysOfWeekJson = const Value.absent(),
                Value<String> plannedStartTime = const Value.absent(),
                Value<String> plannedEndTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> effectiveFrom = const Value.absent(),
                Value<DateTime?> effectiveTo = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftPatternCacheEntriesCompanion(
                tenantId: tenantId,
                scopeKey: scopeKey,
                patternId: patternId,
                sortOrder: sortOrder,
                membershipId: membershipId,
                branchId: branchId,
                daysOfWeekJson: daysOfWeekJson,
                plannedStartTime: plannedStartTime,
                plannedEndTime: plannedEndTime,
                status: status,
                effectiveFrom: effectiveFrom,
                effectiveTo: effectiveTo,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scopeKey,
                required String patternId,
                required int sortOrder,
                required String membershipId,
                required String branchId,
                required String daysOfWeekJson,
                required String plannedStartTime,
                required String plannedEndTime,
                required String status,
                Value<DateTime?> effectiveFrom = const Value.absent(),
                Value<DateTime?> effectiveTo = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftPatternCacheEntriesCompanion.insert(
                tenantId: tenantId,
                scopeKey: scopeKey,
                patternId: patternId,
                sortOrder: sortOrder,
                membershipId: membershipId,
                branchId: branchId,
                daysOfWeekJson: daysOfWeekJson,
                plannedStartTime: plannedStartTime,
                plannedEndTime: plannedEndTime,
                status: status,
                effectiveFrom: effectiveFrom,
                effectiveTo: effectiveTo,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaffShiftPatternCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffShiftPatternCacheEntriesTable,
      StaffShiftPatternCacheEntry,
      $$StaffShiftPatternCacheEntriesTableFilterComposer,
      $$StaffShiftPatternCacheEntriesTableOrderingComposer,
      $$StaffShiftPatternCacheEntriesTableAnnotationComposer,
      $$StaffShiftPatternCacheEntriesTableCreateCompanionBuilder,
      $$StaffShiftPatternCacheEntriesTableUpdateCompanionBuilder,
      (
        StaffShiftPatternCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $StaffShiftPatternCacheEntriesTable,
          StaffShiftPatternCacheEntry
        >,
      ),
      StaffShiftPatternCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$StaffShiftInstanceCacheEntriesTableCreateCompanionBuilder =
    StaffShiftInstanceCacheEntriesCompanion Function({
      required String tenantId,
      required String scopeKey,
      required String instanceId,
      required int sortOrder,
      required String membershipId,
      required String branchId,
      Value<String?> patternId,
      required DateTime date,
      required String plannedStartTime,
      required String plannedEndTime,
      required String status,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StaffShiftInstanceCacheEntriesTableUpdateCompanionBuilder =
    StaffShiftInstanceCacheEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> scopeKey,
      Value<String> instanceId,
      Value<int> sortOrder,
      Value<String> membershipId,
      Value<String> branchId,
      Value<String?> patternId,
      Value<DateTime> date,
      Value<String> plannedStartTime,
      Value<String> plannedEndTime,
      Value<String> status,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StaffShiftInstanceCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $StaffShiftInstanceCacheEntriesTable> {
  $$StaffShiftInstanceCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedStartTime => $composableBuilder(
    column: $table.plannedStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedEndTime => $composableBuilder(
    column: $table.plannedEndTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StaffShiftInstanceCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StaffShiftInstanceCacheEntriesTable> {
  $$StaffShiftInstanceCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchId => $composableBuilder(
    column: $table.branchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedStartTime => $composableBuilder(
    column: $table.plannedStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedEndTime => $composableBuilder(
    column: $table.plannedEndTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StaffShiftInstanceCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StaffShiftInstanceCacheEntriesTable> {
  $$StaffShiftInstanceCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get membershipId => $composableBuilder(
    column: $table.membershipId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get patternId =>
      $composableBuilder(column: $table.patternId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get plannedStartTime => $composableBuilder(
    column: $table.plannedStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plannedEndTime => $composableBuilder(
    column: $table.plannedEndTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StaffShiftInstanceCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StaffShiftInstanceCacheEntriesTable,
          StaffShiftInstanceCacheEntry,
          $$StaffShiftInstanceCacheEntriesTableFilterComposer,
          $$StaffShiftInstanceCacheEntriesTableOrderingComposer,
          $$StaffShiftInstanceCacheEntriesTableAnnotationComposer,
          $$StaffShiftInstanceCacheEntriesTableCreateCompanionBuilder,
          $$StaffShiftInstanceCacheEntriesTableUpdateCompanionBuilder,
          (
            StaffShiftInstanceCacheEntry,
            BaseReferences<
              _$AppDatabase,
              $StaffShiftInstanceCacheEntriesTable,
              StaffShiftInstanceCacheEntry
            >,
          ),
          StaffShiftInstanceCacheEntry,
          PrefetchHooks Function()
        > {
  $$StaffShiftInstanceCacheEntriesTableTableManager(
    _$AppDatabase db,
    $StaffShiftInstanceCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StaffShiftInstanceCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$StaffShiftInstanceCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StaffShiftInstanceCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> instanceId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> membershipId = const Value.absent(),
                Value<String> branchId = const Value.absent(),
                Value<String?> patternId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> plannedStartTime = const Value.absent(),
                Value<String> plannedEndTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftInstanceCacheEntriesCompanion(
                tenantId: tenantId,
                scopeKey: scopeKey,
                instanceId: instanceId,
                sortOrder: sortOrder,
                membershipId: membershipId,
                branchId: branchId,
                patternId: patternId,
                date: date,
                plannedStartTime: plannedStartTime,
                plannedEndTime: plannedEndTime,
                status: status,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scopeKey,
                required String instanceId,
                required int sortOrder,
                required String membershipId,
                required String branchId,
                Value<String?> patternId = const Value.absent(),
                required DateTime date,
                required String plannedStartTime,
                required String plannedEndTime,
                required String status,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StaffShiftInstanceCacheEntriesCompanion.insert(
                tenantId: tenantId,
                scopeKey: scopeKey,
                instanceId: instanceId,
                sortOrder: sortOrder,
                membershipId: membershipId,
                branchId: branchId,
                patternId: patternId,
                date: date,
                plannedStartTime: plannedStartTime,
                plannedEndTime: plannedEndTime,
                status: status,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StaffShiftInstanceCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StaffShiftInstanceCacheEntriesTable,
      StaffShiftInstanceCacheEntry,
      $$StaffShiftInstanceCacheEntriesTableFilterComposer,
      $$StaffShiftInstanceCacheEntriesTableOrderingComposer,
      $$StaffShiftInstanceCacheEntriesTableAnnotationComposer,
      $$StaffShiftInstanceCacheEntriesTableCreateCompanionBuilder,
      $$StaffShiftInstanceCacheEntriesTableUpdateCompanionBuilder,
      (
        StaffShiftInstanceCacheEntry,
        BaseReferences<
          _$AppDatabase,
          $StaffShiftInstanceCacheEntriesTable,
          StaffShiftInstanceCacheEntry
        >,
      ),
      StaffShiftInstanceCacheEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncCheckpointEntriesTableTableManager get syncCheckpointEntries =>
      $$SyncCheckpointEntriesTableTableManager(_db, _db.syncCheckpointEntries);
  $$OfflineCommandQueueEntriesTableTableManager
  get offlineCommandQueueEntries =>
      $$OfflineCommandQueueEntriesTableTableManager(
        _db,
        _db.offlineCommandQueueEntries,
      );
  $$SaleOutageOrderEntriesTableTableManager get saleOutageOrderEntries =>
      $$SaleOutageOrderEntriesTableTableManager(
        _db,
        _db.saleOutageOrderEntries,
      );
  $$PolicyCacheEntriesTableTableManager get policyCacheEntries =>
      $$PolicyCacheEntriesTableTableManager(_db, _db.policyCacheEntries);
  $$CashSessionSnapshotEntriesTableTableManager
  get cashSessionSnapshotEntries =>
      $$CashSessionSnapshotEntriesTableTableManager(
        _db,
        _db.cashSessionSnapshotEntries,
      );
  $$CashSessionMovementCacheEntriesTableTableManager
  get cashSessionMovementCacheEntries =>
      $$CashSessionMovementCacheEntriesTableTableManager(
        _db,
        _db.cashSessionMovementCacheEntries,
      );
  $$CashSessionSaleCacheEntriesTableTableManager
  get cashSessionSaleCacheEntries =>
      $$CashSessionSaleCacheEntriesTableTableManager(
        _db,
        _db.cashSessionSaleCacheEntries,
      );
  $$MenuCacheScopesTableTableManager get menuCacheScopes =>
      $$MenuCacheScopesTableTableManager(_db, _db.menuCacheScopes);
  $$MenuItemCacheEntriesTableTableManager get menuItemCacheEntries =>
      $$MenuItemCacheEntriesTableTableManager(_db, _db.menuItemCacheEntries);
  $$MenuCategoryCacheEntriesTableTableManager get menuCategoryCacheEntries =>
      $$MenuCategoryCacheEntriesTableTableManager(
        _db,
        _db.menuCategoryCacheEntries,
      );
  $$MenuModifierGroupCacheEntriesTableTableManager
  get menuModifierGroupCacheEntries =>
      $$MenuModifierGroupCacheEntriesTableTableManager(
        _db,
        _db.menuModifierGroupCacheEntries,
      );
  $$MenuBranchCacheEntriesTableTableManager get menuBranchCacheEntries =>
      $$MenuBranchCacheEntriesTableTableManager(
        _db,
        _db.menuBranchCacheEntries,
      );
  $$AttendanceContextCacheEntriesTableTableManager
  get attendanceContextCacheEntries =>
      $$AttendanceContextCacheEntriesTableTableManager(
        _db,
        _db.attendanceContextCacheEntries,
      );
  $$AttendanceRecordCacheEntriesTableTableManager
  get attendanceRecordCacheEntries =>
      $$AttendanceRecordCacheEntriesTableTableManager(
        _db,
        _db.attendanceRecordCacheEntries,
      );
  $$StaffShiftScopeEntriesTableTableManager get staffShiftScopeEntries =>
      $$StaffShiftScopeEntriesTableTableManager(
        _db,
        _db.staffShiftScopeEntries,
      );
  $$StaffShiftBranchCacheEntriesTableTableManager
  get staffShiftBranchCacheEntries =>
      $$StaffShiftBranchCacheEntriesTableTableManager(
        _db,
        _db.staffShiftBranchCacheEntries,
      );
  $$StaffShiftMembershipCacheEntriesTableTableManager
  get staffShiftMembershipCacheEntries =>
      $$StaffShiftMembershipCacheEntriesTableTableManager(
        _db,
        _db.staffShiftMembershipCacheEntries,
      );
  $$StaffShiftPatternCacheEntriesTableTableManager
  get staffShiftPatternCacheEntries =>
      $$StaffShiftPatternCacheEntriesTableTableManager(
        _db,
        _db.staffShiftPatternCacheEntries,
      );
  $$StaffShiftInstanceCacheEntriesTableTableManager
  get staffShiftInstanceCacheEntries =>
      $$StaffShiftInstanceCacheEntriesTableTableManager(
        _db,
        _db.staffShiftInstanceCacheEntries,
      );
}
