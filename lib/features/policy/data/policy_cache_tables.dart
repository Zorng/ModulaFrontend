import 'package:drift/drift.dart';

class PolicyCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get branchId => text()();

  BoolColumn get saleVatEnabled => boolean()();

  RealColumn get saleVatRatePercent => real()();

  RealColumn get saleFxRateKhrPerUsd => real()();

  BoolColumn get saleKhrRoundingEnabled => boolean()();

  TextColumn get saleKhrRoundingMode => text()();

  TextColumn get saleKhrRoundingGranularity => text()();

  BoolColumn get saleAllowPayLater => boolean()();

  BoolColumn get saleAllowManualExternalPaymentClaim =>
      boolean().withDefault(const Constant(false))();

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  DateTimeColumn get cachedAt => dateTime()();

  TextColumn get syncCursorApplied => text().nullable()();

  DateTimeColumn get lastPullAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, branchId};
}
