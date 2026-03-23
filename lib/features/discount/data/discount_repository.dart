import 'package:modular_pos/features/discount/domain/models/discount_eligibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/discount/data/discount_api.dart';
import 'package:modular_pos/features/discount/data/mock_discount_repository.dart';
import 'package:modular_pos/features/discount/data/remote_discount_repository.dart';
import 'package:modular_pos/features/discount/domain/models/discount_item_preflight_result.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';

abstract class DiscountRepository {
  Future<List<DiscountRule>> fetchDiscountRules({
    String? status,
    String? scope,
    String? branchId,
    String? search,
    int? limit,
    int? offset,
  });

  Future<DiscountRule> fetchDiscountRuleById(String ruleId);

  Future<DiscountRule> createDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  });

  Future<DiscountRule> updateDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  });

  Future<DiscountRule> updateDiscountRuleStatus({
    required String ruleId,
    required String status,
  });

  Future<DiscountItemPreflightResult> resolveEligibleItemsForBranch({
    required String branchId,
    required List<String> itemIds,
  });

  Future<List<DiscountEligibilityRule>> resolveDiscountEligibility({
    required String branchId,
    required DateTime occurredAt,
    required List<DiscountEligibilityLineInput> lines,
  });
}

final useMockDiscountRepositoryProvider = Provider<bool>(
  (ref) => AppEnv.useMockDiscountRepository,
);

final remoteDiscountRepositoryProvider = Provider<DiscountRepository>((ref) {
  final api = ref.watch(discountApiProvider);
  return RemoteDiscountRepository(api);
});

final mockDiscountRepositoryProvider = Provider<DiscountRepository>((ref) {
  return MockDiscountRepository();
});

final discountRepositoryProvider = Provider<DiscountRepository>((ref) {
  final useMock = ref.watch(useMockDiscountRepositoryProvider);
  if (useMock) {
    return ref.watch(mockDiscountRepositoryProvider);
  }
  return ref.watch(remoteDiscountRepositoryProvider);
});
