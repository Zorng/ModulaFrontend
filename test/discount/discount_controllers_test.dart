import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/discount/data/discount_error_codes.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/data/mock_discount_repository.dart';
import 'package:modular_pos/features/discount/domain/models/discount_eligibility.dart';
import 'package:modular_pos/features/discount/domain/models/discount_item_preflight_result.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_detail_controller.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_form_controller.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_list_controller.dart';

import '../test_utils/riverpod_test_utils.dart';

class _FetchDiscountRulesCall {
  const _FetchDiscountRulesCall({
    this.status,
    this.scope,
    this.branchId,
    this.search,
    this.limit,
    this.offset,
  });

  final String? status;
  final String? scope;
  final String? branchId;
  final String? search;
  final int? limit;
  final int? offset;
}

class _RecordingDiscountRepository implements DiscountRepository {
  _RecordingDiscountRepository({DiscountRepository? delegate})
    : _delegate = delegate ?? MockDiscountRepository();

  final DiscountRepository _delegate;
  final List<_FetchDiscountRulesCall> calls = <_FetchDiscountRulesCall>[];

  @override
  Future<List<DiscountRule>> fetchDiscountRules({
    String? status,
    String? scope,
    String? branchId,
    String? search,
    int? limit,
    int? offset,
  }) async {
    calls.add(
      _FetchDiscountRulesCall(
        status: status,
        scope: scope,
        branchId: branchId,
        search: search,
        limit: limit,
        offset: offset,
      ),
    );
    return _delegate.fetchDiscountRules(
      status: status,
      scope: scope,
      branchId: branchId,
      search: search,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<DiscountRule> fetchDiscountRuleById(String ruleId) {
    return _delegate.fetchDiscountRuleById(ruleId);
  }

  @override
  Future<DiscountRule> createDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  }) {
    return _delegate.createDiscountRule(
      rule: rule,
      confirmOverlap: confirmOverlap,
    );
  }

  @override
  Future<DiscountRule> updateDiscountRule({
    required DiscountRule rule,
    bool confirmOverlap = false,
  }) {
    return _delegate.updateDiscountRule(
      rule: rule,
      confirmOverlap: confirmOverlap,
    );
  }

  @override
  Future<DiscountRule> updateDiscountRuleStatus({
    required String ruleId,
    required String status,
  }) {
    return _delegate.updateDiscountRuleStatus(ruleId: ruleId, status: status);
  }

  @override
  Future<DiscountItemPreflightResult> resolveEligibleItemsForBranch({
    required String branchId,
    required List<String> itemIds,
  }) {
    return _delegate.resolveEligibleItemsForBranch(
      branchId: branchId,
      itemIds: itemIds,
    );
  }

  @override
  Future<List<DiscountEligibilityRule>> resolveDiscountEligibility({
    required String branchId,
    required DateTime occurredAt,
    required List<DiscountEligibilityLineInput> lines,
  }) {
    return _delegate.resolveDiscountEligibility(
      branchId: branchId,
      occurredAt: occurredAt,
      lines: lines,
    );
  }
}

class _MutableLoginController extends LoginController {
  @override
  LoginState build() => LoginState(session: _session('manager'));

  void setRole(String role) {
    state = LoginState(session: _session(role));
  }
}

AuthSession _session(String role) {
  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: role,
      tenantId: 'tenant-001',
    ),
    memberships: [
      TenantMembership(
        tenantId: 'tenant-001',
        tenantName: 'Tenant 1',
        role: role,
        branches: const [],
      ),
    ],
    activeTenantId: 'tenant-001',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
  );
}

void main() {
  group('discount controllers', () {
    test(
      'list controller derives read-only state for manager and loads rules',
      () async {
        final container = createTestContainer(
          overrides: [
            initialAuthSessionProvider.overrideWithValue(_session('manager')),
            discountRepositoryProvider.overrideWithValue(
              MockDiscountRepository(),
            ),
          ],
        );

        await container.read(discountListControllerProvider.notifier).load();
        final state = container.read(discountListControllerProvider);

        expect(state.canManage, isFalse);
        expect(state.isReadOnly, isTrue);
        expect(state.subtitle, contains('View tenant discount rules'));
        expect(state.rules, hasLength(2));
      },
    );

    test(
      'list controller forwards backend query filters and debounces search',
      () async {
        final repository = _RecordingDiscountRepository();
        final container = createTestContainer(
          overrides: [
            initialAuthSessionProvider.overrideWithValue(_session('manager')),
            discountRepositoryProvider.overrideWithValue(repository),
          ],
        );

        final notifier = container.read(
          discountListControllerProvider.notifier,
        );

        await notifier.load();
        expect(repository.calls, hasLength(1));
        expect(repository.calls.first.status, 'all');
        expect(repository.calls.first.scope, 'all');
        expect(repository.calls.first.search, isNull);

        notifier.setStatusFilter(DiscountStatuses.active);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(repository.calls, hasLength(2));
        expect(repository.calls.last.status, 'active');
        expect(repository.calls.last.scope, 'all');

        notifier.setScopeFilter(DiscountScopes.item);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(repository.calls, hasLength(3));
        expect(repository.calls.last.status, 'active');
        expect(repository.calls.last.scope, 'item');

        notifier.setSearchQuery('coffee');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(repository.calls, hasLength(3));

        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(repository.calls, hasLength(4));
        expect(repository.calls.last.status, 'active');
        expect(repository.calls.last.scope, 'item');
        expect(repository.calls.last.search, 'coffee');
      },
    );

    test(
      'list controller refresh preserves branch workspace filters',
      () async {
        final repository = _RecordingDiscountRepository();
        final container = createTestContainer(
          overrides: [
            initialAuthSessionProvider.overrideWithValue(_session('manager')),
            discountRepositoryProvider.overrideWithValue(repository),
          ],
        );

        final notifier = container.read(
          discountListControllerProvider.notifier,
        );

        await notifier.loadBranchWorkspace('branch-001');
        expect(repository.calls, hasLength(1));
        expect(repository.calls.single.branchId, 'branch-001');
        expect(repository.calls.single.status, 'active');

        await notifier.refresh();
        expect(repository.calls, hasLength(2));
        expect(repository.calls.last.branchId, 'branch-001');
        expect(repository.calls.last.status, 'active');
      },
    );

    test(
      'list controller can upsert an updated rule into current state',
      () async {
        final container = createTestContainer(
          overrides: [
            initialAuthSessionProvider.overrideWithValue(_session('manager')),
            discountRepositoryProvider.overrideWithValue(
              MockDiscountRepository(),
            ),
          ],
        );

        final notifier = container.read(
          discountListControllerProvider.notifier,
        );
        await notifier.load();
        notifier.upsertRule(
          container
              .read(discountListControllerProvider)
              .rules
              .first
              .copyWith(status: DiscountStatuses.active),
        );

        final updated = container
            .read(discountListControllerProvider)
            .rules
            .first;
        expect(updated.status, DiscountStatuses.active);
      },
    );

    test(
      'detail controller prevents status updates for read-only roles',
      () async {
        final container = createTestContainer(
          overrides: [
            initialAuthSessionProvider.overrideWithValue(_session('manager')),
            discountRepositoryProvider.overrideWithValue(
              MockDiscountRepository(),
            ),
          ],
        );

        final notifier = container.read(
          discountDetailControllerProvider.notifier,
        );
        await notifier.load('disc-002');
        final updated = await notifier.updateStatus(DiscountStatuses.active);
        final state = container.read(discountDetailControllerProvider);

        expect(state.canManage, isFalse);
        expect(state.isReadOnly, isTrue);
        expect(updated, isNull);
        expect(state.rule?.status, DiscountStatuses.inactive);
      },
    );

    test(
      'detail controller survives later login-state changes without provider error',
      () async {
        final container = createTestContainer(
          overrides: [
            loginControllerProvider.overrideWith(_MutableLoginController.new),
            discountRepositoryProvider.overrideWithValue(
              MockDiscountRepository(),
            ),
          ],
        );

        final detailNotifier = container.read(
          discountDetailControllerProvider.notifier,
        );
        await detailNotifier.load('disc-001');
        expect(
          container.read(discountDetailControllerProvider).canManage,
          false,
        );

        final loginNotifier =
            container.read(loginControllerProvider.notifier)
                as _MutableLoginController;
        loginNotifier.setRole('admin');
        await Future<void>.delayed(Duration.zero);

        final state = container.read(discountDetailControllerProvider);
        expect(state.canManage, false);
        expect(state.rule?.id, 'disc-001');
      },
    );

    test(
      'form controller survives later login-state changes without provider error',
      () async {
        final container = createTestContainer(
          overrides: [
            loginControllerProvider.overrideWith(_MutableLoginController.new),
            discountRepositoryProvider.overrideWithValue(
              MockDiscountRepository(),
            ),
          ],
        );

        final notifier = container.read(
          discountFormControllerProvider.notifier,
        );
        await notifier.load('disc-001');
        expect(container.read(discountFormControllerProvider).canManage, false);

        final loginNotifier =
            container.read(loginControllerProvider.notifier)
                as _MutableLoginController;
        loginNotifier.setRole('admin');
        await Future<void>.delayed(Duration.zero);

        final state = container.read(discountFormControllerProvider);
        expect(state.canManage, false);
        expect(state.initialRule?.id, 'disc-001');
      },
    );

    test(
      'form controller surfaces overlap warning and saves after confirmation retry',
      () async {
        final container = createTestContainer(
          overrides: [
            initialAuthSessionProvider.overrideWithValue(_session('admin')),
            discountRepositoryProvider.overrideWithValue(
              MockDiscountRepository(),
            ),
          ],
        );

        final notifier = container.read(
          discountFormControllerProvider.notifier,
        );
        notifier.setName('Weekend branch promo');
        notifier.setPercentageText('7');
        notifier.setScope(DiscountScopes.branchWide);
        notifier.setBranchId('branch-002');

        final firstAttempt = await notifier.save(tenantId: 'tenant-001');
        final warnedState = container.read(discountFormControllerProvider);
        final confirmedSave = await notifier.save(
          tenantId: 'tenant-001',
          confirmOverlap: true,
        );
        final savedState = container.read(discountFormControllerProvider);

        expect(firstAttempt, isNull);
        expect(warnedState.errorCode, DiscountErrorCodes.overlapWarning);
        expect(warnedState.overlapWarning, isNotNull);
        expect(
          warnedState.overlapWarning!.conflictingRuleIds,
          contains('disc-002'),
        );
        expect(confirmedSave, isNotNull);
        expect(savedState.initialRule?.id, isNotEmpty);
        expect(savedState.error, isNull);
      },
    );

    test(
      'form controller blocks saving currently eligible rules in edit mode',
      () async {
        final container = createTestContainer(
          overrides: [
            initialAuthSessionProvider.overrideWithValue(_session('admin')),
            discountRepositoryProvider.overrideWithValue(
              MockDiscountRepository(),
            ),
          ],
        );

        final notifier = container.read(
          discountFormControllerProvider.notifier,
        );
        await notifier.load('disc-001');
        final result = await notifier.save(tenantId: 'tenant-001');
        final state = container.read(discountFormControllerProvider);

        expect(state.isEditBlocked, isTrue);
        expect(result, isNull);
        expect(
          state.errorCode,
          DiscountErrorCodes.updateRequiresEffectiveInactive,
        );
      },
    );
  });
}
