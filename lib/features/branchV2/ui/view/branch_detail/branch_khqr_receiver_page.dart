import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';

class BranchKhqrReceiverPage extends ConsumerStatefulWidget {
  const BranchKhqrReceiverPage({
    super.key,
    required this.branchId,
  });

  final String branchId;

  @override
  ConsumerState<BranchKhqrReceiverPage> createState() =>
      _BranchKhqrReceiverPageState();
}

class _BranchKhqrReceiverPageState
    extends ConsumerState<BranchKhqrReceiverPage> {
  final _accountController = TextEditingController();
  final _receiverNameController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      if (!mounted) return;
      await ref.read(branchControllerProvider.notifier).loadCurrentBranchProfile();
    });
  }

  @override
  void dispose() {
    _accountController.dispose();
    _receiverNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchControllerProvider);
    final controller = ref.read(branchControllerProvider.notifier);
    final profile = state.currentBranchProfile;

    if (!_initialized && profile != null) {
      _initialized = true;
      _accountController.text = profile.khqrReceiverAccountId ?? '';
      _receiverNameController.text = profile.khqrReceiverName ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.goNamed(
            AppRoute.branchDetail.name,
            pathParameters: {'id': widget.branchId},
          ),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(profile?.branchName ?? 'Bakong Receiver'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.error != null && state.error!.trim().isNotEmpty) ...[
            _ErrorBanner(message: state.error!),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bakong Receiver Account',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add or update the Bakong/KHQR receiver account used for this branch sale flow.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _accountController,
                    enabled:
                        !state.isCurrentBranchLoading &&
                        !state.isKhqrReceiverUpdating,
                    decoration: const InputDecoration(
                      labelText: 'Bakong Account ID',
                      hintText: 'bakong-account-id',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _receiverNameController,
                    enabled:
                        !state.isCurrentBranchLoading &&
                        !state.isKhqrReceiverUpdating,
                    decoration: const InputDecoration(
                      labelText: 'Receiver Name',
                      hintText: 'Main Branch Receiver',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed:
                          state.isCurrentBranchLoading ||
                              state.isKhqrReceiverUpdating
                          ? null
                          : () async {
                              await controller.updateCurrentBranchKhqrReceiver(
                                khqrReceiverAccountId: _accountController.text,
                                khqrReceiverName: _receiverNameController.text,
                              );
                            },
                      child: Text(
                        state.isKhqrReceiverUpdating ? 'Saving...' : 'Save',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
