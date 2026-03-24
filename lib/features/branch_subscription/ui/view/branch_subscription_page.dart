import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_workspace_app_bar_actions.dart';

class BranchSubscriptionPage extends StatelessWidget {
  const BranchSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Subscription'),
        centerTitle: false,
        actions: const [TenantWorkspaceAppBarActions()],
      ),
      body: const Center(
        child: Text('Branch Subscription page is coming soon.'),
      ),
    );
  }
}
