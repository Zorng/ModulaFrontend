import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/data/membership_invitation_repository.dart';
import 'package:modular_pos/features/auth/domain/models/membership_invitation.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class MembershipInvitationInboxState {
  const MembershipInvitationInboxState({
    required this.invitations,
    this.isRefreshing = false,
    this.acceptingMembershipIds = const <String>{},
    this.rejectingMembershipIds = const <String>{},
    this.inlineError,
  });

  const MembershipInvitationInboxState.empty() : this(invitations: const []);

  final List<MembershipInvitation> invitations;
  final bool isRefreshing;
  final Set<String> acceptingMembershipIds;
  final Set<String> rejectingMembershipIds;
  final String? inlineError;

  bool isAccepting(String membershipId) =>
      acceptingMembershipIds.contains(membershipId);

  bool isRejecting(String membershipId) =>
      rejectingMembershipIds.contains(membershipId);

  bool isMutating(String membershipId) =>
      isAccepting(membershipId) || isRejecting(membershipId);

  MembershipInvitationInboxState copyWith({
    List<MembershipInvitation>? invitations,
    bool? isRefreshing,
    Set<String>? acceptingMembershipIds,
    Set<String>? rejectingMembershipIds,
    String? inlineError,
    bool clearInlineError = false,
  }) {
    return MembershipInvitationInboxState(
      invitations: invitations ?? this.invitations,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      acceptingMembershipIds:
          acceptingMembershipIds ?? this.acceptingMembershipIds,
      rejectingMembershipIds:
          rejectingMembershipIds ?? this.rejectingMembershipIds,
      inlineError: clearInlineError ? null : inlineError ?? this.inlineError,
    );
  }
}

class MembershipInvitationMutationResult {
  const MembershipInvitationMutationResult._({
    required this.isSuccess,
    required this.message,
  });

  final bool isSuccess;
  final String message;

  factory MembershipInvitationMutationResult.accepted() {
    return const MembershipInvitationMutationResult._(
      isSuccess: true,
      message: 'Invitation accepted.',
    );
  }

  factory MembershipInvitationMutationResult.rejected() {
    return const MembershipInvitationMutationResult._(
      isSuccess: true,
      message: 'Invitation rejected.',
    );
  }

  factory MembershipInvitationMutationResult.failure(String message) {
    return MembershipInvitationMutationResult._(
      isSuccess: false,
      message: message,
    );
  }
}

final membershipInvitationInboxControllerProvider =
    AsyncNotifierProvider<
      MembershipInvitationInboxController,
      MembershipInvitationInboxState
    >(MembershipInvitationInboxController.new);

class MembershipInvitationInboxController
    extends AsyncNotifier<MembershipInvitationInboxState> {
  MembershipInvitationRepository get _repository =>
      ref.read(membershipInvitationRepositoryProvider);

  MembershipInvitationInboxState? get _currentState {
    final current = state;
    return current is AsyncData<MembershipInvitationInboxState>
        ? current.value
        : null;
  }

  String? _watchAccessToken() {
    final token = ref.watch(
      loginControllerProvider.select((value) => value.session?.accessToken),
    );
    return _normalizeAccessToken(token);
  }

  String? _readAccessToken() {
    final token = ref.read(loginControllerProvider).session?.accessToken;
    return _normalizeAccessToken(token);
  }

  String? _normalizeAccessToken(String? token) {
    final normalized = (token ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Future<MembershipInvitationInboxState> build() async {
    final accessToken = _watchAccessToken();
    if (accessToken == null) {
      return const MembershipInvitationInboxState.empty();
    }
    return _load(accessToken: accessToken);
  }

  Future<void> refresh() async {
    final accessToken = _readAccessToken();
    final current = _currentState;
    if (accessToken == null) {
      state = const AsyncData(MembershipInvitationInboxState.empty());
      return;
    }

    if (current == null) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => _load(accessToken: accessToken));
      return;
    }

    state = AsyncData(
      current.copyWith(isRefreshing: true, clearInlineError: true),
    );
    try {
      state = AsyncData(await _load(accessToken: accessToken));
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isRefreshing: false,
          inlineError: _errorMessage(
            error,
            fallbackMessage: 'Failed to refresh invitations.',
          ),
        ),
      );
    }
  }

  Future<MembershipInvitationMutationResult> acceptInvitation(
    MembershipInvitation invitation, {
    String? intentId,
  }) async {
    return _runMutation(
      invitation: invitation,
      setLoading: (current, membershipId) => current.copyWith(
        acceptingMembershipIds: {
          ...current.acceptingMembershipIds,
          membershipId,
        },
        clearInlineError: true,
      ),
      clearLoading: (current, membershipId) => current.copyWith(
        acceptingMembershipIds: {...current.acceptingMembershipIds}
          ..remove(membershipId),
      ),
      mutate: () => _repository.acceptInvitation(
        membershipId: invitation.membershipId,
        intentId: intentId,
        accessTokenOverride: _readAccessToken(),
      ),
      afterSuccess: () async {
        await ref
            .read(loginControllerProvider.notifier)
            .upsertSessionTenantMembership(
              tenantId: invitation.tenantId,
              tenantName: invitation.tenantName,
              role: invitation.roleKey,
            );
      },
      refreshFallbackMessage:
          'Invitation accepted, but the inbox could not refresh.',
      mutationFallbackMessage: 'Failed to accept invitation.',
      successResult: MembershipInvitationMutationResult.accepted(),
    );
  }

  Future<MembershipInvitationMutationResult> rejectInvitation(
    MembershipInvitation invitation, {
    String? intentId,
  }) async {
    return _runMutation(
      invitation: invitation,
      setLoading: (current, membershipId) => current.copyWith(
        rejectingMembershipIds: {
          ...current.rejectingMembershipIds,
          membershipId,
        },
        clearInlineError: true,
      ),
      clearLoading: (current, membershipId) => current.copyWith(
        rejectingMembershipIds: {...current.rejectingMembershipIds}
          ..remove(membershipId),
      ),
      mutate: () => _repository.rejectInvitation(
        membershipId: invitation.membershipId,
        intentId: intentId,
        accessTokenOverride: _readAccessToken(),
      ),
      afterSuccess: () async {},
      refreshFallbackMessage:
          'Invitation rejected, but the inbox could not refresh.',
      mutationFallbackMessage: 'Failed to reject invitation.',
      successResult: MembershipInvitationMutationResult.rejected(),
    );
  }

  Future<MembershipInvitationMutationResult> _runMutation({
    required MembershipInvitation invitation,
    required MembershipInvitationInboxState Function(
      MembershipInvitationInboxState current,
      String membershipId,
    )
    setLoading,
    required MembershipInvitationInboxState Function(
      MembershipInvitationInboxState current,
      String membershipId,
    )
    clearLoading,
    required Future<Object> Function() mutate,
    required Future<void> Function() afterSuccess,
    required String refreshFallbackMessage,
    required String mutationFallbackMessage,
    required MembershipInvitationMutationResult successResult,
  }) async {
    final accessToken = _readAccessToken();
    final current = _currentState;
    if (accessToken == null || current == null) {
      return MembershipInvitationMutationResult.failure(
        'Unable to update invitation right now.',
      );
    }
    if (current.isMutating(invitation.membershipId)) {
      return MembershipInvitationMutationResult.failure(
        'Invitation update already in progress.',
      );
    }

    state = AsyncData(setLoading(current, invitation.membershipId));

    try {
      await mutate();
      await afterSuccess();

      final latest = _currentState ?? current;
      final localNext = clearLoading(
        latest.copyWith(
          invitations: latest.invitations
              .where((item) => item.membershipId != invitation.membershipId)
              .toList(growable: false),
          clearInlineError: true,
        ),
        invitation.membershipId,
      );
      await _refreshAfterMutation(
        fallbackState: localNext,
        accessToken: accessToken,
        fallbackMessage: refreshFallbackMessage,
      );
      return successResult;
    } catch (error) {
      final latest = _currentState ?? current;
      final errorMessage = _errorMessage(
        error,
        fallbackMessage: mutationFallbackMessage,
      );
      state = AsyncData(
        clearLoading(
          latest,
          invitation.membershipId,
        ).copyWith(inlineError: errorMessage),
      );
      return MembershipInvitationMutationResult.failure(errorMessage);
    }
  }

  Future<void> _refreshAfterMutation({
    required MembershipInvitationInboxState fallbackState,
    required String accessToken,
    required String fallbackMessage,
  }) async {
    try {
      state = AsyncData(await _load(accessToken: accessToken));
    } catch (error) {
      state = AsyncData(
        fallbackState.copyWith(
          inlineError: _errorMessage(error, fallbackMessage: fallbackMessage),
        ),
      );
    }
  }

  Future<MembershipInvitationInboxState> _load({
    required String accessToken,
  }) async {
    final invitations = await _repository.listInvitations(
      accessTokenOverride: accessToken,
    );
    return MembershipInvitationInboxState(invitations: invitations);
  }

  String _errorMessage(Object error, {required String fallbackMessage}) {
    if (error is ApiClientException) {
      final message = error.message.trim();
      if (message.isNotEmpty) return message;
    }
    return fallbackMessage;
  }
}
