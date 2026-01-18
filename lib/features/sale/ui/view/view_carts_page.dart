import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';

class ViewCartsPage extends ConsumerStatefulWidget {
  const ViewCartsPage({super.key});

  @override
  ConsumerState<ViewCartsPage> createState() => _ViewCartsPageState();
}

class _ViewCartsPageState extends ConsumerState<ViewCartsPage> {
  static const _states = ['draft', 'finalized', 'voided', 'reopened'];
  String _selectedState = 'draft';
  DateTime _selectedDate = DateTime.now();
  late Future<List<_SaleSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSales();
  }

  Future<List<_SaleSummary>> _loadSales() async {
    final repo = ref.read(saleRepositoryProvider);
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final end = start.add(const Duration(days: 1));
    final data = await repo.listSales(
      status: _selectedState,
      startDate: start,
      endDate: end,
      limit: 100,
    );
    return data
        .map(_SaleSummary.fromJson)
        .where((s) => s.id.isNotEmpty)
        .toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _future = _loadSales();
      });
    }
  }

  Future<void> _voidSale(_SaleSummary sale) async {
    if (sale.state != 'draft') return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        title: Row(
          children: [
            const Expanded(child: Text('Void draft')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
        content: const Text('Are you sure you want to void this draft cart?'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final repo = ref.read(saleRepositoryProvider);
    try {
      await repo.voidSale(sale.id, reason: 'Voided from POS');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Draft voided')));
      setState(() => _future = _loadSales());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(context: 'Failed to void', error: e),
          ),
        ),
      );
    }
  }

  void _openSale(_SaleSummary sale) {
    // For now, just show read-only detail; wiring to editable cart would require loading items.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _SaleDetailPage(summary: sale)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(_selectedDate);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: const Text('Carts'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(dateLabel),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final state = _states[index];
                return ChoiceChip(
                  label: Text(_stateLabel(state)),
                  selected: _selectedState == state,
                  onSelected: (_) {
                    setState(() {
                      _selectedState = state;
                      _future = _loadSales();
                    });
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _states.length,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<_SaleSummary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      UserErrorMessage.build(
                        context: 'Failed to load carts',
                        error: snapshot.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final sales = snapshot.data ?? const [];
                if (sales.isEmpty) {
                  return const Center(child: Text('No carts for this day'));
                }
                return ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openSale(sale),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _formatTime(sale.createdAt),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: sale.state == 'draft'
                                          ? () => _voidSale(sale)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _stateColor(
                                            sale.state,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          _stateLabel(sale.state),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: _stateColor(sale.state),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: sale.lines
                                      .map(
                                        (line) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: Text(
                                            '${line.quantity} × ${line.name}'
                                            '${line.modifiers.isNotEmpty ? ' (${line.modifiers.join(', ')})' : ''}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _stateLabel(String state) {
    return switch (state) {
      'draft' => 'Draft',
      'finalized' => 'Finalized',
      'voided' => 'Voided',
      'reopened' => 'Reopened',
      _ => state,
    };
  }

  Color _stateColor(String state) {
    return switch (state) {
      'draft' => Colors.amber.shade700,
      'finalized' => Colors.green.shade700,
      'voided' => Colors.red.shade700,
      'reopened' => Colors.blue.shade700,
      _ => Colors.grey.shade700,
    };
  }
}

class _SaleSummary {
  const _SaleSummary({
    required this.id,
    required this.state,
    required this.createdAt,
    required this.lines,
  });

  final String id;
  final String state;
  final DateTime createdAt;
  final List<_SaleLine> lines;

  factory _SaleSummary.fromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final lines = <_SaleLine>[];
    if (json['items'] is List) {
      for (final item in json['items'] as List) {
        if (item is! Map<String, dynamic>) continue;
        final mods = <String>[];
        if (item['modifiers'] is List) {
          for (final m in item['modifiers'] as List) {
            if (m is! Map<String, dynamic>) continue;
            final options = m['options'];
            if (options is List) {
              for (final o in options) {
                if (o is Map<String, dynamic>) {
                  final label = o['label']?.toString() ?? o['name']?.toString();
                  if (label != null && label.isNotEmpty) mods.add(label);
                }
              }
            }
          }
        }
        lines.add(
          _SaleLine(
            name: item['menuItemName']?.toString() ?? 'Item',
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            modifiers: mods,
          ),
        );
      }
    }
    return _SaleSummary(
      id: json['id']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      createdAt: created,
      lines: lines,
    );
  }
}

class _SaleLine {
  const _SaleLine({
    required this.name,
    required this.quantity,
    required this.modifiers,
  });

  final String name;
  final int quantity;
  final List<String> modifiers;
}

class _SaleDetailPage extends StatelessWidget {
  const _SaleDetailPage({required this.summary});

  final _SaleSummary summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: const Text('Cart Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatTime(summary.createdAt),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _detailStateColor(
                      summary.state,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _detailStateLabel(summary.state),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _detailStateColor(summary.state),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...summary.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${line.quantity} × ${line.name}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (line.modifiers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          line.modifiers.join(', '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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

  String _detailStateLabel(String state) {
    return switch (state) {
      'draft' => 'Draft',
      'finalized' => 'Finalized',
      'voided' => 'Voided',
      'reopened' => 'Reopened',
      _ => state,
    };
  }

  Color _detailStateColor(String state) {
    return switch (state) {
      'draft' => Colors.amber.shade700,
      'finalized' => Colors.green.shade700,
      'voided' => Colors.red.shade700,
      'reopened' => Colors.blue.shade700,
      _ => Colors.grey.shade700,
    };
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = monthNames[date.month - 1];
  final year = date.year;
  return '$month $day, $year';
}

String _formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
