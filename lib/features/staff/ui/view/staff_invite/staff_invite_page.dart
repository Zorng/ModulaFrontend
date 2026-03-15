import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/staff/data/repository/membership_command_repository.dart';
import 'package:modular_pos/features/staff/data/repository/staff_branch_assignment_repository.dart';
import 'package:modular_pos/features/staff/domain/models/staff_membership_models.dart';
import 'package:modular_pos/features/staff/ui/components/staff_branch_selection_list.dart';
import 'package:modular_pos/features/staff/ui/components/staff_role_chip.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_membership_list_controller.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_support_providers.dart';

class StaffInvitePage extends ConsumerStatefulWidget {
  const StaffInvitePage({super.key});

  @override
  ConsumerState<StaffInvitePage> createState() => _StaffInvitePageState();
}

class _StaffInvitePageState extends ConsumerState<StaffInvitePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedRole = 'CASHIER';
  bool _isInviting = false;
  bool _isSavingBranches = false;
  String? _message;
  MembershipInviteResult? _inviteResult;
  Set<String> _selectedBranchIds = <String>{};

  static const MenuStyle _whiteDropdownMenuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
    surfaceTintColor: WidgetStatePropertyAll<Color>(Colors.white),
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(staffTenantBranchesProvider);
    final session = ref.watch(loginControllerProvider).session;
    final tenantId = (session?.activeTenantId ?? session?.user.tenantId ?? '')
        .trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Invite team member')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (_message != null) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_message!),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth;
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create a tenant membership invite.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                hintText: '+85512345678',
                                hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                              ),
                              validator: (value) {
                                final phone = (value ?? '').trim();
                                if (phone.isEmpty) return 'Phone is required.';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: fieldWidth,
                            child: DropdownMenu<String>(
                              initialSelection: _selectedRole,
                              width: fieldWidth,
                              menuStyle: _whiteDropdownMenuStyle,
                              label: const Text('Role'),
                              onSelected: (value) {
                                if (value == null) return;
                                setState(() => _selectedRole = value);
                              },
                              dropdownMenuEntries: const [
                                DropdownMenuEntry(
                                  value: 'ADMIN',
                                  label: 'Admin',
                                ),
                                DropdownMenuEntry(
                                  value: 'MANAGER',
                                  label: 'Manager',
                                ),
                                DropdownMenuEntry(
                                  value: 'CASHIER',
                                  label: 'Cashier',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _isInviting || tenantId.isEmpty
                                  ? null
                                  : () => _submitInvite(tenantId),
                              child: _isInviting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Send invite'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_inviteResult != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite created',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(_inviteResult!.phone),
                      const SizedBox(height: 8),
                      StaffRoleChip(roleKey: _inviteResult!.roleKey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              branchesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(
                  UserErrorMessage.build(
                    context: 'Failed to load branches',
                    error: error,
                  ),
                ),
                data: (branches) => Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign branches',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        StaffBranchSelectionList(
                          availableBranches: branches,
                          selectedBranchIds: _selectedBranchIds,
                          onChanged: (value) =>
                              setState(() => _selectedBranchIds = value),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () =>
                                    context.go(AppRoute.staff.path),
                                child: const Text('Finish later'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: FilledButton(
                                onPressed: _isSavingBranches
                                    ? null
                                    : () => _saveBranches(),
                                child: _isSavingBranches
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save branches'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitInvite(String tenantId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isInviting = true;
      _message = null;
    });
    try {
      final result = await ref
          .read(membershipCommandRepositoryProvider)
          .inviteMember(
            tenantId: tenantId,
            phone: _phoneController.text.trim(),
            roleKey: _selectedRole,
          );
      await ref
          .read(staffMembershipListControllerProvider.notifier)
          .reconcileAfterMutation();
      if (!mounted) return;
      setState(() {
        _inviteResult = result;
        _message = 'Invite sent successfully. You can assign branches now.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = UserErrorMessage.build(
          context: 'Failed to send invite',
          error: error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  Future<void> _saveBranches() async {
    final inviteResult = _inviteResult;
    if (inviteResult == null) return;
    setState(() {
      _isSavingBranches = true;
      _message = null;
    });
    try {
      await ref
          .read(staffBranchAssignmentRepositoryProvider)
          .assignBranches(
            membershipId: inviteResult.membershipId,
            branchIds: _selectedBranchIds.toList(growable: false),
          );
      await ref
          .read(staffMembershipListControllerProvider.notifier)
          .reconcileAfterMutation();
      if (!mounted) return;
      context.goNamed(
        AppRoute.staffDetail.name,
        pathParameters: {'membershipId': inviteResult.membershipId},
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = UserErrorMessage.build(
          context: 'Failed to save branch assignments',
          error: error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingBranches = false);
    }
  }
}
