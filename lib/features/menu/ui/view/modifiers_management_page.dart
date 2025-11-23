import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_modifier_group_page.dart';

/// A page for managing modifier groups.
class ModifiersManagementPage extends StatefulWidget {
  const ModifiersManagementPage({super.key});

  @override
  State<ModifiersManagementPage> createState() => _ModifiersManagementPageState();
}

/// Represents a single option within a modifier group (e.g., "Small", "Medium").
class ModifierOption {
  final String name;
  final double price;

  ModifierOption({required this.name, this.price = 0.0});
}

/// A data model representing a group of modifiers (e.g., "Size", "Toppings").
class ModifierGroupInfo {
  final String name;
  final int optionCount;
  final List<ModifierOption> options;

  ModifierGroupInfo({
    required this.name,
    required this.options,
  }) : optionCount = options.length;

  // Override equality to make Set operations work correctly.
  @override
  bool operator ==(Object other) => other is ModifierGroupInfo && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

class _ModifiersManagementPageState extends State<ModifiersManagementPage> {
  // Mock data for display
  List<ModifierGroupInfo> _modifierGroups = [
    ModifierGroupInfo(
      name: 'Size',
      options: [
        ModifierOption(name: 'Small', price: 2.50),
        ModifierOption(name: 'Medium', price: 3.50),
        ModifierOption(name: 'Large', price: 4.50),
      ],
    ),
    ModifierGroupInfo(
      name: 'Sugar Level',
      options: [
        ModifierOption(name: '100%'),
        ModifierOption(name: '75%'),
        ModifierOption(name: '50%'),
        ModifierOption(name: '25%'),
      ],
    ),
    ModifierGroupInfo(name: 'Toppings', options: [ModifierOption(name: 'Boba', price: 0.50)]),
    ModifierGroupInfo(name: 'Ice Level', options: [ModifierOption(name: 'Regular'), ModifierOption(name: 'Less Ice')]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifiers Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppSearchAddBar(
              searchHint: 'Search modifiers...',
              onSearchChanged: (value) {
                // TODO: Implement search logic
              },
              onAddPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return AddModifierGroupPage(onAdd: (newGroup) {
                    setState(() {
                      _modifierGroups.insert(0, newGroup);
                    });
                  });
                }));
              },
            ),
            const SizedBox(height: 16),
            // --- List of Modifier Groups ---
            Expanded(
              child: ListView.builder(
                itemCount: _modifierGroups.length,
                itemBuilder: (context, index) {
                  final group = _modifierGroups[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return ViewModifierGroupPage(
                          initialGroup: group,
                          onGroupUpdated: (updatedGroup) {
                            setState(() => _modifierGroups[index] = updatedGroup);
                          },
                        );
                      }));
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(group.name, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text('${group.optionCount} options', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) {
                                  return EditModifierGroupPage(
                                    groupToEdit: group,
                                    onSave: (updatedGroup) {
                                      setState(() => _modifierGroups[index] = updatedGroup);
                                    },
                                  );
                                }));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}