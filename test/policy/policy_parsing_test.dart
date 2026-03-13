import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/policy/data/policy_api.dart';
import 'package:modular_pos/features/policy/data/dto/policy_dto.dart';
import 'package:modular_pos/features/policy/data/remote_policy_repository.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';

import '../test_utils/fixture_reader.dart';

class _MockPolicyApi extends Mock implements PolicyApi {}

void main() {
  test(
    'BranchPolicyDto preserves current-branch pricing and metadata values',
    () {
      final payload = readJsonMapFixture(
        'test/fixtures/policy/policy_bundle.json',
      );

      final dto = BranchPolicyDto.fromJson(payload);

      expect(dto.tenantId, 'tenant-1');
      expect(dto.branchId, 'branch-1');
      expect(dto.saleVatEnabled, isFalse);
      expect(dto.saleVatRatePercent, 0);
      expect(dto.saleFxRateKhrPerUsd, 4000);
      expect(dto.saleAllowPayLater, isTrue);
      expect(dto.createdAt, '2026-02-17T10:00:00.000Z');
      expect(dto.updatedAt, '2026-02-17T10:05:00.000Z');
    },
  );

  test('BranchPolicyDto parses the current-branch policy payload shape', () {
    final payload = readJsonMapFixture(
      'test/fixtures/policy/policy_bundle.json',
    );

    final dto = BranchPolicyDto.fromJson(payload);
    expect(dto.tenantId, 'tenant-1');
    expect(dto.branchId, 'branch-1');
    expect(dto.saleVatEnabled, isFalse);
    expect(dto.saleVatRatePercent, 0);
    expect(dto.saleFxRateKhrPerUsd, 4000);
    expect(dto.saleKhrRoundingEnabled, isTrue);
    expect(dto.saleKhrRoundingMode, 'UP');
    expect(dto.saleKhrRoundingGranularity, '100');
    expect(dto.saleAllowPayLater, isTrue);
    expect(dto.createdAt, '2026-02-17T10:00:00.000Z');
    expect(dto.updatedAt, '2026-02-17T10:05:00.000Z');

    final defaults = BranchPolicyDto.fromJson(const {
      'success': true,
      'data': {},
    });
    expect(defaults.saleVatEnabled, isFalse);
    expect(defaults.saleFxRateKhrPerUsd, 4100);
    expect(defaults.saleKhrRoundingMode, 'NEAREST');
    expect(defaults.saleKhrRoundingGranularity, '100');
    expect(defaults.saleAllowPayLater, isFalse);
  });

  test('PolicyRepository.fetchPolicy builds a BranchPolicy', () async {
    final payload = readJsonMapFixture(
      'test/fixtures/policy/policy_bundle.json',
    );

    final api = _MockPolicyApi();
    when(
      () => api.getCurrentBranchPolicy(),
    ).thenAnswer((_) async => BranchPolicyDto.fromJson(payload));

    final repo = RemotePolicyRepository(api);
    final branchPolicy = await repo.fetchCurrentBranchPolicy();

    expect(branchPolicy.tenantId, 'tenant-1');
    expect(branchPolicy.branchId, 'branch-1');
    expect(branchPolicy.saleFxRateKhrPerUsd, 4000);
    expect(branchPolicy.saleKhrRoundingEnabled, isTrue);
    expect(branchPolicy.saleAllowPayLater, isTrue);
  });

  test(
    'PolicyRepository.updateCurrency maps patch response directly',
    () async {
      final payload = readJsonMapFixture(
        'test/fixtures/policy/policy_bundle.json',
      );
      final dto = BranchPolicyDto.fromJson(payload);
      final api = _MockPolicyApi();

      when(
        () => api.updateCurrentBranchPolicy(saleFxRateKhrPerUsd: 4050),
      ).thenAnswer((_) async => dto);

      final repo = RemotePolicyRepository(api);
      final branchPolicy = await repo.updateCurrentBranchPolicy(
        saleFxRateKhrPerUsd: 4050,
      );

      expect(branchPolicy.saleFxRateKhrPerUsd, 4000);
      expect(branchPolicy.saleAllowPayLater, isTrue);
      verify(
        () => api.updateCurrentBranchPolicy(saleFxRateKhrPerUsd: 4050),
      ).called(1);
      verifyNever(() => api.getCurrentBranchPolicy());
    },
  );

  test('policy rounding values normalize to contract enums', () {
    final dto = BranchPolicyDto.fromJson(const {
      'success': true,
      'data': {
        'saleKhrRoundingMode': ' nearest ',
        'saleKhrRoundingGranularity': '250',
      },
    });

    expect(dto.saleKhrRoundingMode, BranchPolicyRoundingModes.nearest);
    expect(
      dto.saleKhrRoundingGranularity,
      BranchPolicyRoundingGranularities.hundred,
    );

    final payload = const UpdateBranchPolicyInputDto(
      saleKhrRoundingMode: 'down',
      saleKhrRoundingGranularity: ' 1000 ',
    ).toJson();

    expect(payload['saleKhrRoundingMode'], BranchPolicyRoundingModes.down);
    expect(
      payload['saleKhrRoundingGranularity'],
      BranchPolicyRoundingGranularities.thousand,
    );
  });
}
