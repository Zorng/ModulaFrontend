import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_mappers.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(
  OrdersNotifier.new,
);

class OrdersNotifier extends Notifier<List<Order>> {
  late final SaleCheckoutRepository _repo = ref.read(saleRepositoryProvider);

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
      saleId: id ?? nextNumber,
      number: nextNumber,
      status: 'in_prep',
      ticketStatus: 'PAID',
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
      final page = await _repo.getOrders(
        SaleOrdersQueryDto(from: start, to: end, limit: 100),
      );
      final orders = page.items
          .map(Order.fromSummary)
          .where((o) => o.saleId.isNotEmpty)
          .toList();
      state = orders;
    } catch (_) {
      // keep existing state on failure
    }
  }

  Future<void> settleOpenTicket(
    Order order, {
    required String tenderCurrency,
  }) async {
    final openTicketId = order.openTicketId;
    if (openTicketId == null || openTicketId.trim().isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Open ticket id is missing.',
      );
    }

    final normalizedCurrency = tenderCurrency.trim().toUpperCase();
    final cashReceived = normalizedCurrency == 'KHR'
        ? SaleCashReceivedInputDto(khr: order.totalKhr)
        : SaleCashReceivedInputDto(usd: order.totalUsd);

    await _repo.checkoutOpenTicket(
      SaleCheckoutOpenTicketCommand(
        openTicketId: openTicketId,
        paymentMethod: 'cash',
        tenderCurrency: normalizedCurrency,
        clientOpId:
            'ticket-checkout-$openTicketId-${DateTime.now().millisecondsSinceEpoch}',
        cashReceived: cashReceived,
      ),
    );

    await load(date: order.placedAt);
  }

  Future<void> updateStatus(String number, String status) async {
    try {
      final saleId = state
          .firstWhere(
            (order) => order.number == number || order.id == number,
            orElse: () => Order(
              id: '',
              saleId: '',
              number: '',
              status: '',
              ticketStatus: '',
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
          )
          .id;
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
            saleId: order.saleId,
            number: order.number,
            status: status,
            ticketStatus: order.ticketStatus,
            placedAt: order.placedAt,
            orderType: order.orderType,
            paymentMethod: order.paymentMethod,
            totalUsd: order.totalUsd,
            totalKhr: order.totalKhr,
            tenderCurrency: order.tenderCurrency,
            tenderAmount: order.tenderAmount,
            changeAmount: order.changeAmount,
            lines: order.lines,
            openTicketId: order.openTicketId,
          )
        else
          order,
    ];
  }
}

class Order {
  const Order({
    required this.id,
    required this.saleId,
    required this.number,
    required this.status,
    required this.ticketStatus,
    required this.placedAt,
    required this.orderType,
    required this.paymentMethod,
    required this.totalUsd,
    required this.totalKhr,
    required this.tenderCurrency,
    required this.tenderAmount,
    required this.changeAmount,
    required this.lines,
    this.openTicketId,
  });

  final String id;
  final String saleId;
  final String number;
  final String status;
  final String ticketStatus;
  final DateTime placedAt;
  final String orderType;
  final String paymentMethod;
  final double totalUsd;
  final double totalKhr;
  final String tenderCurrency;
  final double tenderAmount;
  final double changeAmount;
  final List<OrderLine> lines;
  final String? openTicketId;

  bool get isOpenTicket => openTicketId != null && openTicketId!.isNotEmpty;

  bool get isSettleableOpenTicket =>
      isOpenTicket && ticketStatus.trim().toUpperCase() == 'UNPAID';

  factory Order.fromSale(Sale sale) {
    final items = [
      for (final item in sale.items)
        OrderLine(
          name: item.menuItemName.isEmpty ? 'Item' : item.menuItemName,
          modifiers: [for (final mod in item.modifiers) ...mod.optionLabels],
          quantity: item.quantity,
        ),
    ];
    final tenderCurrency = SaleMappers.normalizeTenderCurrency(
      sale.tenderCurrency,
    ).toLowerCase();
    final cashUsd = sale.cashReceivedUsd ?? 0;
    final cashKhr = sale.cashReceivedKhr ?? 0;
    final changeUsd = sale.changeGivenUsd ?? 0;
    final changeKhr = sale.changeGivenKhr ?? 0;
    return Order(
      id: sale.id,
      saleId: sale.id,
      number: sale.id,
      status: sale.fulfillmentStatus.isEmpty
          ? 'in_prep'
          : sale.fulfillmentStatus,
      ticketStatus: sale.state.isEmpty ? 'PAID' : sale.state,
      placedAt: sale.createdAt,
      orderType: sale.saleType.isEmpty ? 'take_away' : sale.saleType,
      paymentMethod: SaleMappers.toUiPaymentMethod(sale.paymentMethod),
      totalUsd: sale.totalUsdExact,
      totalKhr: sale.totalKhrExact,
      tenderCurrency: tenderCurrency,
      tenderAmount: tenderCurrency == 'usd' ? cashUsd : cashKhr,
      changeAmount: tenderCurrency == 'usd' ? changeUsd : changeKhr,
      lines: items,
    );
  }

  factory Order.fromSummary(SaleOrderSummaryDto summary) {
    final ticketStatus = summary.ticketStatus.trim().toUpperCase();
    final normalizedStatus = summary.fulfillmentStatus.trim().isEmpty
        ? (ticketStatus == 'UNPAID' ? 'pending' : 'in_prep')
        : summary.fulfillmentStatus;
    final isOpenTicket = summary.orderId != summary.saleId;
    return Order(
      id: summary.orderId,
      saleId: summary.saleId,
      number: summary.orderId,
      status: normalizedStatus,
      ticketStatus: ticketStatus,
      placedAt: summary.placedAt.toLocal(),
      orderType: ticketStatus == 'UNPAID' ? 'dine_in' : 'take_away',
      paymentMethod: ticketStatus == 'UNPAID' ? 'unpaid' : 'cash',
      totalUsd: summary.totalUsdExact,
      totalKhr: summary.totalKhrExact,
      tenderCurrency: 'usd',
      tenderAmount: 0,
      changeAmount: 0,
      lines: const [],
      openTicketId: isOpenTicket ? summary.orderId : null,
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
