import 'package:drift/drift.dart';

class MenuCacheScopes extends Table {
  TextColumn get tenantId => text()();

  TextColumn get scopeKey => text()();

  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, scopeKey};
}

class MenuItemCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get scopeKey => text()();

  TextColumn get itemId => text()();

  IntColumn get sortOrder => integer()();

  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, scopeKey, itemId};
}

class MenuCategoryCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get scopeKey => text()();

  TextColumn get categoryId => text()();

  IntColumn get sortOrder => integer()();

  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, scopeKey, categoryId};
}

class MenuModifierGroupCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get scopeKey => text()();

  TextColumn get groupId => text()();

  IntColumn get sortOrder => integer()();

  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, scopeKey, groupId};
}

class MenuBranchCacheEntries extends Table {
  TextColumn get tenantId => text()();

  TextColumn get scopeKey => text()();

  TextColumn get branchId => text()();

  IntColumn get sortOrder => integer()();

  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {tenantId, scopeKey, branchId};
}
