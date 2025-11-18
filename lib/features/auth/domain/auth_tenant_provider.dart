import 'package:flutter_riverpod/legacy.dart';

/// Holds the current tenant ID in memory for scoping API requests.
final authTenantIdProvider = StateProvider<String?>((ref) => null);

