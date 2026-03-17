import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/storage/app_database.dart';
import 'package:modular_pos/features/policy/data/policy_cache_store.dart';
import 'package:modular_pos/features/policy/data/policy_error_codes.dart';
import 'package:modular_pos/features/policy/data/policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockPolicyRepository extends Mock implements PolicyRepository {}

void main() {
  test(
    'PolicyNotifier.load shows cached policy while refresh is still in flight',
    () async {
      final repo = _MockPolicyRepository();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final cacheStore = DriftPolicyCacheStore(database);
      await cacheStore.write(
        const BranchPolicy(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          saleFxRateKhrPerUsd: 4000,
        ),
      );

      final completer = Completer<BranchPolicy>();
      when(
        () => repo.fetchCurrentBranchPolicy(),
      ).thenAnswer((_) => completer.future);

      final container = createTestContainer(
        overrides: [
          policyRepositoryProvider.overrideWithValue(repo),
          appDatabaseProvider.overrideWithValue(database),
          policyBranchContextProvider.overrideWithValue(
            const PolicyBranchContext(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
            ),
          ),
        ],
      );

      final notifier = container.read(policyNotifierProvider.notifier);
      final loadFuture = notifier.load();
      await Future<void>.delayed(Duration.zero);

      final loadingState = container.read(policyNotifierProvider);
      expect(loadingState.isLoading, isTrue);
      expect(loadingState.branchPolicy.saleFxRateKhrPerUsd, 4000);

      completer.complete(
        const BranchPolicy(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          saleFxRateKhrPerUsd: 4050,
        ),
      );
      await loadFuture;

      final refreshedState = container.read(policyNotifierProvider);
      expect(refreshedState.isLoading, isFalse);
      expect(refreshedState.branchPolicy.saleFxRateKhrPerUsd, 4050);

      final cached = await cacheStore.read(
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );
      expect(cached?.saleFxRateKhrPerUsd, 4050);
    },
  );

  test(
    'PolicyNotifier.load keeps cached policy and marks it stale when refresh fails offline',
    () async {
      final repo = _MockPolicyRepository();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final cacheStore = DriftPolicyCacheStore(database);
      await cacheStore.write(
        const BranchPolicy(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          saleFxRateKhrPerUsd: 4000,
        ),
      );
      when(() => repo.fetchCurrentBranchPolicy()).thenThrow(
        const ApiClientException(
          message: 'This action requires online connectivity.',
          code: PolicyErrorCodes.offlineUnreachable,
        ),
      );

      final container = createTestContainer(
        overrides: [
          policyRepositoryProvider.overrideWithValue(repo),
          appDatabaseProvider.overrideWithValue(database),
          policyBranchContextProvider.overrideWithValue(
            const PolicyBranchContext(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
            ),
          ),
        ],
      );

      final notifier = container.read(policyNotifierProvider.notifier);
      await notifier.load();

      final state = container.read(policyNotifierProvider);
      expect(state.branchPolicy.saleFxRateKhrPerUsd, 4000);
      expect(state.isOffline, isTrue);
      expect(state.isStale, isTrue);
      expect(state.errorCode, PolicyErrorCodes.offlineUnreachable);
    },
  );

  test(
    'PolicyNotifier.load stops loading and keeps cached policy when refresh times out',
    () async {
      final repo = _MockPolicyRepository();
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final cacheStore = DriftPolicyCacheStore(database);
      await cacheStore.write(
        const BranchPolicy(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          saleFxRateKhrPerUsd: 4000,
        ),
      );

      final completer = Completer<BranchPolicy>();
      when(
        () => repo.fetchCurrentBranchPolicy(),
      ).thenAnswer((_) => completer.future);

      final container = createTestContainer(
        overrides: [
          policyRepositoryProvider.overrideWithValue(repo),
          appDatabaseProvider.overrideWithValue(database),
          policyBranchContextProvider.overrideWithValue(
            const PolicyBranchContext(
              tenantId: 'tenant-1',
              branchId: 'branch-1',
            ),
          ),
          policyRequestTimeoutProvider.overrideWithValue(
            const Duration(milliseconds: 10),
          ),
        ],
      );

      final notifier = container.read(policyNotifierProvider.notifier);
      await notifier.load();

      final state = container.read(policyNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.branchPolicy.saleFxRateKhrPerUsd, 4000);
      expect(state.isOffline, isTrue);
      expect(state.isStale, isTrue);
      expect(state.errorCode, PolicyErrorCodes.offlineUnreachable);
    },
  );

  test('PolicyNotifier.load updates state with fetched sales policy', () async {
    final repo = _MockPolicyRepository();
    when(
      () => repo.fetchCurrentBranchPolicy(),
    ).thenAnswer((_) async => const BranchPolicy(saleFxRateKhrPerUsd: 4000));

    final container = createTestContainer(
      overrides: [policyRepositoryProvider.overrideWithValue(repo)],
    );

    final notifier = container.read(policyNotifierProvider.notifier);

    final future = notifier.load();
    expect(container.read(policyNotifierProvider).isLoading, isTrue);
    await future;

    final state = container.read(policyNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.branchPolicy.saleFxRateKhrPerUsd, 4000);
  });

  test('PolicyNotifier.load captures errors and stops loading', () async {
    final repo = _MockPolicyRepository();
    when(() => repo.fetchCurrentBranchPolicy()).thenThrow(Exception('boom'));

    final container = createTestContainer(
      overrides: [policyRepositoryProvider.overrideWithValue(repo)],
    );

    final notifier = container.read(policyNotifierProvider.notifier);
    await notifier.load();

    final state = container.read(policyNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, contains('boom'));
  });

  test(
    'PolicyNotifier marks existing policy stale when refresh fails offline',
    () async {
      final repo = _MockPolicyRepository();
      when(() => repo.fetchCurrentBranchPolicy()).thenAnswer(
        (_) async => const BranchPolicy(
          tenantId: 'tenant-1',
          branchId: 'branch-1',
          saleFxRateKhrPerUsd: 4000,
        ),
      );
      when(
        () => repo.updateCurrentBranchPolicy(saleFxRateKhrPerUsd: 4050),
      ).thenThrow(
        const ApiClientException(
          message: 'This action requires online connectivity.',
          code: PolicyErrorCodes.offlineUnreachable,
        ),
      );

      final container = createTestContainer(
        overrides: [policyRepositoryProvider.overrideWithValue(repo)],
      );

      final notifier = container.read(policyNotifierProvider.notifier);
      await notifier.load();
      await notifier.updateCurrency(4050);

      final state = container.read(policyNotifierProvider);
      expect(state.branchPolicy.branchId, 'branch-1');
      expect(state.branchPolicy.saleFxRateKhrPerUsd, 4000);
      expect(state.isOffline, isTrue);
      expect(state.isStale, isTrue);
      expect(state.errorCode, PolicyErrorCodes.offlineUnreachable);
    },
  );

  test('PolicyNotifier normalizes backend policy reason codes', () async {
    final repo = _MockPolicyRepository();
    when(() => repo.fetchCurrentBranchPolicy()).thenThrow(
      const ApiClientException(
        message: 'Branch is frozen.',
        code: ' branch_frozen ',
      ),
    );

    final container = createTestContainer(
      overrides: [policyRepositoryProvider.overrideWithValue(repo)],
    );

    final notifier = container.read(policyNotifierProvider.notifier);
    await notifier.load();

    final state = container.read(policyNotifierProvider);
    expect(state.errorCode, PolicyErrorCodes.branchFrozen);
    expect(state.isOffline, isFalse);
  });
}
