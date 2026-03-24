import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_inbox_controller.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_navigation.dart';

const operationalNotificationInboxDialogKey = Key(
  'operational_notification_inbox_dialog',
);
const operationalNotificationInboxBottomSheetKey = Key(
  'operational_notification_inbox_bottom_sheet',
);

Future<void> showOperationalNotificationInboxModal(BuildContext context) {
  final isWide = AppBreakpoints.isLarge(MediaQuery.of(context).size.width);

  if (isWide) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          key: operationalNotificationInboxDialogKey,
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
            child: const OperationalNotificationInboxPage(
              modalPresentation: true,
            ),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.of(sheetContext).size.height * 0.92;
      return SizedBox(
        key: operationalNotificationInboxBottomSheetKey,
        height: height,
        child: const OperationalNotificationInboxPage(modalPresentation: true),
      );
    },
  );
}

class OperationalNotificationInboxPage extends ConsumerWidget {
  const OperationalNotificationInboxPage({
    super.key,
    this.modalPresentation = false,
  });

  final bool modalPresentation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(
      operationalNotificationInboxControllerProvider,
    );
    final controller = ref.read(
      operationalNotificationInboxControllerProvider.notifier,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: modalPresentation,
        backgroundColor: Colors.white,
        leading: modalPresentation ? const CloseButton() : null,
        title: const Text('Notifications'),
        actions: [
          asyncState.maybeWhen(
            data: (state) => IconButton(
              tooltip: 'Refresh',
              onPressed: state.isRefreshing ? null : controller.refresh,
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
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ),
          asyncState.maybeWhen(
            data: (state) {
              final hasUnread = state.items.any((item) => item.isUnread);
              return TextButton(
                onPressed: hasUnread && !state.isMarkingAllRead
                    ? () {
                        controller.markAllAsRead();
                      }
                    : null,
                child: state.isMarkingAllRead
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Mark all read'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _FatalErrorState(
                message: UserErrorMessage.build(
                  context: 'Failed to load notifications',
                  error: error,
                ),
                onRetry: controller.refresh,
              ),
              data: (state) {
                return ListView(
                  children: [
                    _Toolbar(
                      unreadOnly: state.unreadOnly,
                      onUnreadOnlyChanged: (selected) {
                        controller.applyFilters(unreadOnly: selected);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (state.inlineError != null) ...[
                      _InlineMessageCard(message: state.inlineError!),
                      const SizedBox(height: 12),
                    ],
                    if (state.items.isEmpty)
                      _EmptyState(onRefresh: controller.refresh)
                    else ...[
                      for (final notification in state.items) ...[
                        _NotificationCard(
                          notification: notification,
                          isMarkingRead: state.isMarkingRead(notification.id),
                          onOpen: () => _openNotification(
                            context,
                            controller,
                            notification,
                            closeModalOnNavigate: modalPresentation,
                          ),
                          onMarkRead: notification.isUnread
                              ? () {
                                  controller.markAsRead(notification);
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (state.hasMore)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: state.isLoadingMore
                                ? null
                                : controller.loadMore,
                            child: state.isLoadingMore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Load more'),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openNotification(
  BuildContext context,
  OperationalNotificationInboxController controller,
  OperationalNotificationItem notification, {
  required bool closeModalOnNavigate,
}) async {
  if (notification.isUnread) {
    await controller.markAsRead(notification);
  }
  if (!context.mounted) return;
  final router = GoRouter.of(context);
  if (closeModalOnNavigate) {
    Navigator.of(context).pop();
    router.go(operationalNotificationLocation(notification));
    return;
  }
  router.go(operationalNotificationLocation(notification));
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.unreadOnly, required this.onUnreadOnlyChanged});

  final bool unreadOnly;
  final ValueChanged<bool> onUnreadOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          label: const Text('Unread only'),
          selected: unreadOnly,
          onSelected: onUnreadOnlyChanged,
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isMarkingRead,
    required this.onOpen,
    this.onMarkRead,
  });

  final OperationalNotificationItem notification;
  final bool isMarkingRead;
  final VoidCallback onOpen;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final typeLabel = _typeLabel(notification.type);
    final createdAtLabel = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(notification.createdAt.toLocal());
    final tenantLabel = _tenantLabel(notification);
    final branchLabel = _branchLabel(notification);

    return Card(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _TypeChip(
                    label: typeLabel,
                    emphasized: notification.isUnread,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.body,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (tenantLabel != null)
                    _MetaText(label: 'Tenant', value: tenantLabel),
                  if (branchLabel != null)
                    _MetaText(label: 'Branch', value: branchLabel),
                  _MetaText(label: 'Created', value: createdAtLabel),
                  _MetaText(
                    label: 'Subject',
                    value: _subjectTypeLabel(notification.subjectType),
                  ),
                  _MetaText(
                    label: 'Status',
                    value: notification.isRead ? 'Read' : 'Unread',
                  ),
                ],
              ),
              if (notification.isUnread) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: onOpen,
                      child: Text(
                        operationalNotificationActionLabel(notification),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: isMarkingRead ? null : onMarkRead,
                      icon: isMarkingRead
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.done_outlined),
                      label: const Text('Mark as read'),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onOpen,
                    child: Text(
                      operationalNotificationActionLabel(notification),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String? _tenantLabel(OperationalNotificationItem notification) {
  final tenantName = notification.tenantName.trim();
  return tenantName.isEmpty ? null : tenantName;
}

String? _branchLabel(OperationalNotificationItem notification) {
  final branchName = (notification.branchName ?? '').trim();
  if (branchName.isNotEmpty) return branchName;
  final branchId = notification.branchId.trim();
  if (branchId.isNotEmpty) return branchId;
  return null;
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.emphasized});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: emphasized
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.notifications_none_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'New operational notifications will appear here for your current tenant inbox.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
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
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _typeLabel(String type) {
  switch (type) {
    case OperationalNotificationTypes.voidApprovalNeeded:
      return 'Void Approval';
    case OperationalNotificationTypes.voidApproved:
      return 'Void Approved';
    case OperationalNotificationTypes.voidRejected:
      return 'Void Rejected';
    case OperationalNotificationTypes.cashSessionClosed:
      return 'Cash Closed';
    default:
      return type;
  }
}

String _subjectTypeLabel(String subjectType) {
  switch (subjectType) {
    case OperationalNotificationSubjectTypes.sale:
      return 'Sale';
    case OperationalNotificationSubjectTypes.cashSession:
      return 'Cash Session';
    default:
      return subjectType;
  }
}
