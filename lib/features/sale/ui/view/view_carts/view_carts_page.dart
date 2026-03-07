import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/widgets/navigation/responsive_detail_modal.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/sale_summary.dart';
import 'package:modular_pos/features/sale/ui/view/view_cart_detail/view_cart_detail_page.dart';
import 'package:modular_pos/features/sale/ui/view/view_carts/widgets/sale_summary_card.dart';
import 'package:modular_pos/features/sale/ui/view/view_carts/widgets/view_carts_filters.dart';

class ViewCartsPage extends ConsumerStatefulWidget {
  const ViewCartsPage({super.key});

  @override
  ConsumerState<ViewCartsPage> createState() => _ViewCartsPageState();
}

class _ViewCartsPageState extends ConsumerState<ViewCartsPage> {
  static const _states = ['PENDING', 'FINALIZED', 'VOID_PENDING', 'VOIDED'];
  String _selectedState = 'PENDING';
  DateTime _selectedDate = DateTime.now();
  late Future<List<SaleSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSales();
  }

  Future<List<SaleSummary>> _loadSales() async {
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
        .map(SaleSummary.fromSale)
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
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _future = _loadSales();
    });
  }

  Future<bool> _voidSale(SaleSummary sale) async {
    if (!sale.canVoid) return false;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        title: Row(
          children: [
            const Expanded(child: Text('Void sale')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(false),
            ),
          ],
        ),
        content: const Text('Are you sure you want to void this sale?'),
        actions: [
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    if (confirm != true) return false;

    final repo = ref.read(saleRepositoryProvider);
    try {
      await repo.voidSale(sale.id, reason: 'Voided from POS');
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sale voided')));
      setState(() => _future = _loadSales());
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UserErrorMessage.build(context: 'Failed to void', error: e),
          ),
        ),
      );
      return false;
    }
  }

  void _openSale(SaleSummary sale) {
    showResponsiveDetailModal<void>(
      context: context,
      builder: (modalContext) => ViewCartDetailPage(
        summary: sale,
        showBack: false,
        onVoid: sale.canVoid ? () => _voidSale(sale) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: false, title: const Text('Carts')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ViewCartsFilters(
            selectedDate: _selectedDate,
            selectedState: _selectedState,
            states: _states,
            onPickDate: _pickDate,
            onStateSelected: (state) {
              setState(() {
                _selectedState = state;
                _future = _loadSales();
              });
            },
          ),
          Expanded(
            child: FutureBuilder<List<SaleSummary>>(
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
                      child: SaleSummaryCard(
                        summary: sale,
                        onTap: () => _openSale(sale),
                        onVoid: sale.canVoid ? () => _voidSale(sale) : null,
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
}
