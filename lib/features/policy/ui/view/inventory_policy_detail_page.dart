import 'package:flutter/material.dart';
import 'package:modular_pos/features/policy/ui/widgets/policy_detail_controls.dart';

class InventoryPolicyDetailPage extends StatefulWidget {
  const InventoryPolicyDetailPage({
    super.key,
    required this.subtractStock,
    required this.useRecipes,
    required this.onSaved,
  });

  final bool subtractStock;
  final bool useRecipes;
  final void Function(bool subtractStock, bool useRecipes) onSaved;

  @override
  State<InventoryPolicyDetailPage> createState() => _InventoryPolicyDetailPageState();
}

class _InventoryPolicyDetailPageState extends State<InventoryPolicyDetailPage> {
  bool _isEditing = false;
  late bool _subtractStock;
  late bool _useRecipes;

  @override
  void initState() {
    super.initState();
    _subtractStock = widget.subtractStock;
    _useRecipes = widget.useRecipes;
  }

  void _startEdit() {
    if (_isEditing) return;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _subtractStock = widget.subtractStock;
      _useRecipes = widget.useRecipes;
    });
  }

  void _saveChanges() {
    widget.onSaved(_subtractStock, _useRecipes && _subtractStock);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return PolicyDetailScaffold(
      title: 'Subtract stock on sale',
      isEditing: _isEditing,
      onEditToggle: _isEditing ? _cancelEdit : _startEdit,
      onSave: _saveChanges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PolicySettingGroup(
            children: [
              PolicySwitchTile(
                title: 'Subtract stock on sale',
                subtitle: 'Reduce inventory when a sale is finalized',
                value: _subtractStock,
                enabled: _isEditing,
                onChanged: (value) {
                  setState(() {
                    _subtractStock = value;
                    if (!_subtractStock) {
                      _useRecipes = false;
                    }
                  });
                },
              ),
              PolicySwitchTile(
                title: 'Use recipes for items',
                subtitle: 'Deduct ingredients according to recipe mapping',
                value: _useRecipes,
                enabled: _isEditing && _subtractStock,
                onChanged: (value) => setState(() => _useRecipes = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Recipes are only applied when automatic stock subtraction is enabled.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
