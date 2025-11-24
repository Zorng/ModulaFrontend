import 'package:flutter/material.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';
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
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    Widget? header;

    switch (widget.item.type) {
      case PolicyItemType.toggle:
        content = PolicySettingGroup(
          children: [
            PolicySwitchTile(
              title: widget.item.title,
              subtitle: widget.item.subtitle,
              value: _tempValue as bool? ?? false,
              enabled: _isEditing,
              onChanged: (value) => setState(() => _tempValue = value),
            ),
          ],
        );
        break;
      case PolicyItemType.selector:
        final options = widget.item.options ?? const [];
        if (widget.item.subtitle != null) {
          header = Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.item.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        content = PolicySettingGroup(
          children: options
              .map(
                (option) => PolicyRadioTile<String>(
                  title: option,
                  value: option,
                  groupValue: _tempValue as String?,
                  enabled: _isEditing,
                  onChanged: (value) => setState(() => _tempValue = value),
                ),
              )
              .toList(),
        );
        break;
      case PolicyItemType.info:
        content = PolicySettingGroup(
          children: [
            PolicyComingSoonTile(
              title: widget.item.title,
              subtitle: widget.item.subtitle ?? 'Coming soon',
            ),
          ],
        );
        break;
    }

    return PolicyDetailScaffold(
      title: widget.item.title,
      isEditing: _isEditing,
      onEditToggle: widget.item.type == PolicyItemType.info
          ? () {}
          : (_isEditing ? _cancelEdit : _startEdit),
      onSave: widget.item.type == PolicyItemType.info ? null : _saveChanges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) header!,
          content,
        ],
      ),
      canSave: widget.item.type != PolicyItemType.info,
    );
  }
}
