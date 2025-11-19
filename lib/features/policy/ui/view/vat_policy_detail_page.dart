import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modular_pos/core/widgets/app_back_button.dart';

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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppBackButton(),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('VAT'),
        ),
        actions: [
          TextButton(
            onPressed: _isEditing ? _cancelEdit : _startEdit,
            child: Text(_isEditing ? 'Cancel' : 'Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.7,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Apply VAT'),
                  subtitle: const Text('Show VAT line on sales and receipts'),
                  value: _enabled,
                  onChanged:
                      _isEditing ? (val) => setState(() => _enabled = val) : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('VAT rate (%)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formattedRate,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: _rateInteractionEnabled
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.4),
                            ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right,
                        color: _rateInteractionEnabled
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                      ),
                    ],
                  ),
                  enabled: _rateInteractionEnabled,
                  onTap: _rateInteractionEnabled ? _openRateSheet : null,
                ),
              ],
            ),
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
          if (_isEditing)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: _saveChanges,
                  child: const Text('Save'),
                ),
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
