import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/staff/data/repository/membership_command_repository.dart';
import 'package:modular_pos/features/staff/data/repository/staff_branch_assignment_repository.dart';
import 'package:modular_pos/features/staff/ui/components/staff_branch_selection_list.dart';
import 'package:modular_pos/features/staff/ui/components/staff_role_chip.dart';
import 'package:modular_pos/features/staff/ui/components/staff_status_chip.dart';
import 'package:modular_pos/features/staff/ui/components/staff_ui_formatters.dart';
import 'package:modular_pos/features/staff/ui/view/staff_detail/widgets/staff_detail_info_row.dart';
import 'package:modular_pos/features/staff/ui/view/staff_detail/widgets/staff_detail_section_card.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_membership_detail_provider.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_membership_list_controller.dart';

class StaffMembershipDetailPage extends ConsumerStatefulWidget {
  const StaffMembershipDetailPage({super.key, required this.membershipId});

  final String membershipId;

  @override
  ConsumerState<StaffMembershipDetailPage> createState() =>
      _StaffMembershipDetailPageState();
}

class _StaffMembershipDetailPageState
    extends ConsumerState<StaffMembershipDetailPage> {
  static const double _dialogMaxWidth = 600;

  bool _isChangingRole = false;
  bool _isRevoking = false;
  bool _isSavingBranches = false;
  String? _actionMessage;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(
      staffMembershipDetailPageProvider(widget.membershipId),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Staff membership')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  UserErrorMessage.build(
                    context: 'Failed to load membership detail',
                    error: error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(
                    staffMembershipDetailPageProvider(widget.membershipId),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (data) {
            final detail = data.detail;
            final branchSummary = formatBranchAssignmentSummary(
              data.branchAssignment.branchIds,
              data.branchNameById,
            );
            return ListView(
              children: [
                if (_actionMessage != null) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_actionMessage!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.displayName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StaffRoleChip(roleKey: detail.roleKey),
                            StaffStatusChip.membership(
                              status: detail.membershipStatus,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(detail.phone),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StaffDetailSectionCard(
                  title: 'Membership summary',
                  child: Column(
                    children: [
                      StaffDetailInfoRow(
                        label: 'Membership ID',
                        value: detail.membershipId,
                      ),
                      StaffDetailInfoRow(
                        label: 'Account ID',
                        value: detail.accountId,
                      ),
                      StaffDetailInfoRow(
                        label: 'Role',
                        value: detail.roleLabel,
                      ),
                      StaffDetailInfoRow(
                        label: 'Status',
                        value: detail.statusLabel,
                      ),
                      StaffDetailInfoRow(
                        label: 'Profile status',
                        value: detail.staffProfileStatus ?? '-',
                      ),
                      StaffDetailInfoRow(
                        label: 'Invited',
                        value: formatStaffDateTime(detail.invitedAt),
                      ),
                      StaffDetailInfoRow(
                        label: 'Accepted',
                        value: formatStaffDateTime(detail.acceptedAt),
                      ),
                      StaffDetailInfoRow(
                        label: 'Revoked',
                        value: formatStaffDateTime(detail.revokedAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StaffDetailSectionCard(
                  title: 'Branch assignment',
                  trailing: TextButton(
                    onPressed: _isSavingBranches
                        ? null
                        : () => _editBranches(context, data),
                    child: _isSavingBranches
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Edit'),
                  ),
                  child: Column(
                    children: [
                      StaffDetailInfoRow(
                        label: 'Assignment',
                        value: branchSummary,
                      ),
                      StaffDetailInfoRow(
                        label: 'Pending branches',
                        value: formatBranchAssignmentSummary(
                          data.branchAssignment.pendingBranchIds,
                          data.branchNameById,
                        ),
                      ),
                      StaffDetailInfoRow(
                        label: 'Active branches',
                        value: formatBranchAssignmentSummary(
                          data.branchAssignment.activeBranchIds,
                          data.branchNameById,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StaffDetailSectionCard(
                  title: 'Actions',
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isChangingRole
                              ? null
                              : () => _changeRole(context, data),
                          child: _isChangingRole
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Change role'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _isRevoking
                              ? null
                              : () => _revoke(context),
                          child: _isRevoking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Revoke membership'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    StaffMembershipDetailPageData data,
  ) async {
    const roleOptions = {'ADMIN', 'MANAGER', 'CASHIER'};
    final currentRole = data.detail.roleKey.trim().toUpperCase();
    var selectedRole = roleOptions.contains(currentRole)
        ? currentRole
        : 'CASHIER';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        title: const Text('Change role'),
        content: _buildDialogContent(
          child: StatefulBuilder(
            builder: (context, setDialogState) => LayoutBuilder(
              builder: (context, constraints) => DropdownMenu<String>(
                initialSelection: selectedRole,
                width: constraints.maxWidth,
                menuStyle: const MenuStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
                  surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
                ),
                onSelected: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedRole = value);
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'ADMIN', label: 'Admin'),
                  DropdownMenuEntry(value: 'MANAGER', label: 'Manager'),
                  DropdownMenuEntry(value: 'CASHIER', label: 'Cashier'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          _buildDialogActions(
            context: context,
            confirmLabel: 'Save',
            onConfirm: () => Navigator.of(context).pop(selectedRole),
          ),
        ],
      ),
    );
    if (result == null || result == currentRole) return;

    setState(() {
      _isChangingRole = true;
      _actionMessage = null;
    });
    try {
      await ref
          .read(membershipCommandRepositoryProvider)
          .changeRole(membershipId: widget.membershipId, roleKey: result);
      ref.invalidate(staffMembershipDetailPageProvider(widget.membershipId));
      await ref
          .read(staffMembershipListControllerProvider.notifier)
          .reconcileAfterMutation();
      if (!mounted) return;
      setState(() => _actionMessage = 'Membership role updated.');
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _actionMessage = UserErrorMessage.build(
          context: 'Failed to update role',
          error: error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChangingRole = false);
    }
  }

  Future<void> _editBranches(
    BuildContext context,
    StaffMembershipDetailPageData data,
  ) async {
    var selected = data.branchAssignment.branchIds.toSet();
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        title: const Text('Assign branches'),
        content: _buildDialogContent(
          child: StatefulBuilder(
            builder: (context, setDialogState) => SingleChildScrollView(
              child: StaffBranchSelectionList(
                availableBranches: data.availableBranches,
                selectedBranchIds: selected,
                onChanged: (next) => setDialogState(() => selected = next),
              ),
            ),
          ),
        ),
        actions: [
          _buildDialogActions(
            context: context,
            confirmLabel: 'Save',
            onConfirm: () => Navigator.of(context).pop(selected),
          ),
        ],
      ),
    );
    if (result == null) return;

    setState(() {
      _isSavingBranches = true;
      _actionMessage = null;
    });
    try {
      await ref
          .read(staffBranchAssignmentRepositoryProvider)
          .assignBranches(
            membershipId: widget.membershipId,
            branchIds: result.toList(growable: false),
          );
      ref.invalidate(staffMembershipDetailPageProvider(widget.membershipId));
      await ref
          .read(staffMembershipListControllerProvider.notifier)
          .reconcileAfterMutation();
      if (!mounted) return;
      setState(() => _actionMessage = 'Branch assignments saved.');
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _actionMessage = UserErrorMessage.build(
          context: 'Failed to save branch assignments',
          error: error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingBranches = false);
    }
  }

  Future<void> _revoke(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        title: const Text('Revoke membership'),
        content: _buildDialogContent(
          child: const Text(
            'This removes the team member from the tenant. Continue?',
          ),
        ),
        actions: [
          _buildDialogActions(
            context: context,
            confirmLabel: 'Revoke',
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isRevoking = true;
      _actionMessage = null;
    });
    try {
      await ref
          .read(membershipCommandRepositoryProvider)
          .revokeMembership(membershipId: widget.membershipId);
      ref.invalidate(staffMembershipDetailPageProvider(widget.membershipId));
      await ref
          .read(staffMembershipListControllerProvider.notifier)
          .reconcileAfterMutation();
      if (!mounted) return;
      setState(() => _actionMessage = 'Membership revoked.');
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _actionMessage = UserErrorMessage.build(
          context: 'Failed to revoke membership',
          error: error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRevoking = false);
    }
  }

  Widget _buildDialogActions({
    required BuildContext context,
    required String confirmLabel,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return SizedBox(
      width: double.maxFinite,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onConfirm,
              child: Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogContent({required Widget child}) {
    return SizedBox(width: double.maxFinite, child: child);
  }
}
