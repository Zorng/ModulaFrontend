import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/navigation/account_shell_action.dart';
import 'package:modular_pos/core/widgets/sync/global_sync_status_indicator.dart';
import 'package:modular_pos/features/notification/ui/components/operational_notification_inbox_action.dart';

class TenantWorkspaceAppBarActions extends StatelessWidget {
  const TenantWorkspaceAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlobalSyncStatusIndicator(compact: true),
          SizedBox(width: 4),
          OperationalNotificationInboxAction(compact: true),
          SizedBox(width: 4),
          AccountShellAction(),
        ],
      ),
    );
  }
}
