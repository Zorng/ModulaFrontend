import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';

class MockBranchRepository implements BranchRepository {
  final List<BranchListItem> _branches = <BranchListItem>[
    const BranchListItem(
      branchId: 'branch-001',
      tenantId: 'tenant-001',
      branchName: 'Olympic',
      status: 'ACTIVE',
      branchAddress: 'Street 2004',
      contactNumber: '+85512000009',
      khqrReceiverAccountId: null,
      khqrReceiverName: null,
    ),
    const BranchListItem(
      branchId: 'branch-002',
      tenantId: 'tenant-001',
      branchName: 'Central',
      status: 'ACTIVE',
      branchAddress: 'Street 315',
      contactNumber: '+85512000010',
      khqrReceiverAccountId: null,
      khqrReceiverName: null,
    ),
  ];

  BranchActivationDraft? _pendingDraft;
  int _nextId = 3;

  @override
  Future<List<BranchListItem>> loadAccessibleBranches() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<BranchListItem>.from(_branches);
  }

  @override
  Future<BranchListItem> getCurrentBranchProfile({
    String? accessTokenOverride,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _branches.first;
  }

  @override
  Future<BranchListItem> updateCurrentBranchKhqrReceiver({
    required String khqrReceiverAccountId,
    required String khqrReceiverName,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final current = _branches.first;
    final updated = current.copyWith(
      khqrReceiverAccountId: khqrReceiverAccountId,
      khqrReceiverName: khqrReceiverName,
    );
    _branches[0] = updated;
    return updated;
  }

  @override
  Future<BranchListItem> updateCurrentBranchAttendanceLocation({
    required String attendanceLocationVerificationMode,
    BranchWorkplaceLocation? workplaceLocation,
    String? intentId,
    String? accessTokenOverride,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final current = _branches.first;
    final updated = current.copyWith(
      attendanceLocationVerificationMode: attendanceLocationVerificationMode,
      workplaceLocation: workplaceLocation,
    );
    _branches[0] = updated;
    return updated;
  }

  @override
  Future<BranchActivationDraft> initiateBranchActivation({
    required String branchName,
    String? intentId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalizedName = branchName.trim();
    if (normalizedName.isEmpty) {
      throw const FormatException('branchName is required');
    }

    if (_pendingDraft != null) {
      return _pendingDraft!.copyWith(created: false);
    }

    final id = 'draft-${DateTime.now().millisecondsSinceEpoch}';
    final invoiceId = 'invoice-${DateTime.now().millisecondsSinceEpoch}';

    final draft = BranchActivationDraft(
      draftId: id,
      tenantId: 'tenant-001',
      branchName: normalizedName,
      activationType: 'ADDITIONAL_BRANCH',
      draftStatus: 'PENDING_PAYMENT',
      created: true,
      invoice: BranchActivationInvoice(
        invoiceId: invoiceId,
        invoiceType: 'FIRST_BRANCH_ACTIVATION',
        status: 'ISSUED',
        currency: 'USD',
        totalAmountUsd: '5.00',
        issuedAt: DateTime.now().toUtc(),
        paidAt: null,
      ),
    );
    _pendingDraft = draft;
    return draft;
  }

  @override
  Future<BranchActivationResult> confirmBranchActivation({
    required String draftId,
    required String paymentToken,
    String? intentId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final pending = _pendingDraft;
    if (pending == null || pending.draftId != draftId.trim()) {
      throw const FormatException('DRAFT_NOT_FOUND');
    }
    if (paymentToken.trim().toUpperCase() != 'PAID') {
      throw const FormatException('BRANCH_ACTIVATION_PAYMENT_REQUIRED');
    }

    final newBranchId = 'branch-${_nextId.toString().padLeft(3, '0')}';
    _nextId++;

    _branches.add(
      BranchListItem(
        branchId: newBranchId,
        tenantId: pending.tenantId,
        branchName: pending.branchName,
        status: 'ACTIVE',
        branchAddress: null,
        contactNumber: null,
        khqrReceiverAccountId: null,
        khqrReceiverName: null,
        isNew: true,
        shouldHighlight: true,
      ),
    );

    _pendingDraft = null;

    return BranchActivationResult(
      draftId: pending.draftId,
      branchId: newBranchId,
      tenantId: pending.tenantId,
      branchName: pending.branchName,
      activationType: pending.activationType,
      status: 'ACTIVE',
      invoiceId: pending.invoice.invoiceId,
      paymentConfirmationRef: 'mock:$newBranchId',
      created: true,
    );
  }

  @override
  Future<BranchContextTokens> selectBranchContext({
    required String branchId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return BranchContextTokens(
      accessToken: 'mock-access-token-$branchId',
      refreshToken: 'mock-refresh-token-$branchId',
      tenantId: 'tenant-001',
      branchId: branchId.trim(),
    );
  }
}

extension on BranchActivationDraft {
  BranchActivationDraft copyWith({bool? created}) {
    return BranchActivationDraft(
      draftId: draftId,
      tenantId: tenantId,
      branchName: branchName,
      activationType: activationType,
      draftStatus: draftStatus,
      invoice: invoice,
      created: created ?? this.created,
    );
  }
}
