import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';

final operationalNotificationUnreadCountControllerProvider =
    AsyncNotifierProvider<OperationalNotificationUnreadCountController, int>(
      OperationalNotificationUnreadCountController.new,
    );

class OperationalNotificationUnreadCountController extends AsyncNotifier<int> {
  OperationalNotificationRepository get _repository =>
      ref.read(operationalNotificationRepositoryProvider);

  @override
  Future<int> build() async {
    final accessToken = _watchAccessToken();
    final branchId = _watchBranchId();
    if (accessToken == null || branchId == null) return 0;
    return _repository.getUnreadCount();
  }

  Future<void> refresh() async {
    final accessToken = _readAccessToken();
    final branchId = _readBranchId();
    if (accessToken == null || branchId == null) {
      state = const AsyncData(0);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getUnreadCount);
  }

  void setUnreadCount(int unreadCount) {
    state = AsyncData(unreadCount < 0 ? 0 : unreadCount);
  }

  void decrementUnreadCount({int by = 1}) {
    final current = state.asData?.value ?? 0;
    setUnreadCount(current - by);
  }

  void reset() {
    state = const AsyncData(0);
  }

  String? _watchAccessToken() {
    final token = ref.watch(
      loginControllerProvider.select((value) => value.session?.accessToken),
    );
    return _normalizeAccessToken(token);
  }

  String? _watchBranchId() {
    final branchId = ref.watch(activeBranchContextIdProvider);
    return _normalizeBranchId(branchId);
  }

  String? _readAccessToken() {
    final token = ref.read(loginControllerProvider).session?.accessToken;
    return _normalizeAccessToken(token);
  }

  String? _readBranchId() {
    final branchId = ref.read(activeBranchContextIdProvider);
    return _normalizeBranchId(branchId);
  }

  String? _normalizeAccessToken(String? token) {
    final normalized = (token ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _normalizeBranchId(String? branchId) {
    final normalized = (branchId ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }
}
