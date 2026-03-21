import 'package:drift/drift.dart';

class SaleOutageOrderEntries extends Table {
  TextColumn get localIntentId => text()();

  TextColumn get orderNumber => text()();

  TextColumn get tenantId => text()();

  TextColumn get branchId => text()();

  TextColumn get accountId => text()();

  TextColumn get saleType => text()();

  TextColumn get paymentMethodRequested => text()();

  TextColumn get tenderCurrency => text()();

  RealColumn get cashReceivedUsd => real().withDefault(const Constant(0))();

  RealColumn get cashReceivedKhr => real().withDefault(const Constant(0))();

  RealColumn get totalUsd => real()();

  RealColumn get totalKhr => real()();

  TextColumn get linesJson => text()();

  TextColumn get state => text()();

  TextColumn get sourceMode => text()();

  TextColumn get backendOrderId => text().nullable()();

  DateTimeColumn get materializedAt => dateTime().nullable()();

  TextColumn get claimedPaymentMethod => text().nullable()();

  RealColumn get claimedTenderAmount => real().nullable()();

  TextColumn get proofImageUrl => text().nullable()();

  TextColumn get customerReference => text().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get claimRecordedAt => dateTime().nullable()();

  TextColumn get backendClaimId => text().nullable()();

  DateTimeColumn get claimSubmittedAt => dateTime().nullable()();

  TextColumn get lastErrorCode => text().nullable()();

  TextColumn get lastErrorMessage => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localIntentId};
}
