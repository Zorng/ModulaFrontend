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
            final initials = detail.displayName
                .trim()
                .split(' ')
                .take(2)
                .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                .join();

            return ListView(
              children: [
                // ── Inline error ─────────────────────────────────────
                if (_actionMessage != null) ...[
                  Card(
                    color: Colors.orange.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_actionMessage!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Header card ──────────────────────────────────────
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.displayName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  StaffRoleChip(roleKey: detail.roleKey),
                                  const SizedBox(width: 8),
                                  StaffStatusChip.membership(
                                    status: detail.membershipStatus,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      detail.phone,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Membership summary ───────────────────────────────
                StaffDetailSectionCard(
                  title: 'Membership summary',
                  trailing: _isChangingRole
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: () => _changeRole(context, data),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Change role'),
                        ),
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
                        value: '',
                        valueWidget: StaffRoleChip(roleKey: detail.roleKey),
                      ),
                      StaffDetailInfoRow(
                        label: 'Status',
                        value: '',
                        valueWidget: StaffStatusChip.membership(
                          status: detail.membershipStatus,
                        ),
                      ),
                      StaffDetailInfoRow(
                        label: 'Profile status',
                        value: detail.staffProfileStatus ?? '—',
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
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Branch assignment ────────────────────────────────
                StaffDetailSectionCard(
                  title: 'Branch assignment',
                  trailing: _isSavingBranches
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: () => _editBranches(context, data),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Edit'),
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
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Actions ──────────────────────────────────────────
                StaffDetailSectionCard(
                  title: 'Actions',
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _isRevoking ? null : () => _revoke(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isRevoking
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red.shade700,
                                ),
                              )
                            : const Text('Revoke membership'),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Dialogs & actions (unchanged logic) ─────────────────────────────

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
                requestFocusOnTap: false,
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
