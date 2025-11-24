import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A page to view the details of a modifier group.
class ViewModifierGroupPage extends ConsumerWidget {
  const ViewModifierGroupPage({super.key, required this.group});

  final ModifierGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(menuViewModelProvider);
    final resolvedGroup = state.modifierGroups
        .firstWhere((g) => g.id == group.id, orElse: () => group);

    return Scaffold(
      appBar: AppBar(
        title: Text('View: ${resolvedGroup.name}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditModifierGroupPage(group: resolvedGroup),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resolvedGroup.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${resolvedGroup.selectionType == "single" ? "Single selection" : "Multiple selection"} • ${_behaviorLabel(resolvedGroup.pricingBehavior)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('Options', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...resolvedGroup.options.map(
              (option) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.name),
                trailing: option.price > 0
                    ? Text('+ \$${option.price.toStringAsFixed(2)}')
                    : const SizedBox.shrink(),
                leading: Icon(
                  resolvedGroup.defaultOptionId == option.id
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: resolvedGroup.defaultOptionId == option.id
                      ? Theme.of(context).primaryColor
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _behaviorLabel(String behavior) {
    switch (behavior) {
      case 'fixed':
        return 'Fixed pricing';
      case 'none':
        return 'No price change';
      case 'addon':
      default:
        return 'Add-on pricing';
    }
  }
}
