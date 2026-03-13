import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/widgets/navigation/unsaved_changes_guard.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/view/policy/policy_route_args.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class KhrRoundingPolicyDetailPage extends StatefulWidget {
  const KhrRoundingPolicyDetailPage({
    super.key,
    required this.enabled,
    required this.mode,
    required this.granularity,
  });

  final bool enabled;
  final String mode;
  final String granularity;

  @override
  State<KhrRoundingPolicyDetailPage> createState() =>
      _KhrRoundingPolicyDetailPageState();
}

class _KhrRoundingPolicyDetailPageState
    extends State<KhrRoundingPolicyDetailPage> {
  bool _isEditing = false;
  late bool _enabled;
  late String _mode;
  late String _granularity;
  late bool _initialEnabled;
  late String _initialMode;
  late String _initialGranularity;

  static const _modeOptions = <String>[
    BranchPolicyRoundingModes.nearest,
    BranchPolicyRoundingModes.up,
    BranchPolicyRoundingModes.down,
  ];

  static const _granularityOptions = <String>[
    BranchPolicyRoundingGranularities.hundred,
    BranchPolicyRoundingGranularities.thousand,
  ];

  @override
  void initState() {
    super.initState();
    _initialEnabled = widget.enabled;
    _initialMode = BranchPolicyRoundingModes.normalize(widget.mode);
    _initialGranularity = BranchPolicyRoundingGranularities.normalize(
      widget.granularity,
    );
    _enabled = _initialEnabled;
    _mode = _initialMode;
    _granularity = _initialGranularity;
  }

  void _startEdit() {
    if (_isEditing) return;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _enabled = _initialEnabled;
      _mode = _initialMode;
      _granularity = _initialGranularity;
    });
  }

  void _saveChanges() {
    context.pop(
      KhrRoundingPolicySaveResult(
        enabled: _enabled,
        mode: _mode,
        granularity: _granularity,
      ),
    );
  }

  bool get _isDirty {
    if (!_isEditing) return false;
    return _enabled != _initialEnabled ||
        _mode != _initialMode ||
        _granularity != _initialGranularity;
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: _isDirty,
      child: PolicyDetailScaffold(
        title: 'KHR Rounding',
        isEditing: _isEditing,
        onEditToggle: _isEditing ? _cancelEdit : _startEdit,
        onSave: _saveChanges,
        canSave: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PolicySettingGroup(
              children: [
                PolicySwitchTile(
                  title: 'Enable KHR rounding',
                  value: _enabled,
                  enabled: _isEditing,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'KHR rounding controls whether Cambodian Riel totals are rounded at this branch. When rounding is enabled, choose the rounding step size and the rule used to round each amount.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_enabled) ...[
              const SizedBox(height: 12),
              Text(
                'Rounding step',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              PolicySettingGroup(
                children: _granularityOptions
                    .map(
                      (option) => PolicyRadioTile<String>(
                        title: '$option KHR',
                        value: option,
                        groupValue: _granularity,
                        enabled: _isEditing,
                        onChanged: (value) => setState(
                          () => _granularity =
                              BranchPolicyRoundingGranularities.normalize(
                                value,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Rounding rule',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              PolicySettingGroup(
                children: _modeOptions
                    .map(
                      (option) => PolicyRadioTile<String>(
                        title: _modeLabel(option),
                        value: option,
                        groupValue: _mode,
                        enabled: _isEditing,
                        onChanged: (value) => setState(
                          () => _mode = BranchPolicyRoundingModes.normalize(
                            value,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _modeLabel(String mode) {
    switch (BranchPolicyRoundingModes.normalize(mode)) {
      case BranchPolicyRoundingModes.up:
        return 'Up';
      case BranchPolicyRoundingModes.down:
        return 'Down';
      default:
        return 'Nearest';
    }
  }
}
