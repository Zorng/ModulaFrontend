import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_access_gate.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils/riverpod_test_utils.dart';

class _SmokeLoginController extends LoginController {
  static AuthSession? session;

  @override
  LoginState build() => LoginState(session: session);
}

class _StaticPolicyNotifier extends PolicyNotifier {
  @override
  PolicyState build() {
    return const PolicyState(
      isLoading: false,
      branchPolicy: BranchPolicy(
        saleFxRateKhrPerUsd: 4000,
        saleAllowPayLater: true,
      ),
    );
  }
}

class _SmokeBranchRepository implements BranchRepository {
  BranchListItem _current = const BranchListItem(
    branchId: 'branch-1',
    tenantId: 'tenant-1',
    branchName: 'Branch A',
    status: 'ACTIVE',
  );

  @override
  Future<List<BranchListItem>> loadAccessibleBranches() async {
    return <BranchListItem>[_current];
  }

  @override
  Future<BranchListItem> getCurrentBranchProfile({
    String? accessTokenOverride,
  }) async => _current;

  @override
  Future<BranchListItem> updateCurrentBranchKhqrReceiver({
    required String khqrReceiverAccountId,
    required String khqrReceiverName,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    _current = BranchListItem(
      branchId: _current.branchId,
      tenantId: _current.tenantId,
      branchName: _current.branchName,
      status: _current.status,
      branchAddress: _current.branchAddress,
      contactNumber: _current.contactNumber,
      khqrReceiverAccountId: khqrReceiverAccountId,
      khqrReceiverName: khqrReceiverName,
    );
    return _current;
  }

  @override
  Future<BranchListItem> updateCurrentBranchAttendanceLocation({
    required String attendanceLocationVerificationMode,
    BranchWorkplaceLocation? workplaceLocation,
    String? intentId,
    String? accessTokenOverride,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BranchActivationDraft> initiateBranchActivation({
    required String branchName,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BranchActivationResult> confirmBranchActivation({
    required String draftId,
    required String paymentToken,
    String? intentId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BranchContextTokens> selectBranchContext({required String branchId}) {
    throw UnimplementedError();
  }
}

AuthSession _session() {
  const branches = [
    UserBranch(
      id: 'assign-1',
      name: 'Branch A',
      role: 'admin',
      active: true,
      branchId: 'branch-1',
    ),
  ];

  return AuthSession(
    user: User(
      id: 'user-1',
      name: 'Tester',
      role: 'ADMIN',
      tenantId: 'tenant-1',
      branches: branches,
    ),
    memberships: const [
      TenantMembership(
        membershipId: 'membership-1',
        tenantId: 'tenant-1',
        tenantName: 'Tenant 1',
        role: 'ADMIN',
        branches: branches,
      ),
    ],
    activeTenantId: 'tenant-1',
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _SmokeLoginController.session = _session();
  });

  test(
    'smoke branch KHQR setup and cashier generate/cancel/regenerate/finalize flow',
    () async {
      final branchRepo = _SmokeBranchRepository();
      final saleRepo = MockSaleRepository();
      saleRepo.configureContext(
        activeBranchId: 'branch-1',
        khqrReceiverConfigured: false,
      );

      final container = createTestContainer(
        overrides: [
          loginControllerProvider.overrideWith(_SmokeLoginController.new),
          branchRepositoryProvider.overrideWithValue(branchRepo),
          policyNotifierProvider.overrideWith(_StaticPolicyNotifier.new),
          saleRepositoryProvider.overrideWithValue(saleRepo),
          saleAccessGateProvider.overrideWithValue(
            const SaleAccessGate(
              branchId: 'branch-1',
              contextLoading: false,
              branchActive: true,
              branchFrozen: false,
              cashSessionOpen: true,
              canMutateCart: true,
              canCheckout: true,
              canPlacePayLater: true,
            ),
          ),
        ],
      );

      final branchNotifier = container.read(branchControllerProvider.notifier);
      await branchNotifier.loadCurrentBranchProfile();
      expect(
        container
            .read(branchControllerProvider)
            .currentBranchProfile
            ?.khqrReceiverAccountId,
        isNull,
      );

      await branchNotifier.updateCurrentBranchKhqrReceiver(
        khqrReceiverAccountId: 'bakong-001',
        khqrReceiverName: 'Branch A KHQR',
      );
      final branchState = container.read(branchControllerProvider);
      expect(
        branchState.currentBranchProfile?.khqrReceiverAccountId,
        'bakong-001',
      );
      expect(
        branchState.currentBranchProfile?.khqrReceiverName,
        'Branch A KHQR',
      );

      // Simulate backend branch KHQR config becoming effective for sale flow.
      saleRepo.configureContext(khqrReceiverConfigured: true);

      final cartNotifier = container.read(saleCartProvider.notifier);
      const item = MenuItem(
        id: 'menu-1',
        name: 'Milk Tea',
        categoryId: 'tea',
        price: 1.5,
      );
      const selection = SaleItemSelectionResult(
        item: item,
        quantity: 1,
        selectedOptionIds: {},
        selectedOptions: {},
        addonTotalUsd: 0,
        unitPriceUsd: 1.5,
        lineTotalUsd: 1.5,
      );

      await cartNotifier.addSelection(selection);
      await cartNotifier.setPaymentMethod('qr');
      final readyState = container.read(saleCartProvider);
      expect(readyState.khqrStatus, SaleKhqrUiStates.readyToGenerate);

      await cartNotifier.generateKhqrAttempt();

      final generated = container.read(saleCartProvider);
      expect(generated.khqrStatus, SaleKhqrUiStates.waitingForPayment);
      expect(generated.khqrQrPayload, isNotNull);
      expect(generated.khqrToAccountId, 'mock-bakong-account');
      final originalMd5 = generated.khqrMd5;

      await cartNotifier.cancelKhqrAttempt();
      final cancelled = container.read(saleCartProvider);
      expect(cancelled.khqrStatus, SaleKhqrUiStates.cancelled);
      expect(cancelled.khqrMd5, isNull);

      await cartNotifier.setPaymentMethod('cash');
      await cartNotifier.setPaymentMethod('qr');
      final readyToRegenerate = container.read(saleCartProvider);
      expect(readyToRegenerate.khqrStatus, SaleKhqrUiStates.readyToGenerate);

      await cartNotifier.generateKhqrAttempt();
      final regenerated = container.read(saleCartProvider);
      expect(regenerated.khqrStatus, SaleKhqrUiStates.waitingForPayment);
      expect(regenerated.khqrMd5, isNotNull);
      expect(regenerated.khqrMd5, isNot(originalMd5));

      await cartNotifier.checkKhqrStatus();
      await cartNotifier.checkKhqrStatus();
      final confirmed = container.read(saleCartProvider);
      expect(confirmed.khqrStatus, SaleKhqrUiStates.paidConfirmed);
      expect(confirmed.khqrMd5, isNotNull);

      final result = await cartNotifier.checkout();
      expect(result.summary.paymentMethod, 'qr');
      expect(result.receipt?.receiptId, isNotEmpty);
      expect(
        container.read(saleCartProvider).lastReceipt?.receiptId,
        result.receiptId,
      );
    },
  );
}
