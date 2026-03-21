import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

QueryExecutor openDatabaseConnection() {
  return NativeDatabase.createInBackground(File('modula_local_cache.sqlite'));
}
