import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/widgets/navigation/unsaved_changes_guard.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';
import 'package:modular_pos/features/policy/ui/view/vat_policy_detail/widgets/vat_rate_bottom_sheet.dart';
import 'package:modular_pos/features/policy/ui/view/policy/policy_route_args.dart';

class VatPolicyDetailPage extends StatefulWidget {
  const VatPolicyDetailPage({
    super.key,
    required this.enabled,
    required this.currentRate,
  });

  final bool enabled;
  final String currentRate;

  @override
  State<VatPolicyDetailPage> createState() => _VatPolicyDetailPageState();
}

class _VatPolicyDetailPageState extends State<VatPolicyDetailPage> {
  bool _isEditing = false;
  late bool _enabled;
  late TextEditingController _rateController;
  late bool _initialEnabled;
  late String _initialRate;

  @override
  void initState() {
    super.initState();
    _initialEnabled = widget.enabled;
    _initialRate = widget.currentRate.replaceAll('%', '');
    _enabled = _initialEnabled;
    _rateController = TextEditingController(text: _initialRate);
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _startEdit() {
    if (_isEditing) return;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _enabled = _initialEnabled;
      _rateController.text = _initialRate;
    });
  }

  void _saveChanges() {
    if (!_canSave) return;
    final parsed = _parsedRate ?? 0;
    context.pop(VatPolicySaveResult(enabled: _enabled, ratePercent: parsed));
  }

  bool get _isDirty {
    if (!_isEditing) return false;
    final currentRate = _rateController.text.trim();
    return _enabled != _initialEnabled || currentRate != _initialRate;
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: _isDirty,
      child: PolicyDetailScaffold(
        title: 'Apply VAT',
        isEditing: _isEditing,
        onEditToggle: _isEditing ? _cancelEdit : _startEdit,
        onSave: _saveChanges,
        canSave: _canSave,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PolicySettingGroup(
              children: [
                PolicySwitchTile(
                  title: 'Apply VAT',
                  value: _enabled,
                  enabled: _isEditing,
                  onChanged: (val) => setState(() => _enabled = val),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'VAT is a tax added to branch sale prices. Use this setting to control whether VAT appears on sales and receipts and what percentage is applied when it is enabled.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_enabled) ...[
              const SizedBox(height: 16),
              PolicySettingGroup(
                children: [
                  PolicyValueTile(
                    title: 'VAT rate (%)',
                    valueText: _formattedRate,
                    enabled: _rateInteractionEnabled,
                    onTap: _openRateSheet,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The VAT rate must stay between 0% and 100%.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_rateError != null) ...[
              const SizedBox(height: 8),
              Text(
                _rateError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _formattedRate => '$_displayRateText%';

  bool get _rateInteractionEnabled => _isEditing && _enabled;

  double? get _parsedRate => double.tryParse(_rateController.text.trim());

  String get _displayRateText {
    final parsed = _parsedRate;
    if (parsed == null) {
      final raw = _rateController.text.trim();
      return raw.isEmpty ? '0' : raw;
    }
    if (parsed == parsed.roundToDouble()) {
      return parsed.toInt().toString();
    }
    return parsed.toString();
  }

  String? get _rateError {
    if (!_isEditing || !_enabled) return null;
    final raw = _rateController.text.trim();
    if (raw.isEmpty) return 'VAT rate is required.';
    final parsed = _parsedRate;
    if (parsed == null) return 'VAT rate must be a valid number.';
    if (parsed < 0 || parsed > 100) {
      return 'VAT rate must be between 0 and 100.';
    }
    return null;
  }

  bool get _canSave => !_isEditing || _rateError == null;

  Future<void> _openRateSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return VatRateBottomSheet(initialValue: _rateController.text);
      },
    );

    if (result == null || result.isEmpty) return;
    setState(() {
      _rateController.text = result;
    });
  }
}
