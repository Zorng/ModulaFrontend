import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/policy/data/policy_api.dart';
import 'package:modular_pos/features/policy/data/dto/policy_bundle_dto.dart';
import 'package:modular_pos/features/policy/data/policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

import '../test_utils/fixture_reader.dart';

class _MockPolicyApi extends Mock implements PolicyApi {}

void main() {
  test('SalesPolicy parses policy bundle and overrides defaults', () {
    final payload = readJsonMapFixture('test/fixtures/policy/policy_bundle.json');

    final sales = SalesPolicy.fromJson(payload);

    expect(sales.saleVatEnabled, isFalse);
    expect(sales.saleVatRatePercent, 0);

    // Ensure backend-provided FX rate replaces the app default (4100).
    expect(sales.saleFxRateKhrPerUsd, 4000);
  });

  test('CashSessionPolicy parses cash-session policy and defaults correctly', () {
    final payload = readJsonMapFixture('test/fixtures/policy/policy_bundle.json');

    final cash = CashSessionPolicy.fromJson(payload);
    expect(cash.cashAllowPaidOut, isFalse);
    expect(cash.cashRequireRefundApproval, isFalse);
    expect(cash.cashAllowManualAdjustment, isFalse);

    // Defaults when policy keys are missing.
    final defaultCash = CashSessionPolicy.fromJson(
      const {
        'success': true,
        'data': {
          'cashSession': {},
        },
      },
    );
    expect(defaultCash.cashAllowPaidOut, isFalse);
    expect(defaultCash.cashRequireRefundApproval, isFalse);
    expect(defaultCash.cashAllowManualAdjustment, isFalse);

    // Accept legacy/alternative key grouping (`cash`).
    final legacyCash = CashSessionPolicy.fromJson(
      const {
        'data': {
          'cash': {
            'cashAllowPaidOut': true,
          },
        },
      },
    );
    expect(legacyCash.cashAllowPaidOut, isTrue);
  });

  test('PolicyRepository.fetchPolicies builds a PolicyBundle', () async {
    final payload = readJsonMapFixture('test/fixtures/policy/policy_bundle.json');

    final api = _MockPolicyApi();
    when(() => api.getPolicies()).thenAnswer(
      (_) async => PolicyBundleDto.fromJson(payload),
    );

    final repo = PolicyRepository(api);
    final bundle = await repo.fetchPolicies();

    expect(bundle.sales.saleFxRateKhrPerUsd, 4000);
    expect(bundle.cashSession.cashAllowPaidOut, isFalse);
  });
}
