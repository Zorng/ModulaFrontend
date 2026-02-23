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
    var rate = _rateController.text.trim();
    if (rate.isEmpty) rate = '0';
    final parsed = int.tryParse(rate) ?? 0;
    context.pop(
      VatPolicySaveResult(enabled: _enabled, ratePercent: parsed.toDouble()),
    );
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
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PolicySettingGroup(
            children: [
              PolicySwitchTile(
                title: 'Apply VAT',
                subtitle: 'Show VAT line on sales and receipts',
                value: _enabled,
                enabled: _isEditing,
                onChanged: (val) => setState(() => _enabled = val),
              ),
              PolicyValueTile(
                title: 'VAT rate (%)',
                valueText: _formattedRate,
                enabled: _rateInteractionEnabled,
                onTap: _openRateSheet,
                hint: 'Enable and edit rate',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The VAT rate is applied only when VAT is enabled.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        ),
      ),
    );
  }

  String get _formattedRate =>
      '${_rateController.text.isEmpty ? '0' : _rateController.text}%';

  bool get _rateInteractionEnabled => _isEditing && _enabled;

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
