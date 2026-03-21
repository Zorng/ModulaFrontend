import 'package:drift/drift.dart';

import 'package:modular_pos/core/storage/database_connection_stub.dart'
    if (dart.library.io) 'package:modular_pos/core/storage/database_connection_native.dart'
    if (dart.library.js_interop) 'package:modular_pos/core/storage/database_connection_web.dart';

QueryExecutor openAppDatabaseConnection() => openDatabaseConnection();
