import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/ui/view/order_detail_page.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_card.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_filters_bar.dart';
import 'package:modular_pos/features/sale/ui/view/order/widgets/order_status_bottom_sheet.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/order_viewmodel.dart';

class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({super.key});

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> {
  String _selectedStatus = 'in_prep';
  static const _statuses = ['in_prep', 'ready', 'delivered', 'cancelled'];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).load(date: _selectedDate);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await ref.read(ordersProvider.notifier).load(date: picked);
    }
  }

  void _openStatusSheet(Order order) {
    final notifier = ref.read(ordersProvider.notifier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => OrderStatusBottomSheet(
        initialStatus: order.status,
        onSubmit: (status) => notifier.updateStatus(order.number, status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final filtered = orders.where((o) => o.status == _selectedStatus).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders'), centerTitle: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderFiltersBar(
            selectedDate: _selectedDate,
            onPickDate: _pickDate,
            statuses: _statuses,
            selectedStatus: _selectedStatus,
            onStatusChanged: (status) =>
                setState(() => _selectedStatus = status),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No orders'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return OrderCard(
                        order: order,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailPage(orderNumber: order.number),
                            ),
                          );
                        },
                        onStatusTap: () => _openStatusSheet(order),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
