import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/view/add_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/edit_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/view/view_modifier_group_page.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

/// A page for managing modifier groups.
class ModifiersManagementPage extends ConsumerStatefulWidget {
  const ModifiersManagementPage({super.key});

  @override
  ConsumerState<ModifiersManagementPage> createState() =>
      _ModifiersManagementPageState();
}

class _ModifiersManagementPageState
    extends ConsumerState<ModifiersManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(menuViewModelProvider.notifier).refreshModifierGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);
    final modifierGroups = menuState.modifierGroups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifiers Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppSearchAddBar(
              searchHint: 'Search modifiers...',
              onSearchChanged: (_) {},
              onAddPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddModifierGroupPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: menuState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : modifierGroups.isEmpty
                      ? const Center(child: Text('No modifier groups yet'))
                      : ListView.builder(
                          itemCount: modifierGroups.length,
                          itemBuilder: (context, index) {
                            final group = modifierGroups[index];
                            return _ModifierGroupTile(group: group);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModifierGroupTile extends StatelessWidget {
  const _ModifierGroupTile({required this.group});

  final ModifierGroup group;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewModifierGroupPage(group: group),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${group.options.length} options • ${group.selectionType == 'single' ? 'Single' : 'Multiple'} select',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditModifierGroupPage(group: group),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
