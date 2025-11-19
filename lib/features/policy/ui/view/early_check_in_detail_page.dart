import 'package:flutter/material.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class EarlyCheckInDetailPage extends StatefulWidget {
  const EarlyCheckInDetailPage({
    super.key,
    required this.enabled,
    required this.duration,
    required this.onSaved,
  });

  final bool enabled;
  final String duration;
  final void Function(bool enabled, String duration) onSaved;

  @override
  State<EarlyCheckInDetailPage> createState() => _EarlyCheckInDetailPageState();
}

class _EarlyCheckInDetailPageState extends State<EarlyCheckInDetailPage> {
  bool _isEditing = false;
  late bool _enabled;
  late String _duration;

  final _durations = const ['15 min', '30 min', '1 hour'];

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _duration = widget.duration;
  }

  void _startEdit() => setState(() => _isEditing = true);

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _enabled = widget.enabled;
      _duration = widget.duration;
    });
  }

  void _saveChanges() {
    widget.onSaved(_enabled, _duration);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return PolicyDetailScaffold(
      title: 'Early check-in buffer',
      isEditing: _isEditing,
      onEditToggle: _isEditing ? _cancelEdit : _startEdit,
      onSave: _saveChanges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PolicySettingGroup(
            children: [
              PolicySwitchTile(
                title: 'Early check-in buffer',
                subtitle: 'Allow staff to start shift early within buffer',
                value: _enabled,
                enabled: _isEditing,
                onChanged: (value) => setState(() => _enabled = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Buffer duration', style: Theme.of(context).textTheme.bodyMedium),
          PolicySettingGroup(
            children: _durations
                .map(
                  (d) => PolicyRadioTile<String>(
                    title: d,
                    value: d,
                    groupValue: _duration,
                    enabled: _isEditing && _enabled,
                    onChanged: (value) => setState(() => _duration = value ?? _duration),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
