import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';

enum TenantRoleFilter { all, admin, member }

extension TenantRoleFilterX on TenantRoleFilter {
  String get code {
    return switch (this) {
      TenantRoleFilter.all => '__all_roles__',
      TenantRoleFilter.admin => 'ADMIN',
      TenantRoleFilter.member => 'MEMBER',
    };
  }

  String get label {
    return switch (this) {
      TenantRoleFilter.all => 'All roles',
      TenantRoleFilter.admin => 'Admin',
      TenantRoleFilter.member => 'Member',
    };
  }

  int get sortOrder {
    return switch (this) {
      TenantRoleFilter.all => 0,
      TenantRoleFilter.admin => 1,
      TenantRoleFilter.member => 2,
    };
  }

  static TenantRoleFilter fromRawRole(String? rawRole) {
    final normalized = (rawRole ?? '').trim().toUpperCase();
    return switch (normalized) {
      'OWNER' || 'ADMIN' || 'SUPER_ADMIN' => TenantRoleFilter.admin,
      'MEMBER' ||
      'MANAGER' ||
      'CASHIER' ||
      'STAFF' ||
      'EMPLOYEE' ||
      'USER' ||
      'VIEWER' => TenantRoleFilter.member,
      _ => TenantRoleFilter.member,
    };
  }

  static TenantRoleFilter fromCode(String? code) {
    final normalized = (code ?? '').trim().toUpperCase();
    return switch (normalized) {
      '__ALL_ROLES__' => TenantRoleFilter.all,
      'ADMIN' => TenantRoleFilter.admin,
      'MEMBER' => TenantRoleFilter.member,
      _ => fromRawRole(normalized),
    };
  }
}

class TenantSelectionState {
  static const Object _unset = Object();

  TenantSelectionState({
    this.memberships = const <TenantMembership>[],
    this.searchQuery = '',
    this.selectedRoleFilter = TenantRoleFilter.all,
    this.isCreatingTenant = false,
    this.createTenantError,
    this.createTenantErrorCode,
    this.createTenantErrorStatusCode,
    List<TenantMembershipSearchIndex>? indexedMemberships,
  }) : _indexedMemberships =
           indexedMemberships ??
           memberships
               .map(TenantMembershipSearchIndex.fromMembership)
               .toList(growable: false);

  final List<TenantMembership> memberships;
  final String searchQuery;
  final TenantRoleFilter selectedRoleFilter;
  final bool isCreatingTenant;
  final String? createTenantError;
  final String? createTenantErrorCode;
  final int? createTenantErrorStatusCode;
  // Precomputed normalized values used by search/filter to avoid repeated
  // string normalization work on every getter call.
  final List<TenantMembershipSearchIndex> _indexedMemberships;

  TenantSelectionState copyWith({
    List<TenantMembership>? memberships,
    String? searchQuery,
    TenantRoleFilter? selectedRoleFilter,
    bool? isCreatingTenant,
    Object? createTenantError = _unset,
    Object? createTenantErrorCode = _unset,
    Object? createTenantErrorStatusCode = _unset,
  }) {
    final nextMemberships = memberships ?? this.memberships;
    return TenantSelectionState(
      memberships: nextMemberships,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRoleFilter: selectedRoleFilter ?? this.selectedRoleFilter,
      isCreatingTenant: isCreatingTenant ?? this.isCreatingTenant,
      createTenantError: identical(createTenantError, _unset)
          ? this.createTenantError
          : createTenantError as String?,
      createTenantErrorCode: identical(createTenantErrorCode, _unset)
          ? this.createTenantErrorCode
          : createTenantErrorCode as String?,
      createTenantErrorStatusCode:
          identical(createTenantErrorStatusCode, _unset)
          ? this.createTenantErrorStatusCode
          : createTenantErrorStatusCode as int?,
      indexedMemberships: identical(nextMemberships, this.memberships)
          ? _indexedMemberships
          : null,
    );
  }

  List<TenantRoleFilter> get availableRoleFilters {
    final values = <TenantRoleFilter>{
      TenantRoleFilter.all,
      ..._indexedMemberships.map((item) => item.roleFilter),
    };
    final sorted = values.toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted;
  }

  List<TenantMembership> get visibleMemberships {
    final query = searchQuery.trim().toLowerCase();

    return _indexedMemberships
        .where((item) {
          final matchesQuery = query.isEmpty || item.searchText.contains(query);
          final matchesRole =
              selectedRoleFilter == TenantRoleFilter.all ||
              item.roleFilter == selectedRoleFilter;
          return matchesQuery && matchesRole;
        })
        .map((item) => item.membership)
        .toList(growable: false);
  }
}

class TenantMembershipSearchIndex {
  const TenantMembershipSearchIndex({
    required this.membership,
    required this.roleFilter,
    required this.searchText,
  });

  final TenantMembership membership;
  final TenantRoleFilter roleFilter;
  final String searchText;

  factory TenantMembershipSearchIndex.fromMembership(
    TenantMembership membership,
  ) {
    final roleFilter = TenantRoleFilterX.fromRawRole(membership.role);
    final tenantName = membership.tenantName.trim().toLowerCase();
    final tenantId = membership.tenantId.trim().toLowerCase();
    final roleCode = roleFilter.code.toLowerCase();

    final searchText = '$tenantName|$tenantId|$roleCode';
    return TenantMembershipSearchIndex(
      membership: membership,
      roleFilter: roleFilter,
      searchText: searchText,
    );
  }
}
