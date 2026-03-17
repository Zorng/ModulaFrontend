import 'package:drift/drift.dart';

class AttendanceContextCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get branchId => text()();

  TextColumn get accountId => text()();

  BoolColumn get canCheckIn => boolean()();

  TextColumn get reasonCode => text().nullable()();

  TextColumn get reasonMessage => text().nullable()();

  TextColumn get activeShiftId => text().nullable()();

  TextColumn get activeShiftStartAt => text().nullable()();

  TextColumn get activeShiftEndAt => text().nullable()();

  TextColumn get activeAttendanceId => text().nullable()();

  TextColumn get activeAttendanceStartAt => text().nullable()();

  TextColumn get locationVerificationMode => text()();

  RealColumn get geofenceCenterLat => real().nullable()();

  RealColumn get geofenceCenterLng => real().nullable()();

  RealColumn get geofenceRadiusM => real().nullable()();

  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, branchId, accountId};
}

class AttendanceRecordCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get branchId => text()();

  TextColumn get accountId => text()();

  TextColumn get recordId => text()();

  TextColumn get employeeId => text()();

  TextColumn get type => text()();

  DateTimeColumn get occurredAt => dateTime()();

  DateTimeColumn get createdAt => dateTime()();

  RealColumn get locationLat => real().nullable()();

  RealColumn get locationLng => real().nullable()();

  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    tenantId,
    branchId,
    accountId,
    recordId,
  };
}
