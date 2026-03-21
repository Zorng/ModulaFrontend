import 'package:drift/drift.dart';

QueryExecutor openDatabaseConnection() {
  throw UnsupportedError(
    'No local database connection is available on this platform.',
  );
}
