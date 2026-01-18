import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current tenant ID in memory for scoping API requests.
final authTenantIdProvider = StateProvider<String?>((ref) => null);
