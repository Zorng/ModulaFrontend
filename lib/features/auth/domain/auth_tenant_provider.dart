import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current tenant ID in memory for scoping API requests.
final authTenantIdProvider = NotifierProvider<AuthTenantIdNotifier, String?>(
  AuthTenantIdNotifier.new,
);

class AuthTenantIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTenantId(String? tenantId) {
    final trimmed = (tenantId ?? '').trim();
    state = trimmed.isEmpty ? null : trimmed;
  }

  void clear() => state = null;
}
