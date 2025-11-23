import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form_page.dart';
import 'package:modular_pos/features/menu/ui/view/modifiers_management_page.dart';

/// A page to view the details of a menu item in a read-only format.
class ViewMenuItemPage extends StatefulWidget {
  const ViewMenuItemPage({
    super.key,
    required this.menuItem,
    required this.categories,
    required this.modifierGroups,
    required this.onItemUpdated,
  });

  final MenuItem menuItem;
  final List<String> categories;
  final List<ModifierGroupInfo> modifierGroups;
  final ValueSetter<MenuItem> onItemUpdated;

  @override
  State<ViewMenuItemPage> createState() => _ViewMenuItemPageState();
}

class _ViewMenuItemPageState extends State<ViewMenuItemPage> {
  late MenuItem _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.menuItem;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentItem.name),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuItemFormPage(
                    itemId: _currentItem.id, // Pass the ID to enter 'edit' mode
                    initialItem: _currentItem,
                    categories: widget.categories,
                    modifierGroups: widget.modifierGroups,
                    onSave: (updatedItem) {
                      setState(() {
                        _currentItem = updatedItem;
                      });
                      widget.onItemUpdated(updatedItem);
                    },
                  ),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: AbsorbPointer(
          // This widget makes the form fields read-only but allows scrolling.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image ---
              Center(
                child: Container(
                  width: 159.69,
                  height: 149,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: _currentItem.imagePath != null
                        ? DecorationImage(
                            image: AssetImage(_currentItem.imagePath!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _currentItem.imagePath == null
                      ? const Center(
                          child: Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 40),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // --- Item Name ---
              _buildLabel('Item Name'),
              TextField(
                controller: TextEditingController(text: _currentItem.name),
                decoration: const InputDecoration(hintText: 'Enter item name'),
              ),
              const SizedBox(height: 16),

              // --- Description ---
              _buildLabel('Description'),
              const TextField(
                decoration: InputDecoration(hintText: 'Enter item description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // --- Base Price ---
              _buildLabel('Base price'),
              TextField(
                controller: TextEditingController(text: _currentItem.price.toStringAsFixed(2)),
                decoration: const InputDecoration(hintText: '0.00'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // --- Category Dropdown ---
              _buildLabel('Category'),
              DropdownButtonFormField<String>(
                value: _currentItem.category,
                items: widget.categories.where((c) => c != 'All').map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: null,
              ),
              const SizedBox(height: 16),

              // --- Assign to Branch Dropdown ---
              _buildLabel('Assign to Branch'),
              DropdownButtonFormField<String>(
                value: 'All Branches', // Placeholder
                items: const ['All Branches', 'Main Branch', 'Downtown'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: null,
              ),
              const SizedBox(height: 24),

              // --- Modifier Group ---
              Text('Modifier Group', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              // Display the item's associated modifiers
              if (_currentItem.modifierGroups.isEmpty)
                const Text('No modifiers assigned.', style: TextStyle(color: Colors.grey))
              else
                ..._currentItem.modifierGroups.map((group) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: textTheme.titleMedium),
                        const Divider(),
                        ...group.options.map((option) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(option.name, style: textTheme.bodyLarge),
                                if (option.price > 0)
                                  Text(
                                    '+\$${option.price.toStringAsFixed(2)}',
                                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // --- Set Active Switch ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Set Active', style: textTheme.titleMedium),
                  CupertinoSwitch(
                    value: true, // Placeholder
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (bool value) {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build form field labels.
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}