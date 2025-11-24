import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class VatPolicyDetailPage extends StatefulWidget {
  const VatPolicyDetailPage({
    super.key,
    required this.enabled,
    required this.currentRate,
    required this.onSaved,
  });

  final bool enabled;
  final String currentRate;
  final void Function(bool enabled, String rate) onSaved;

  @override
  State<VatPolicyDetailPage> createState() => _VatPolicyDetailPageState();
}

class _VatPolicyDetailPageState extends State<VatPolicyDetailPage> {
  bool _isEditing = false;
  late bool _enabled;
  late TextEditingController _rateController;
  String? _errorText;
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
      _errorText = null;
    });
  }

  void _saveChanges() {
    var rate = _rateController.text.trim();
    if (rate.isEmpty) {
      rate = '0';
    }
    final parsed = int.tryParse(rate);
    if (parsed == null || parsed <= 0) {
      setState(() => _errorText = 'Enter a positive number');
      return;
    }
    setState(() => _errorText = null);
    final formattedRate = '$parsed%';
    widget.onSaved(_enabled, formattedRate);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return PolicyDetailScaffold(
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
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  String get _formattedRate =>
      '${_rateController.text.isEmpty ? '0' : _rateController.text}%';

  bool get _rateInteractionEnabled => _isEditing && _enabled;

  Future<void> _openRateSheet() async {
    final controller = TextEditingController(text: _rateController.text);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VAT rate (%)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Enter rate',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }
    final parsed = int.tryParse(result);
    if (parsed == null || parsed <= 0) {
      setState(() => _errorText = 'Enter a positive number');
      return;
    }
    setState(() {
      _errorText = null;
      _rateController.text = parsed.toString();
    });
  }
}
