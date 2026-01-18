import 'dart:convert';
import 'dart:io';

/// Reads a fixture file from the repository and returns its contents as a string.
///
/// Typical usage:
/// ```dart
/// final json = readFixture('test/fixtures/auth/login_single_tenant.json');
/// ```
String readFixture(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'Fixture not found: $path (cwd: ${Directory.current.path})',
    );
  }
  return file.readAsStringSync();
}

/// Convenience helper for building a fixture path under `test/fixtures/`.
///
/// Example:
/// ```dart
/// final data = readJsonMapFixture(fixturePath('auth/login_single_tenant.json'));
/// ```
String fixturePath(String relativePath) => 'test/fixtures/$relativePath';

/// Reads a JSON fixture and returns a decoded object.
dynamic readJsonFixture(String path) {
  return jsonDecode(readFixture(path));
}

/// Reads a JSON fixture and returns a map.
Map<String, dynamic> readJsonMapFixture(String path) {
  final decoded = readJsonFixture(path);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  throw StateError(
    'Expected JSON object at $path but got ${decoded.runtimeType}',
  );
}
