import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';

final ordersProvider =
    NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<List<Order>> {
  late final SaleRepository _repo = ref.read(saleRepositoryProvider);

  @override
  List<Order> build() => const [];

  void createOrder({
    String? id,
    required String orderType,
    required String paymentMethod,
    required double totalUsd,
    required double totalKhr,
    required String tenderCurrency,
    required double tenderAmount,
    required double changeAmount,
    required List<OrderLine> lines,
  }) {
    final nextNumber = (state.length + 1).toString().padLeft(3, '0');
    final order = Order(
      id: id ?? nextNumber,
      number: nextNumber,
      status: 'in_prep',
      placedAt: DateTime.now(),
      orderType: orderType,
      paymentMethod: paymentMethod,
      totalUsd: totalUsd,
      totalKhr: totalKhr,
      tenderCurrency: tenderCurrency,
      tenderAmount: tenderAmount,
      changeAmount: changeAmount,
      lines: lines,
    );
    state = [order, ...state];
  }

  Future<void> load({DateTime? date}) async {
    final target = date ?? DateTime.now();
    final start = DateTime(target.year, target.month, target.day);
    final end = start.add(const Duration(days: 1));
    try {
      final sales = await _repo.listSales(
        status: 'finalized',
        startDate: start,
        endDate: end,
        limit: 100,
      );
      final orders = sales
          .map((sale) => Order.fromJson(sale))
          .where((o) => o.id.isNotEmpty)
          .toList();
      state = orders;
    } catch (_) {
      // keep existing state on failure
    }
  }

  Future<void> updateStatus(String number, String status) async {
    try {
      final saleId = state.firstWhere(
        (order) => order.number == number || order.id == number,
        orElse: () => Order(
          id: '',
          number: '',
          status: '',
          placedAt: DateTime.fromMillisecondsSinceEpoch(0),
          orderType: '',
          paymentMethod: '',
          totalUsd: 0,
          totalKhr: 0,
          tenderCurrency: '',
          tenderAmount: 0,
          changeAmount: 0,
          lines: [],
        ),
      ).id;
      if (saleId.isNotEmpty) {
        await _repo.updateFulfillmentStatus(saleId: saleId, status: status);
      }
    } catch (_) {
      // swallow errors and optimistically update below
    }
    state = [
      for (final order in state)
        if (order.number == number || order.id == number)
          Order(
            id: order.id,
            number: order.number,
            status: status,
            placedAt: order.placedAt,
            orderType: order.orderType,
            paymentMethod: order.paymentMethod,
            totalUsd: order.totalUsd,
            totalKhr: order.totalKhr,
            tenderCurrency: order.tenderCurrency,
            tenderAmount: order.tenderAmount,
            changeAmount: order.changeAmount,
            lines: order.lines,
          )
        else
          order,
    ];
  }
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.status,
    required this.placedAt,
    required this.orderType,
    required this.paymentMethod,
    required this.totalUsd,
    required this.totalKhr,
    required this.tenderCurrency,
    required this.tenderAmount,
    required this.changeAmount,
    required this.lines,
  });

  final String id;
  final String number;
  final String status;
  final DateTime placedAt;
  final String orderType;
  final String paymentMethod;
  final double totalUsd;
  final double totalKhr;
  final String tenderCurrency;
  final double tenderAmount;
  final double changeAmount;
  final List<OrderLine> lines;

  factory Order.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final placed = DateTime.tryParse(json['createdAt']?.toString() ?? '')
            ?.toLocal() ??
        DateTime.now();
    final items = <OrderLine>[];
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
        items.add(
          OrderLine(
            name: item['menuItemName']?.toString() ?? 'Item',
            modifiers: mods,
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          ),
        );
      }
    }
    final tenderCurrency =
        (json['tenderCurrency']?.toString() ?? 'usd').toLowerCase();
    final cashUsd = (json['cashReceivedUsd'] as num?)?.toDouble() ?? 0;
    final cashKhr = (json['cashReceivedKhr'] as num?)?.toDouble() ?? 0;
    final changeUsd = (json['changeGivenUsd'] as num?)?.toDouble() ?? 0;
    final changeKhr = (json['changeGivenKhr'] as num?)?.toDouble() ?? 0;
    return Order(
      id: id,
      number: id,
      status: json['fulfillmentStatus']?.toString() ?? 'in_prep',
      placedAt: placed,
      orderType: json['saleType']?.toString() ?? 'take_away',
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      totalUsd: (json['totalUsdExact'] as num?)?.toDouble() ??
          (json['totalUsd'] as num?)?.toDouble() ??
          0,
      totalKhr: (json['totalKhrExact'] as num?)?.toDouble() ??
          (json['totalKhr'] as num?)?.toDouble() ??
          0,
      tenderCurrency: tenderCurrency,
      tenderAmount: tenderCurrency == 'usd' ? cashUsd : cashKhr,
      changeAmount: tenderCurrency == 'usd' ? changeUsd : changeKhr,
      lines: items,
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.name,
    required this.modifiers,
    required this.quantity,
  });

  final String name;
  final List<String> modifiers;
  final int quantity;
}
