import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/branchV2/data/dto/branch_dto.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';

/// Maps Branch DTOs from `/v0` endpoints into Branch domain models.
class BranchMapper {
  const BranchMapper._();

  static BranchListItem toBranchListItem(
    BranchAccessibleBranchDto dto, {
    bool isNew = false,
    bool shouldHighlight = false,
  }) {
    final branchId = dto.branchId.trim();
    final fallbackName = branchId.isEmpty ? 'Unknown Branch' : branchId;
    final branchName = dto.branchName.trim().isEmpty
        ? fallbackName
        : dto.branchName.trim();

    final normalizedStatus = dto.status.trim().toUpperCase();
    final status = normalizedStatus.isEmpty ? 'UNKNOWN' : normalizedStatus;

    return BranchListItem(
      branchId: branchId,
      tenantId: dto.tenantId.trim(),
      branchName: branchName,
      status: status,
      branchAddress: _nullableTrim(dto.branchAddress),
      contactNumber: _nullableTrim(dto.contactNumber),
      khqrReceiverAccountId: _nullableTrim(dto.khqrReceiverAccountId),
      khqrReceiverName: _nullableTrim(dto.khqrReceiverName),
      isNew: isNew,
      shouldHighlight: shouldHighlight,
    );
  }

  static List<BranchListItem> toBranchListItems(
    List<BranchAccessibleBranchDto> dtos, {
    String? newBranchId,
    String? highlightBranchId,
  }) {
    final normalizedNewId = (newBranchId ?? '').trim();
    final normalizedHighlightId = (highlightBranchId ?? '').trim();

    return dtos
        .map(
          (dto) => toBranchListItem(
            dto,
            isNew: normalizedNewId.isNotEmpty &&
                dto.branchId.trim() == normalizedNewId,
            shouldHighlight: normalizedHighlightId.isNotEmpty &&
                dto.branchId.trim() == normalizedHighlightId,
          ),
        )
        .toList(growable: false);
  }

  static BranchContextTokens toContextTokens(BranchContextTokenResultDto dto) {
    return BranchContextTokens(
      accessToken: dto.accessToken.trim(),
      refreshToken: dto.refreshToken.trim(),
      tenantId: _nullableTrim(dto.tenantId),
      branchId: _nullableTrim(dto.branchId),
    );
  }

  static BranchActivationDraft toActivationDraft(
    BranchActivationInitiateDto dto,
  ) {
    return BranchActivationDraft(
      draftId: dto.draftId.trim(),
      tenantId: dto.tenantId.trim(),
      branchName: dto.branchName.trim(),
      activationType: dto.activationType.trim().toUpperCase(),
      draftStatus: dto.draftStatus.trim().toUpperCase(),
      created: dto.created,
      invoice: toActivationInvoice(dto.invoice),
    );
  }

  static BranchActivationInvoice toActivationInvoice(
    BranchActivationInvoiceDto dto,
  ) {
    return BranchActivationInvoice(
      invoiceId: dto.invoiceId.trim(),
      invoiceType: dto.invoiceType.trim().toUpperCase(),
      status: dto.status.trim().toUpperCase(),
      currency: dto.currency.trim().toUpperCase(),
      totalAmountUsd: dto.totalAmountUsd.trim(),
      issuedAt: dto.issuedAt,
      paidAt: dto.paidAt,
    );
  }

  static BranchActivationResult toActivationResult(
    BranchActivationConfirmDto dto,
  ) {
    return BranchActivationResult(
      draftId: dto.draftId.trim(),
      branchId: dto.branchId.trim(),
      tenantId: dto.tenantId.trim(),
      branchName: dto.branchName.trim(),
      activationType: dto.activationType.trim().toUpperCase(),
      status: dto.status.trim().toUpperCase(),
      invoiceId: dto.invoiceId.trim(),
      paymentConfirmationRef: dto.paymentConfirmationRef.trim(),
      created: dto.created,
    );
  }

  /// Resolves effective tenant role for the currently active tenant context.
  static BranchTenantAccess resolveTenantAccess({
    required String? activeTenantId,
    required List<TenantMembership> memberships,
  }) {
    final tenantId = _nullableTrim(activeTenantId);
    if (tenantId == null) {
      return const BranchTenantAccess(
        activeTenantId: null,
        roleKey: '',
        canManageTenant: false,
        membershipId: '',
      );
    }

    TenantMembership? matchedMembership;
    for (final membership in memberships) {
      if (membership.tenantId.trim() == tenantId) {
        matchedMembership = membership;
        break;
      }
    }

    final roleKey = (matchedMembership?.role ?? '').trim().toUpperCase();
    final canManageTenant = roleKey == 'OWNER' || roleKey == 'ADMIN';

    return BranchTenantAccess(
      activeTenantId: tenantId,
      roleKey: roleKey,
      canManageTenant: canManageTenant,
      membershipId: (matchedMembership?.membershipId ?? '').trim(),
    );
  }

  static String? _nullableTrim(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }
}
