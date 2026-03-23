import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/discount/data/discount_error_codes.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_list_state.dart';

final discountListControllerProvider =
    NotifierProvider<DiscountListController, DiscountListState>(
      DiscountListController.new,
    );

class DiscountListController extends Notifier<DiscountListState> {
  static const _searchDebounceDuration = Duration(milliseconds: 250);

  DiscountRepository get _repo => ref.read(discountRepositoryProvider);
  Timer? _searchDebounce;
  int _requestEpoch = 0;

  @override
  DiscountListState build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    final session = ref.watch(
      loginControllerProvider.select((value) => value.session),
    );
    return DiscountListState(canManage: _canManage(session));
  }

  Future<void> load({
    String? branchId,
    String? statusFilter,
    String? scopeFilter,
    String? searchQuery,
  }) async {
    final nextState = state.copyWith(
      branchIdFilter: branchId,
      statusFilter: statusFilter,
      scopeFilter: scopeFilter,
      searchQuery: searchQuery,
    );
    if (nextState != state) {
      state = nextState;
    }
    final requestEpoch = ++_requestEpoch;
    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final rules = await _repo.fetchDiscountRules(
        status: _backendStatus(nextState.statusFilter),
        scope: _backendScope(nextState.scopeFilter),
        branchId: _backendBranchId(nextState.branchIdFilter),
        search: _backendSearch(nextState.searchQuery),
      );
      if (requestEpoch != _requestEpoch) return;
      state = state.copyWith(
        isLoading: false,
        error: null,
        errorCode: null,
        rules: rules,
      );
    } catch (error) {
      if (requestEpoch != _requestEpoch) return;
      final mapped = _mapError(error);
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<void> refresh() {
    return load(
      branchId: state.branchIdFilter,
      statusFilter: state.statusFilter,
      scopeFilter: state.scopeFilter,
      searchQuery: state.searchQuery,
    );
  }

  Future<void> loadTenantWorkspace() {
    return load(
      branchId: null,
      statusFilter: 'ALL',
      scopeFilter: 'ALL',
      searchQuery: '',
    );
  }

  Future<void> loadBranchWorkspace(String branchId) {
    return load(
      branchId: branchId.trim(),
      statusFilter: 'ACTIVE',
      scopeFilter: 'ALL',
      searchQuery: '',
    );
  }

  void upsertRule(DiscountRule rule) {
    final index = state.rules.indexWhere((entry) => entry.id == rule.id);
    if (index < 0) return;
    final nextRules = [...state.rules]..[index] = rule;
    state = state.copyWith(rules: nextRules);
  }

  void setSearchQuery(String value) {
    if (state.searchQuery == value) return;
    state = state.copyWith(searchQuery: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      unawaited(load());
    });
  }

  void setStatusFilter(String value) {
    if (state.statusFilter == value) return;
    state = state.copyWith(statusFilter: value);
    unawaited(load());
  }

  void setScopeFilter(String value) {
    if (state.scopeFilter == value) return;
    state = state.copyWith(scopeFilter: value);
    unawaited(load());
  }
}

({String message, String? code}) _mapError(Object error) {
  if (error is ApiClientException) {
    return (
      message: error.message,
      code: DiscountErrorCodes.normalize(error.code),
    );
  }
  return (message: error.toString(), code: null);
}

bool _canManage(Object? session) {
  final role = resolveSessionAuthRole(session as dynamic);
  return role == AuthRole.admin || role == AuthRole.owner;
}

String? _backendStatus(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.isEmpty) return null;
  return normalized.toLowerCase();
}

String? _backendScope(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.isEmpty) return null;
  return normalized == 'BRANCH_WIDE' ? 'branch_wide' : normalized.toLowerCase();
}

String? _backendSearch(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String? _backendBranchId(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : normalized;
}
