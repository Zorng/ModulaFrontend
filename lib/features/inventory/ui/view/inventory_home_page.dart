import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key});

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  String _selectedBranch = 'Main Branch';
  String _selectedCategory = 'All';
  bool _lowStockOnly = false;
  final _searchController = TextEditingController();

  final _branches = const ['Main Branch', 'Downtown', 'Airport'];
  final _categories = const ['All', 'Dairy', 'Packaging', 'Produce'];
  final _items = const [
    _InventoryItem(
      name: 'Milk 1000ml',
      category: 'Dairy',
      unit: 'pcs',
      onHand: 24,
      minThreshold: 20,
    ),
    _InventoryItem(
      name: 'Straws Paper',
      category: 'Packaging',
      unit: 'pcs',
      onHand: 12,
      minThreshold: 30,
    ),
    _InventoryItem(
      name: 'Oranges',
      category: 'Produce',
      unit: 'kg',
      onHand: 18,
      minThreshold: 15,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesLowStock = !_lowStockOnly || item.isLowStock;
      return matchesCategory && matchesSearch && matchesLowStock;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchAddBar(
              searchHint: 'Search stock items',
              searchController: _searchController,
              onSearchChanged: (_) => setState(() {}),
              onAddPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add stock item coming soon')),
                );
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final selected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showBranchSelector,
                  icon: const Icon(Icons.store_outlined),
                  label: Text(_selectedBranch),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: _openFilterSheet,
                  tooltip: 'Filters',
                  icon: const Icon(Icons.filter_list),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _InventoryRow(item: item);
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    var tempLowStock = _lowStockOnly;
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleMedium),
                  SwitchListTile.adaptive(
                    title: const Text('Low stock only'),
                    value: tempLowStock,
                    onChanged: (value) => setModalState(() => tempLowStock = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setModalState(() => tempLowStock = false),
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(tempLowStock),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _lowStockOnly = result);
    }
  }

  Future<void> _showBranchSelector() async {
    final branch = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final branch = _branches[index];
              final selected = branch == _selectedBranch;
              return ListTile(
                title: Text(branch),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(branch),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: _branches.length,
          ),
        );
      },
    );

    if (branch != null) {
      setState(() => _selectedBranch = branch);
    }
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.item});

  final _InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.category),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${item.onHand} ${item.unit}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: item.isLowStock ? colorScheme.error : null,
                  )),
          Text('Min ${item.minThreshold}',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InventoryItem {
  const _InventoryItem({
    required this.name,
    required this.category,
    required this.unit,
    required this.onHand,
    required this.minThreshold,
  });

  final String name;
  final String category;
  final String unit;
  final int onHand;
  final int minThreshold;

  bool get isLowStock => onHand < minThreshold;
}

extension on _InventoryHomePageState {
  Future<void> _openFilterSheet() async {
    var tempLowStock = _lowStockOnly;
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleMedium),
                  SwitchListTile.adaptive(
                    title: const Text('Low stock only'),
                    value: tempLowStock,
                    onChanged: (value) => setModalState(() => tempLowStock = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setModalState(() => tempLowStock = false),
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(tempLowStock),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _lowStockOnly = result);
    }
  }
}
