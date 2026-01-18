import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/policy/data/policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';

import '../test_utils/riverpod_test_utils.dart';

class _MockPolicyRepository extends Mock implements PolicyRepository {}

void main() {
  test('PolicyNotifier.load updates state with fetched bundle', () async {
    final repo = _MockPolicyRepository();
    when(() => repo.fetchPolicies(branchId: any(named: 'branchId'))).thenAnswer(
      (_) async => const PolicyBundle(
        sales: SalesPolicy(saleFxRateKhrPerUsd: 4000),
        inventory: InventoryPolicy(inventoryAutoSubtractOnSale: true),
        cashSession: CashSessionPolicy(cashAllowPaidOut: true),
        attendance: AttendancePolicy(attendanceAllowManagerEdits: true),
      ),
    );

    final container = createTestContainer(
      overrides: [
        policyRepositoryProvider.overrideWithValue(repo),
      ],
    );

    final notifier = container.read(policyNotifierProvider.notifier);

    final future = notifier.load(branchId: 'branch-1');
    expect(container.read(policyNotifierProvider).isLoading, isTrue);
    await future;

    final state = container.read(policyNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.salesPolicy.saleFxRateKhrPerUsd, 4000);
    expect(state.inventoryPolicy.inventoryAutoSubtractOnSale, isTrue);
    expect(state.cashSessionPolicy.cashAllowPaidOut, isTrue);
    expect(state.attendancePolicy.attendanceAllowManagerEdits, isTrue);
  });

  test('PolicyNotifier.load captures errors and stops loading', () async {
    final repo = _MockPolicyRepository();
    when(() => repo.fetchPolicies(branchId: any(named: 'branchId'))).thenThrow(
      Exception('boom'),
    );

    final container = createTestContainer(
      overrides: [
        policyRepositoryProvider.overrideWithValue(repo),
      ],
    );

    final notifier = container.read(policyNotifierProvider.notifier);
    await notifier.load(branchId: 'branch-1');

    final state = container.read(policyNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, contains('boom'));
  });
}

