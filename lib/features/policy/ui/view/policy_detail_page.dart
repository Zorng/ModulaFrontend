import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/app_back_button.dart';
import 'package:modular_pos/features/policy/ui/models/policy_models.dart';

class PolicyDetailPage extends StatefulWidget {
  const PolicyDetailPage({
    super.key,
    required this.item,
    required this.value,
    required this.onSaved,
  });

  final PolicyItem item;
  final dynamic value;
  final ValueChanged<dynamic> onSaved;

  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  bool _isEditing = false;
  late dynamic _tempValue;
  late dynamic _initialValue;

  @override
  void initState() {
    super.initState();
    _tempValue = widget.value;
    _initialValue = widget.value;
  }

  void _startEdit() {
    if (_isEditing) return;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _tempValue = _initialValue;
    });
  }

  void _saveChanges() {
    widget.onSaved(_tempValue);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (widget.item.type) {
      case PolicyItemType.toggle:
        content = SwitchListTile(
          title: Text(widget.item.title),
          subtitle:
              widget.item.subtitle != null ? Text(widget.item.subtitle!) : null,
          value: _tempValue as bool? ?? false,
          onChanged: _isEditing
              ? (value) => setState(() => _tempValue = value)
              : null,
        );
        break;
      case PolicyItemType.selector:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.item.subtitle != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  widget.item.subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (widget.item.options != null)
              ...widget.item.options!.map(
                (option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _tempValue as String?,
                  onChanged: _isEditing
                      ? (value) => setState(() => _tempValue = value)
                      : null,
                ),
              ),
          ],
        );
        break;
      case PolicyItemType.info:
        content = Padding(
          padding: const EdgeInsets.all(16),
          child: Text(widget.item.subtitle ?? 'No editable fields.'),
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppBackButton(),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(widget.item.title),
        ),
        actions: [
          TextButton(
            onPressed: widget.item.type == PolicyItemType.info
                ? null
                : (_isEditing ? _cancelEdit : _startEdit),
            child: Text(_isEditing ? 'Cancel' : 'Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 8),
            content,
            if (_isEditing && widget.item.type != PolicyItemType.info)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
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
      ),
    );
  }
}
