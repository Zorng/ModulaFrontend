import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/notification/data/operational_notification_repository.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_unread_count_controller.dart';

class OperationalNotificationInboxState {
  static const Object _unset = Object();
  static const int defaultPageSize = 50;

  const OperationalNotificationInboxState({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
    this.unreadOnly = false,
    this.selectedType,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.markingReadIds = const <String>{},
    this.isMarkingAllRead = false,
    this.inlineError,
  });

  const OperationalNotificationInboxState.empty()
    : this(
        items: const <OperationalNotificationItem>[],
        limit: defaultPageSize,
        offset: 0,
        total: 0,
        hasMore: false,
      );

  final List<OperationalNotificationItem> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
  final bool unreadOnly;
  final String? selectedType;
  final bool isRefreshing;
  final bool isLoadingMore;
  final Set<String> markingReadIds;
  final bool isMarkingAllRead;
  final String? inlineError;

  bool isMarkingRead(String notificationId) =>
      markingReadIds.contains(notificationId);

  OperationalNotificationInboxState copyWith({
    List<OperationalNotificationItem>? items,
    int? limit,
    int? offset,
    int? total,
    bool? hasMore,
    bool? unreadOnly,
    Object? selectedType = _unset,
    bool? isRefreshing,
    bool? isLoadingMore,
    Set<String>? markingReadIds,
    bool? isMarkingAllRead,
    String? inlineError,
    bool clearInlineError = false,
  }) {
    return OperationalNotificationInboxState(
      items: items ?? this.items,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      selectedType: identical(selectedType, _unset)
          ? this.selectedType
          : selectedType as String?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      markingReadIds: markingReadIds ?? this.markingReadIds,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      inlineError: clearInlineError ? null : inlineError ?? this.inlineError,
    );
  }
}

final operationalNotificationInboxControllerProvider =
    AsyncNotifierProvider<
      OperationalNotificationInboxController,
      OperationalNotificationInboxState
    >(OperationalNotificationInboxController.new);

class OperationalNotificationInboxController
    extends AsyncNotifier<OperationalNotificationInboxState> {
  OperationalNotificationRepository get _repository =>
      ref.read(operationalNotificationRepositoryProvider);

  OperationalNotificationInboxState? get _currentState {
    final current = state;
    return current is AsyncData<OperationalNotificationInboxState>
        ? current.value
        : null;
  }

  @override
  Future<OperationalNotificationInboxState> build() async {
    final accessToken = _watchAccessToken();
    final branchId = _watchBranchId();
    if (accessToken == null || branchId == null) {
      return const OperationalNotificationInboxState.empty();
    }
    return _load(
      baseState: const OperationalNotificationInboxState.empty(),
      offset: 0,
    );
  }

  Future<void> refresh() async {
    final accessToken = _readAccessToken();
    final branchId = _readBranchId();
    final current = _currentState;
    if (accessToken == null || branchId == null) {
      state = const AsyncData(OperationalNotificationInboxState.empty());
      return;
    }

    final baseState =
        current ?? const OperationalNotificationInboxState.empty();
    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(
        () => _load(baseState: baseState, offset: 0),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(isRefreshing: true, clearInlineError: true),
    );
    try {
      state = AsyncData(await _load(baseState: current, offset: 0));
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isRefreshing: false,
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to refresh notifications.',
          ),
        ),
      );
    }
  }

  Future<void> applyFilters({bool? unreadOnly, String? type}) async {
    final accessToken = _readAccessToken();
    final branchId = _readBranchId();
    final current =
        _currentState ?? const OperationalNotificationInboxState.empty();
    final nextState = current.copyWith(
      unreadOnly: unreadOnly ?? current.unreadOnly,
      selectedType: type,
      isRefreshing: true,
      clearInlineError: true,
    );
    if (accessToken == null || branchId == null) {
      state = AsyncData(
        nextState.copyWith(
          items: const <OperationalNotificationItem>[],
          total: 0,
          hasMore: false,
          offset: 0,
          isRefreshing: false,
        ),
      );
      return;
    }

    state = AsyncData(nextState);
    try {
      state = AsyncData(await _load(baseState: nextState, offset: 0));
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to apply notification filters.',
          ),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final accessToken = _readAccessToken();
    final branchId = _readBranchId();
    final current = _currentState;
    if (accessToken == null || branchId == null || current == null) return;
    if (!current.hasMore || current.isLoadingMore || current.isRefreshing) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearInlineError: true),
    );
    try {
      final page = await _repository.listInbox(
        unreadOnly: current.unreadOnly,
        type: current.selectedType,
        limit: current.limit,
        offset: current.items.length,
      );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          limit: page.limit,
          offset: page.offset,
          total: page.total,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to load more notifications.',
          ),
        ),
      );
    }
  }

  Future<bool> markAsRead(OperationalNotificationItem notification) async {
    final current = _currentState;
    if (current == null) return false;
    if (notification.isRead || current.isMarkingRead(notification.id)) {
      return true;
    }

    state = AsyncData(
      current.copyWith(
        markingReadIds: {...current.markingReadIds, notification.id},
        clearInlineError: true,
      ),
    );

    try {
      final result = await _repository.markNotificationAsRead(notification.id);
      final updatedItems = current.unreadOnly
          ? current.items
                .where((item) => item.id != notification.id)
                .toList(growable: false)
          : current.items
                .map(
                  (item) => item.id == notification.id
                      ? item.copyWith(
                          isRead: result.isRead,
                          readAt: result.readAt,
                        )
                      : item,
                )
                .toList(growable: false);
      state = AsyncData(
        current.copyWith(
          items: updatedItems,
          total: current.unreadOnly
              ? (current.total > 0 ? current.total - 1 : 0)
              : current.total,
          hasMore: current.unreadOnly
              ? updatedItems.length < current.total - 1
              : current.hasMore,
          markingReadIds: {...current.markingReadIds}..remove(notification.id),
        ),
      );
      ref
          .read(operationalNotificationUnreadCountControllerProvider.notifier)
          .decrementUnreadCount();
      return result.isRead;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          markingReadIds: {...current.markingReadIds}..remove(notification.id),
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to mark notification as read.',
          ),
        ),
      );
      return false;
    }
  }

  Future<int> markAllAsRead() async {
    final current = _currentState;
    if (current == null || current.isMarkingAllRead) return 0;

    state = AsyncData(
      current.copyWith(isMarkingAllRead: true, clearInlineError: true),
    );
    try {
      final result = await _repository.markAllAsRead();
      final nextState = current.unreadOnly
          ? current.copyWith(
              items: const <OperationalNotificationItem>[],
              total: 0,
              hasMore: false,
              offset: 0,
              isMarkingAllRead: false,
            )
          : current.copyWith(
              items: current.items
                  .map(
                    (item) => item.isRead
                        ? item
                        : item.copyWith(
                            isRead: true,
                            readAt: DateTime.now().toUtc(),
                          ),
                  )
                  .toList(growable: false),
              isMarkingAllRead: false,
            );
      state = AsyncData(nextState);
      ref
          .read(operationalNotificationUnreadCountControllerProvider.notifier)
          .setUnreadCount(0);
      return result.updatedCount;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isMarkingAllRead: false,
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to mark all notifications as read.',
          ),
        ),
      );
      return 0;
    }
  }

  Future<OperationalNotificationInboxState> _load({
    required OperationalNotificationInboxState baseState,
    required int offset,
  }) async {
    final page = await _repository.listInbox(
      unreadOnly: baseState.unreadOnly,
      type: baseState.selectedType,
      limit: baseState.limit,
      offset: offset,
    );
    return baseState.copyWith(
      items: page.items,
      limit: page.limit,
      offset: page.offset,
      total: page.total,
      hasMore: page.hasMore,
      isRefreshing: false,
      isLoadingMore: false,
      markingReadIds: const <String>{},
      isMarkingAllRead: false,
      clearInlineError: true,
    );
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

  void reset() {
    state = const AsyncData(OperationalNotificationInboxState.empty());
  }

  Future<void> refreshIfLoaded() async {
    if (_currentState == null) return;
    await refresh();
  }

  void ingestRealtimeNotification(
    OperationalNotificationItem notification, {
    required int unreadCount,
  }) {
    final current = _currentState;
    if (current == null) return;

    final selectedType = (current.selectedType ?? '').trim();
    if (selectedType.isNotEmpty && selectedType != notification.type) {
      return;
    }
    if (current.unreadOnly && notification.isRead) {
      return;
    }

    final nextItems = <OperationalNotificationItem>[
      notification,
      ...current.items.where((item) => item.id != notification.id),
    ];
    final truncatedItems = current.hasMore && nextItems.length > current.limit
        ? nextItems.take(current.limit).toList(growable: false)
        : nextItems;
    final nextTotal = current.items.any((item) => item.id == notification.id)
        ? current.total
        : current.total + 1;

    state = AsyncData(
      current.copyWith(
        items: truncatedItems,
        total: nextTotal,
        hasMore: current.hasMore || nextTotal > truncatedItems.length,
      ),
    );
  }

  String _errorMessage(Object error, {required String fallbackMessage}) {
    if (error is ApiClientException) {
      final message = error.message.trim();
      if (message.isNotEmpty) return message;
    }
    return fallbackMessage;
  }
}
