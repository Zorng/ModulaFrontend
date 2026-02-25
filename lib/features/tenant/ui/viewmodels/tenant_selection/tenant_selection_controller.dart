import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/tenant/data/tenant_repository.dart';
import 'package:modular_pos/features/tenant/domain/models/tenant_provision_result.dart';
import 'package:modular_pos/features/tenant/ui/viewmodels/tenant_selection/tenant_selection_state.dart';

final tenantSelectionControllerProvider =
    NotifierProvider<TenantSelectionController, TenantSelectionState>(
      TenantSelectionController.new,
    );

class TenantSelectionController extends Notifier<TenantSelectionState> {
  String _searchQuery = '';
  TenantRoleFilter _selectedRoleFilter = TenantRoleFilter.all;
  TenantRepository get _repository => ref.read(tenantRepositoryProvider);

  @override
  TenantSelectionState build() {
    final memberships = ref.watch(
      loginControllerProvider.select(
        (value) => value.session?.memberships ?? const <TenantMembership>[],
      ),
    );

    return TenantSelectionState(
      memberships: memberships,
      searchQuery: _searchQuery,
      selectedRoleFilter: _selectedRoleFilter,
    );
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    state = state.copyWith(searchQuery: value);
  }

  void setRoleFilter(TenantRoleFilter value) {
    _selectedRoleFilter = value;
    state = state.copyWith(selectedRoleFilter: value);
  }

  void setRoleFilterByCode(String value) {
    setRoleFilter(TenantRoleFilterX.fromCode(value));
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedRoleFilter = TenantRoleFilter.all;
    state = state.copyWith(
      searchQuery: '',
      selectedRoleFilter: TenantRoleFilter.all,
    );
  }

  void clearCreateTenantFeedback() {
    state = state.copyWith(
      createTenantError: null,
      createTenantErrorCode: null,
      createTenantErrorStatusCode: null,
    );
  }

  Future<void> applyCreatedTenantMembership(
    TenantProvisionResult provisionResult,
  ) {
    return ref
        .read(loginControllerProvider.notifier)
        .upsertSessionTenantMembership(
          tenantId: provisionResult.tenantId,
          tenantName: provisionResult.tenantName,
          role: provisionResult.ownerRoleKey,
        );
  }

  Future<TenantProvisionResult?> createTenant(String tenantName) async {
    final normalizedName = tenantName.trim();
    if (normalizedName.isEmpty) {
      state = state.copyWith(
        createTenantError: 'Tenant name is required.',
        createTenantErrorCode: 'INVALID_INPUT',
        createTenantErrorStatusCode: 422,
      );
      return null;
    }

    state = state.copyWith(
      isCreatingTenant: true,
      createTenantError: null,
      createTenantErrorCode: null,
      createTenantErrorStatusCode: null,
    );
    try {
      final provisionResult = await _repository.createTenant(
        tenantName: normalizedName,
      );
      await applyCreatedTenantMembership(provisionResult);
      state = state.copyWith(isCreatingTenant: false);
      return provisionResult;
    } catch (error) {
      if (error is ApiClientException) {
        state = state.copyWith(
          isCreatingTenant: false,
          createTenantError: error.message,
          createTenantErrorCode: error.code,
          createTenantErrorStatusCode: error.statusCode,
        );
        return null;
      }

      state = state.copyWith(
        isCreatingTenant: false,
        createTenantError: 'Failed to create tenant.',
        createTenantErrorCode: null,
        createTenantErrorStatusCode: null,
      );
      return null;
    }
  }
}
