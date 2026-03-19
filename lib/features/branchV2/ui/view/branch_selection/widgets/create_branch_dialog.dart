import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';

Future<void> showCreateBranchDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          child: const CreateBranchDialogBody(),
        ),
      );
    },
  );
}

class CreateBranchDialogBody extends ConsumerStatefulWidget {
  const CreateBranchDialogBody({super.key});

  @override
  ConsumerState<CreateBranchDialogBody> createState() =>
      _CreateBranchDialogBodyState();
}

class _CreateBranchDialogBodyState extends ConsumerState<CreateBranchDialogBody> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchControllerProvider);
    final controller = ref.read(branchControllerProvider.notifier);
    final flow = state.createFlowStatus;
    final isSubmitting =
        flow == BranchCreateFlowStatus.initiating ||
        flow == BranchCreateFlowStatus.confirming;
    final canCreate =
        flow == BranchCreateFlowStatus.idle ||
        flow == BranchCreateFlowStatus.failed;
    final canConfirmPayment = flow == BranchCreateFlowStatus.pendingPayment;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Create Branch', style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: isSubmitting
                      ? null
                      : () {
                          controller.clearCreateFlow();
                          Navigator.of(context).pop();
                        },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 20),
            if (canCreate) ...[
              TextField(
                controller: _nameController,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onCreate(controller),
                decoration: InputDecoration(
                  labelText: 'Branch name',
                  hintText: 'Enter branch name',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
              ),
            ] else if (canConfirmPayment) ...[
              Text(
                'Payment is required before branch activation.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Draft: ${state.activationDraft?.draftId ?? '-'}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Invoice: ${state.activationDraft?.invoice.invoiceId ?? '-'}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Amount (USD): ${state.activationDraft?.invoice.totalAmountUsd ?? '-'}',
                style: theme.textTheme.bodySmall,
              ),
            ] else if (flow == BranchCreateFlowStatus.confirmed) ...[
              Text(
                'Branch created successfully.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Branch ID: ${state.activationResult?.branchId ?? '-'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (isSubmitting) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            if (state.error != null && state.error!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (canCreate)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSubmitting ? null : () => _onCreate(controller),
                  child: const Text('Create'),
                ),
              )
            else if (canConfirmPayment)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () => controller.confirmCreateBranch(
                            paymentToken: 'PAID',
                          ),
                  child: const Text('Confirm Payment'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onCreate(BranchController controller) {
    controller.initiateCreateBranch(branchName: _nameController.text);
  }
}
