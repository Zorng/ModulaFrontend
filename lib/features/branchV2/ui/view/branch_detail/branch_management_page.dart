import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/branchV2/data/branch_repository.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_selection/widgets/google_maps.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';

class BranchManagementPage extends ConsumerStatefulWidget {
  const BranchManagementPage({super.key, required this.branchId});

  final String branchId;

  @override
  ConsumerState<BranchManagementPage> createState() =>
      _BranchManagementPageState();
}

class _BranchManagementPageState extends ConsumerState<BranchManagementPage> {
  BranchListItem? _branch;
  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>(() => _loadBranch());
  }

  Future<void> _loadBranch() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final session = ref.read(loginControllerProvider).session;
      if (session == null) {
        throw const ApiClientException(message: 'Session is unavailable.');
      }

      final targetBranchId = widget.branchId.trim();
      final activeBranchId = (ref.read(authActiveBranchIdProvider) ?? '')
          .trim();
      if (targetBranchId.isEmpty) {
        throw const ApiClientException(message: 'Branch ID is required.');
      }

      if (activeBranchId != targetBranchId) {
        await ref
            .read(loginControllerProvider.notifier)
            .selectBranch(targetBranchId);
        final loginState = ref.read(loginControllerProvider);
        final error = (loginState.error ?? '').trim();
        if (error.isNotEmpty) {
          throw ApiClientException(
            message: error,
            code: loginState.errorCode,
            statusCode: loginState.errorStatusCode,
          );
        }
      }

      final accessToken =
          ref.read(loginControllerProvider).session?.accessToken ?? '';
      final branch = await ref
          .read(branchRepositoryProvider)
          .getCurrentBranchProfile(accessTokenOverride: accessToken);
      if (!mounted) return;
      ref
          .read(authActiveBranchNameOverrideProvider.notifier)
          .setName(branch.branchName);
      setState(() {
        _branch = branch;
        _loading = false;
      });
      // Refresh the branch list in the background so BranchSelectionPage has
      // up-to-date data when the user navigates back.
      ref.read(branchControllerProvider.notifier).loadInitial();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = UserErrorMessage.build(
          context: 'Failed to load branch management',
          error: error,
        );
      });
    }
  }

  Future<void> _showKhqrDialog() async {
    final branch = _branch;
    if (branch == null) return;

    final accountController = TextEditingController(
      text: branch.khqrReceiverAccountId ?? '',
    );
    final nameController = TextEditingController(
      text: branch.khqrReceiverName ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update KHQR Receiver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: accountController,
              decoration: const InputDecoration(
                labelText: 'Receiver account ID',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Receiver name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      accountController.dispose();
      nameController.dispose();
      return;
    }

    await _runSave(() async {
      final accessToken =
          ref.read(loginControllerProvider).session?.accessToken ?? '';
      final updated = await ref
          .read(branchRepositoryProvider)
          .updateCurrentBranchKhqrReceiver(
            khqrReceiverAccountId: accountController.text.trim(),
            khqrReceiverName: nameController.text.trim(),
            accessTokenOverride: accessToken,
          );
      if (!mounted) return;
      setState(() => _branch = updated);
      _showMessage('KHQR receiver updated.');
    });

    accountController.dispose();
    nameController.dispose();
  }

  Future<void> _showAttendanceLocationDialog() async {
    final branch = _branch;
    if (branch == null) return;

    final existingLocation = branch.workplaceLocation;
    final mode = ValueNotifier<String>(
      branch.attendanceLocationVerificationMode.isEmpty
          ? 'disabled'
          : branch.attendanceLocationVerificationMode,
    );
    final radiusController = TextEditingController(
      text: existingLocation?.radiusMeters.toString() ?? '',
    );
    // Holds the lat/lng picked from the map; null means "clear location".
    final pickedLocation = ValueNotifier<LatLng?>(
      existingLocation == null
          ? null
          : LatLng(existingLocation.latitude, existingLocation.longitude),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Attendance Location'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: mode,
                  builder: (context, value, _) => DropdownMenu<String>(
                    width: 360,
                    initialSelection: value,
                    label: const Text('Verification mode'),
                    onSelected: (selected) {
                      if (selected != null) mode.value = selected;
                    },
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'disabled', label: 'Disabled'),
                      DropdownMenuEntry(
                        value: 'checkin_only',
                        label: 'Check-in only',
                      ),
                      DropdownMenuEntry(
                        value: 'checkin_and_checkout',
                        label: 'Check-in and check-out',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Map location picker row
                ValueListenableBuilder<LatLng?>(
                  valueListenable: pickedLocation,
                  builder: (context, picked, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workplace location',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              picked == null
                                  ? 'Not set'
                                  : 'Lat ${picked.latitude.toStringAsFixed(6)},  '
                                        'Lng ${picked.longitude.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: Text(
                              picked == null ? 'Pick on map' : 'Change',
                            ),
                            onPressed: () async {
                              final result = await showLocationPickerDialog(
                                context: dialogContext,
                                initialLocation: picked,
                              );
                              if (result != null) {
                                pickedLocation.value = result;
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: radiusController,
                  decoration: const InputDecoration(labelText: 'Radius (meters)'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      pickedLocation.value = null;
                      radiusController.clear();
                    },
                    child: const Text('Clear workplace location'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      mode.dispose();
      radiusController.dispose();
      pickedLocation.dispose();
      return;
    }

    await _runSave(() async {
      final picked = pickedLocation.value;
      final workplaceLocation = _buildWorkplaceLocation(
        picked,
        radiusController.text,
      );
      final accessToken =
          ref.read(loginControllerProvider).session?.accessToken ?? '';
      final updated = await ref
          .read(branchRepositoryProvider)
          .updateCurrentBranchAttendanceLocation(
            attendanceLocationVerificationMode: mode.value,
            workplaceLocation: workplaceLocation,
            accessTokenOverride: accessToken,
          );
      if (!mounted) return;
      setState(() => _branch = updated);
      _showMessage('Attendance location updated.');
    });

    mode.dispose();
    radiusController.dispose();
    pickedLocation.dispose();
  }

  BranchWorkplaceLocation? _buildWorkplaceLocation(
    LatLng? picked,
    String radiusText,
  ) {
    if (picked == null) return null;
    final radius = radiusText.trim();
    if (radius.isEmpty) {
      throw const ApiClientException(
        message: 'Radius is required when a location is set.',
      );
    }
    final radiusMeters = double.tryParse(radius);
    if (radiusMeters == null) {
      throw const ApiClientException(
        message: 'Radius must be a valid number.',
      );
    }
    return BranchWorkplaceLocation(
      latitude: picked.latitude,
      longitude: picked.longitude,
      radiusMeters: radiusMeters,
    );
  }

  Future<void> _runSave(Future<void> Function() action) async {
    setState(() => _saving = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        UserErrorMessage.build(
          context: 'Failed to update branch settings',
          error: error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final branch = _branch;
    final workplaceLocation = branch?.workplaceLocation;
    final locationSummary = workplaceLocation == null
        ? 'Not configured'
        : 'Lat ${workplaceLocation.latitude.toStringAsFixed(4)}, '
              'Lng ${workplaceLocation.longitude.toStringAsFixed(4)}, '
              'Radius ${workplaceLocation.radiusMeters.toStringAsFixed(0)}m';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Branch Management'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : branch == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage ?? 'Oops, something went wrong.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _SectionCard(
                  title: branch.branchName,
                  actionLabel: 'Read only',
                  onAction: null,
                  rows: [
                    _SummaryRow(label: 'Status', value: branch.status),
                    _SummaryRow(label: 'Branch ID', value: branch.branchId),
                    _SummaryRow(
                      label: 'Address',
                      value: _display(branch.branchAddress),
                    ),
                    _SummaryRow(
                      label: 'Contact number',
                      value: _display(branch.contactNumber),
                    ),
                  ],
                  footer:
                      'Branch profile editing is not available yet because the current backend contract does not expose a branch profile update endpoint.',
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'KHQR Receiver',
                  actionLabel: _saving ? 'Saving...' : 'Edit',
                  onAction: _saving ? null : _showKhqrDialog,
                  rows: [
                    _SummaryRow(
                      label: 'Receiver account ID',
                      value: _display(branch.khqrReceiverAccountId),
                    ),
                    _SummaryRow(
                      label: 'Receiver name',
                      value: _display(branch.khqrReceiverName),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Attendance Location',
                  actionLabel: _saving ? 'Saving...' : 'Edit',
                  onAction: _saving ? null : _showAttendanceLocationDialog,
                  rows: [
                    _SummaryRow(
                      label: 'Verification mode',
                      value: branch.attendanceLocationVerificationMode.isEmpty
                          ? 'Not configured'
                          : branch.attendanceLocationVerificationMode,
                    ),
                    _SummaryRow(
                      label: 'Workplace location',
                      value: locationSummary,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _display(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? 'Not set' : trimmed;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.rows,
    this.actionLabel,
    this.onAction,
    this.footer,
  });

  final String title;
  final List<_SummaryRow> rows;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (actionLabel != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < rows.length; index++) ...[
              rows[index],
              if (index < rows.length - 1) const SizedBox(height: 12),
            ],
            if (footer != null) ...[
              const SizedBox(height: 12),
              Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
