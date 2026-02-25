import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class BranchSelectionPage extends ConsumerStatefulWidget {
  const BranchSelectionPage({super.key});

  @override
  ConsumerState<BranchSelectionPage> createState() =>
      _BranchSelectionPageState();
}

class _BranchSelectionPageState extends ConsumerState<BranchSelectionPage> {
  @override
  void initState() {
    super.initState();
    Future<void>(() {
      if (!mounted) return;
      ref.read(loginControllerProvider.notifier).loadBranchContexts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final session = loginState.session;
    final controller = ref.read(loginControllerProvider.notifier);
    final branchOptions = loginState.branchOptions;
    final isLoading = loginState.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go(AppRoute.tenantSelection.path),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Select Branch'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : controller.loadBranchContexts,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await controller.logout();
              if (context.mounted) context.go(AppRoute.login.path);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a branch for ${(session?.activeTenantId ?? session?.user.tenantId ?? '').trim()}.',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (loginState.error != null) ...[
              Text(
                loginState.error!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: branchOptions.isEmpty
                  ? Center(
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'No branch options available.',
                              style: TextStyle(fontSize: 14),
                            ),
                    )
                  : ListView.separated(
                      itemCount: branchOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final branch = branchOptions[index];
                        return Card(
                          child: ListTile(
                            enabled: !isLoading,
                            title: Text(branch.branchName),
                            subtitle: Text(branch.branchId),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await controller.selectBranch(branch.branchId);
                              final updated = ref.read(loginControllerProvider);
                              if (updated.requiresBranchSelection) return;
                              if (context.mounted) {
                                context.go(AppRoute.portal.path);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
