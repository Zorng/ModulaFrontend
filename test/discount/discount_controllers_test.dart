import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/discount/data/discount_error_codes.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/data/mock_discount_repository.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_detail_controller.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_form_controller.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_list_controller.dart';

import '../test_utils/riverpod_test_utils.dart';

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
