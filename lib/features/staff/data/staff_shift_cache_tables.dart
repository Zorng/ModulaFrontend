import 'package:drift/drift.dart';

class StaffShiftScopeEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get scopeKey => text()();

  TextColumn get branchId => text()();

  TextColumn get membershipId => text().withDefault(const Constant(''))();

  TextColumn get fromDate => text()();

  TextColumn get toDate => text()();

  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, scopeKey};
}

class StaffShiftBranchCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get branchId => text()();

  IntColumn get sortOrder => integer()();

  TextColumn get branchName => text()();

  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, branchId};
}

class StaffShiftMembershipCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get membershipId => text()();

  IntColumn get sortOrder => integer()();

  TextColumn get accountId => text()();

  TextColumn get roleKey => text()();

  TextColumn get membershipStatus => text()();

  TextColumn get phone => text()();

  TextColumn get firstName => text().nullable()();

  TextColumn get lastName => text().nullable()();

  TextColumn get staffProfileStatus => text().nullable()();

  DateTimeColumn get invitedAt => dateTime().nullable()();

  DateTimeColumn get acceptedAt => dateTime().nullable()();

  DateTimeColumn get rejectedAt => dateTime().nullable()();

  DateTimeColumn get revokedAt => dateTime().nullable()();

  TextColumn get pendingBranchIdsJson => text()();

  TextColumn get activeBranchIdsJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, membershipId};
}

class StaffShiftPatternCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get scopeKey => text()();

  TextColumn get patternId => text()();

  IntColumn get sortOrder => integer()();

  TextColumn get membershipId => text()();

  TextColumn get branchId => text()();

  TextColumn get daysOfWeekJson => text()();

  TextColumn get plannedStartTime => text()();

  TextColumn get plannedEndTime => text()();

  TextColumn get status => text()();

  DateTimeColumn get effectiveFrom => dateTime().nullable()();

  DateTimeColumn get effectiveTo => dateTime().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, scopeKey, patternId};
}

class StaffShiftInstanceCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get scopeKey => text()();

  TextColumn get instanceId => text()();

  IntColumn get sortOrder => integer()();

  TextColumn get membershipId => text()();

  TextColumn get branchId => text()();

  TextColumn get patternId => text().nullable()();

  DateTimeColumn get date => dateTime()();

  TextColumn get plannedStartTime => text()();

  TextColumn get plannedEndTime => text()();

  TextColumn get status => text()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, scopeKey, instanceId};
}
