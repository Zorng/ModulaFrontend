import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

const _databaseName = 'modula_local_cache';

QueryExecutor openDatabaseConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
      final fileSystem = await IndexedDbFileSystem.open(dbName: _databaseName);
      sqlite3.registerVirtualFileSystem(fileSystem, makeDefault: true);

      return DatabaseConnection(
        WasmDatabase(
          sqlite3: sqlite3,
          path: _databaseName,
          fileSystem: fileSystem,
        ),
      );
    }),
  );
}
