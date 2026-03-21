import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';

class DiscountListState {
  static const _unset = Object();

  const DiscountListState({
    this.isLoading = false,
    this.error,
    this.errorCode,
    this.rules = const <DiscountRule>[],
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.scopeFilter = 'ALL',
    this.canManage = false,
  });

  final bool isLoading;
  final String? error;
  final String? errorCode;
  final List<DiscountRule> rules;
  final String searchQuery;
  final String statusFilter;
  final String scopeFilter;
  final bool canManage;

  bool get isReadOnly => !canManage;
  String get subtitle => canManage
      ? 'Manage tenant discount rules and assign each rule to one branch.'
      : 'View tenant discount rules and their assigned branch coverage.';

  List<DiscountRule> get filteredRules {
    final normalizedSearch = searchQuery.trim().toLowerCase();
    return rules
        .where((rule) {
          final statusOk = statusFilter == 'ALL' || rule.status == statusFilter;
          final scopeOk = scopeFilter == 'ALL' || rule.scope == scopeFilter;
          final searchOk =
              normalizedSearch.isEmpty ||
              rule.name.toLowerCase().contains(normalizedSearch);
          return statusOk && scopeOk && searchOk;
        })
        .toList(growable: false);
  }

  DiscountListState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? errorCode = _unset,
    List<DiscountRule>? rules,
    String? searchQuery,
    String? statusFilter,
    String? scopeFilter,
    bool? canManage,
  }) {
    return DiscountListState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      rules: rules ?? this.rules,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      scopeFilter: scopeFilter ?? this.scopeFilter,
      canManage: canManage ?? this.canManage,
    );
  }
}
