import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runtime resource that should be reset/rebound when auth context changes.
///
/// Example consumers: SSE notification client, sync workers, live subscriptions.
abstract class ContextScopedRuntimeResource {
  bool get requiresTenantContext => true;

  bool get requiresBranchContext => true;

  FutureOr<void> onContextCleared();

  FutureOr<void> onContextChanged({
    required String accessToken,
    required String tenantId,
    required String branchId,
  });
}

/// Register context-scoped runtime resources here.
///
/// Default is empty; features can override/extend this provider when they add
/// long-lived connections that depend on auth context.
final contextScopedRuntimeResourcesProvider =
    Provider<List<ContextScopedRuntimeResource>>(
      (_) => const <ContextScopedRuntimeResource>[],
    );
