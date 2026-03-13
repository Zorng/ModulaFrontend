import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/auth/domain/models/membership_invitation.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/membership_invitation_inbox_controller.dart';

class InvitationInboxPage extends ConsumerStatefulWidget {
  const InvitationInboxPage({super.key});

  @override
  ConsumerState<InvitationInboxPage> createState() =>
      _InvitationInboxPageState();
}

class _InvitationInboxPageState extends ConsumerState<InvitationInboxPage> {
  String? _feedbackMessage;
  bool _isFeedbackSuccess = true;

  void _setFeedback(MembershipInvitationMutationResult result) {
    setState(() {
      _feedbackMessage = result.message;
      _isFeedbackSuccess = result.isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(membershipInvitationInboxControllerProvider);
    final controller = ref.read(
      membershipInvitationInboxControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Invitation Inbox'),
        actions: [
          asyncState.maybeWhen(
            data: (state) => IconButton(
              tooltip: 'Refresh',
              onPressed: state.isRefreshing
                  ? null
                  : () {
                      controller.refresh();
                    },
              icon: state.isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
            orElse: () => IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                controller.refresh();
              },
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _FatalErrorState(
                message: UserErrorMessage.build(
                  context: 'Failed to load invitations',
                  error: error,
                ),
                onRetry: () {
                  controller.refresh();
                },
              ),
              data: (state) {
                if (state.invitations.isEmpty) {
                  return ListView(
                    children: [
                      if (_feedbackMessage != null) ...[
                        _FeedbackCard(
                          message: _feedbackMessage!,
                          isSuccess: _isFeedbackSuccess,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (state.inlineError != null) ...[
                        _InlineMessageCard(message: state.inlineError!),
                        const SizedBox(height: 12),
                      ],
                      _EmptyState(
                        onRefresh: () {
                          controller.refresh();
                        },
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  itemCount:
                      (_feedbackMessage == null ? 0 : 1) +
                      state.invitations.length +
                      (state.inlineError == null ? 0 : 1),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (_feedbackMessage != null && index == 0) {
                      return _FeedbackCard(
                        message: _feedbackMessage!,
                        isSuccess: _isFeedbackSuccess,
                      );
                    }

                    final feedbackOffset = _feedbackMessage == null ? 0 : 1;
                    if (state.inlineError != null && index == feedbackOffset) {
                      return _InlineMessageCard(message: state.inlineError!);
                    }

                    final invitationIndex =
                        index -
                        feedbackOffset -
                        (state.inlineError == null ? 0 : 1);
                    final invitation = state.invitations[invitationIndex];
                    return _InvitationCard(
                      invitation: invitation,
                      isAccepting: state.isAccepting(invitation.membershipId),
                      isRejecting: state.isRejecting(invitation.membershipId),
                      onAccept: () async {
                        final result = await controller.acceptInvitation(
                          invitation,
                        );
                        if (!mounted) return;
                        _setFeedback(result);
                      },
                      onReject: () async {
                        final result = await controller.rejectInvitation(
                          invitation,
                        );
                        if (!mounted) return;
                        _setFeedback(result);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.isAccepting,
    required this.isRejecting,
    required this.onAccept,
    required this.onReject,
  });

  final MembershipInvitation invitation;
  final bool isAccepting;
  final bool isRejecting;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  Widget build(BuildContext context) {
    final isMutating = isAccepting || isRejecting;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invitation.tenantName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _MetaRow(label: 'Role', value: _formatRole(invitation.roleKey)),
            _MetaRow(
              label: 'Invited at',
              value: _formatInvitationTimestamp(invitation.invitedAt),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isMutating
                        ? null
                        : () {
                            onReject();
                          },
                    child: isRejecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isMutating
                        ? null
                        : () {
                            onAccept();
                          },
                    child: isAccepting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSuccess
        ? Colors.green.shade50
        : Theme.of(context).colorScheme.errorContainer;
    final iconColor = isSuccess
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.onErrorContainer;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _FatalErrorState extends StatelessWidget {
  const _FatalErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'No invitations right now.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'When a tenant invites this account, it will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  onRefresh();
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatRole(String roleKey) {
  final normalized = roleKey.trim();
  if (normalized.isEmpty) return 'Unknown';
  return normalized
      .toLowerCase()
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _formatInvitationTimestamp(DateTime? value) {
  if (value == null) return 'Unknown';
  return DateFormat('yyyy-MM-dd hh:mm a').format(value.toLocal());
}
