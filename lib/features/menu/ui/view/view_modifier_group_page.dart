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
        centerTitle: false,
        title: Text(resolvedGroup.name),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditModifierGroupPage(group: resolvedGroup),
                  fullscreenDialog: true,
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
              (option) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(option.name),
                    if (option.price > 0)
                      Text(
                        '+ \$${option.price.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                  ],
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
