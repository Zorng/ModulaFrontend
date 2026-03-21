import 'package:drift/drift.dart';

class OfflineCommandQueueEntries extends Table {
  TextColumn get clientOpId => text()();

  TextColumn get operationType => text()();

  TextColumn get tenantId => text().withDefault(const Constant(''))();

  TextColumn get branchId => text().withDefault(const Constant(''))();

  TextColumn get accountId => text().withDefault(const Constant(''))();

  DateTimeColumn get occurredAt => dateTime()();

  TextColumn get payloadJson => text()();

  TextColumn get dependsOnClientOpId => text().nullable()();

  TextColumn get status => text()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  TextColumn get lastErrorCode => text().nullable()();

  TextColumn get lastErrorMessage => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {clientOpId};
}
