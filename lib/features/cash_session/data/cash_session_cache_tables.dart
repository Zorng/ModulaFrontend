import 'package:drift/drift.dart';

class CashSessionSnapshotEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get branchId => text()();

  TextColumn get sessionId => text()();

  TextColumn get openedByAccountId => text()();

  TextColumn get openedByName => text()();

  DateTimeColumn get openedAt => dateTime().nullable()();

  TextColumn get status => text()();

  RealColumn get openingFloatUsd => real()();

  RealColumn get openingFloatKhr => real()();

  DateTimeColumn get closedAt => dateTime().nullable()();

  TextColumn get closedByAccountId => text().nullable()();

  TextColumn get closedByName => text().nullable()();

  TextColumn get closeNote => text().nullable()();

  RealColumn get totalPaidInUsd => real()();

  RealColumn get totalPaidOutUsd => real()();

  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, branchId};
}

class CashSessionMovementCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get branchId => text()();

  TextColumn get sessionId => text()();

  TextColumn get movementId => text()();

  TextColumn get movementType => text()();

  RealColumn get amountUsd => real()();

  RealColumn get amountKhr => real()();

  TextColumn get reason => text().nullable()();

  TextColumn get sourceRefType => text()();

  TextColumn get sourceRefId => text().nullable()();

  TextColumn get recordedByAccountId => text()();

  DateTimeColumn get occurredAt => dateTime().nullable()();

  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    tenantId,
    branchId,
    sessionId,
    movementId,
  };
}

class CashSessionSaleCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get branchId => text()();

  TextColumn get sessionId => text()();

  TextColumn get saleId => text()();

  TextColumn get status => text()();

  TextColumn get paymentMethod => text()();

  TextColumn get saleType => text()();

  DateTimeColumn get finalizedAt => dateTime().nullable()();

  IntColumn get totalItems => integer()();

  RealColumn get grandTotalUsd => real()();

  RealColumn get grandTotalKhr => real()();

  TextColumn get cashierAccountId => text()();

  TextColumn get cashierName => text()();

  DateTimeColumn get voidedAt => dateTime().nullable()();

  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, branchId, sessionId, saleId};
}
