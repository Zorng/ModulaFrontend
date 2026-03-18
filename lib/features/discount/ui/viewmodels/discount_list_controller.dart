import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/discount/data/discount_error_codes.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/ui/viewmodels/discount_list_state.dart';

final discountListControllerProvider =
    NotifierProvider<DiscountListController, DiscountListState>(
      DiscountListController.new,
    );

class DiscountListController extends Notifier<DiscountListState> {
  DiscountRepository get _repo => ref.read(discountRepositoryProvider);

  @override
  DiscountListState build() {
    final session = ref.watch(
      loginControllerProvider.select((value) => value.session),
    );
    return DiscountListState(canManage: _canManage(session));
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final rules = await _repo.fetchDiscountRules();
      state = state.copyWith(
        isLoading: false,
        error: null,
        errorCode: null,
        rules: rules,
      );
    } catch (error) {
      final mapped = _mapError(error);
      state = state.copyWith(
        isLoading: false,
        error: mapped.message,
        errorCode: mapped.code,
      );
    }
  }

  Future<void> refresh() => load();

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setStatusFilter(String value) {
    state = state.copyWith(statusFilter: value);
  }

  void setScopeFilter(String value) {
    state = state.copyWith(scopeFilter: value);
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
