import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/notification/ui/viewmodels/operational_notification_unread_count_controller.dart';
import 'package:modular_pos/features/notification/ui/view/operational_notification_inbox/operational_notification_inbox_page.dart';

class OperationalNotificationInboxAction extends ConsumerWidget {
  const OperationalNotificationInboxAction({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(
      operationalNotificationUnreadCountControllerProvider,
    );
    final unreadCount = unreadAsync.maybeWhen(
      data: (count) => count < 0 ? 0 : count,
      orElse: () => 0,
    );

    return IconButton(
      key: const Key('operational_notification_inbox_action'),
      tooltip: 'Notifications',
      onPressed: () => showOperationalNotificationInboxModal(context),
      icon: _NotificationBellIcon(unreadCount: unreadCount, compact: compact),
    );
  }
}

class _NotificationBellIcon extends StatelessWidget {
  const _NotificationBellIcon({
    required this.unreadCount,
    required this.compact,
  });

  final int unreadCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badgeText = unreadCount > 99 ? '99+' : unreadCount.toString();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.notifications_none_outlined, size: compact ? 20 : 24),
        if (unreadCount > 0)
          Positioned(
            right: -7,
            top: -5,
            child: Container(
              key: const Key('operational_notification_unread_badge'),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  badgeText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
