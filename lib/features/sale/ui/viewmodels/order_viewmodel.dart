import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/data/sale_mappers.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';

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
    final localOrders = await _loadLocalOutageOrders();
    final retainedRemoteOrders = state
        .where((order) => !order.isLocalOutageOrder)
        .toList(growable: false);
    final fallbackOrders = _mergeOrders(
      remoteOrders: retainedRemoteOrders,
      localOutageOrders: localOrders,
    );
    if (localOrders.isNotEmpty || state.isEmpty) {
      state = fallbackOrders;
    }

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
      state = _mergeOrders(
        remoteOrders: orders,
        localOutageOrders: localOrders,
      );
    } catch (_) {
      state = fallbackOrders;
    }
  }

  Future<List<Order>> _loadLocalOutageOrders() async {
    final scope = ref.read(saleOutageScopeProvider);
    if (scope == null) return const <Order>[];
    final records = await ref.read(saleOutageStoreProvider).list(scope);
    return records.map(Order.fromOutageRecord).toList(growable: false);
  }

  List<Order> _mergeOrders({
    required List<Order> remoteOrders,
    required List<Order> localOutageOrders,
  }) {
    if (localOutageOrders.isEmpty) return remoteOrders;

    final seenRemoteKeys = <String>{
      for (final order in remoteOrders) ..._remoteIdentityKeys(order),
    };
    final merged = <Order>[
      ...localOutageOrders.where((order) {
        for (final key in _remoteIdentityKeys(order)) {
          if (seenRemoteKeys.contains(key)) return false;
        }
        return true;
      }),
      ...remoteOrders,
    ];
    return merged;
  }

  Iterable<String> _remoteIdentityKeys(Order order) sync* {
    final saleId = order.saleId.trim();
    final orderId = order.id.trim();
    final openTicketId = (order.openTicketId ?? '').trim();
    if (saleId.isNotEmpty) yield 'sale:$saleId';
    if (orderId.isNotEmpty) yield 'order:$orderId';
    if (openTicketId.isNotEmpty) yield 'ticket:$openTicketId';
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

  Future<SaleFinalizeSaleResultDto> finalizeLocalOutageCashOrder(
    Order order, {
    required double cashReceivedAmount,
  }) async {
    if (!order.isLocalOutageOrder || order.localOutageIntentId == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message:
            'Only locally captured outage orders can be finalized from this flow.',
      );
    }
    if (order.isManualClaimOutageOrder) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message:
            'Manual-claim outage orders require the manual claim review flow.',
      );
    }

    final scope = ref.read(saleOutageScopeProvider);
    if (scope == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.branchRequired,
        message: 'Tenant, branch, or account context is missing.',
      );
    }

    final store = ref.read(saleOutageStoreProvider);
    final currentRecord = await store.readByLocalIntentId(
      scope: scope,
      localIntentId: order.localOutageIntentId!,
    );
    if (currentRecord == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'This outage order is no longer available locally.',
      );
    }
    if (currentRecord.paymentMethodRequested.trim().toLowerCase() != 'cash') {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Only offline cash outage orders can be finalized here.',
      );
    }

    final now = DateTime.now().toUtc();
    await store.write(
      currentRecord.copyWith(
        state: SaleOutageOrderStates.settlementInProgress,
        lastErrorCode: null,
        lastErrorMessage: null,
        updatedAt: now,
      ),
    );
    await load(date: order.placedAt);

    try {
      final result = await _repo.finalizeSale(
        SaleFinalizeSaleCommand(
          saleId: '',
          paymentMethod: 'cash',
          tenderCurrency: currentRecord.tenderCurrency,
          clientOpId:
              'outage-cash-finalize-${currentRecord.localIntentId}-${now.millisecondsSinceEpoch}',
          cashReceived: _cashReceivedForOutageRecord(
            currentRecord,
            cashReceivedAmount: cashReceivedAmount,
          ),
          saleType: currentRecord.saleType,
          cartLines: _commandLinesFromOutageRecord(currentRecord),
        ),
      );

      await store.deleteByLocalIntentId(
        scope: scope,
        localIntentId: currentRecord.localIntentId,
      );
      await load(date: order.placedAt);
      return result;
    } on SaleCheckoutRepositoryException catch (error) {
      await store.write(
        currentRecord.copyWith(
          state: SaleOutageOrderStates.finalizationFailed,
          lastErrorCode: error.reasonCode,
          lastErrorMessage: error.message,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await load(date: order.placedAt);
      rethrow;
    } catch (error) {
      await store.write(
        currentRecord.copyWith(
          state: SaleOutageOrderStates.finalizationFailed,
          lastErrorCode: SaleCheckoutReasonCodes.unknownError,
          lastErrorMessage: error.toString(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await load(date: order.placedAt);
      rethrow;
    }
  }

  Future<void> recordLocalManualExternalPaymentClaim(
    Order order, {
    required double claimedTenderAmount,
    required String proofImageUrl,
    String? customerReference,
    String? note,
  }) async {
    if (!order.isLocalOutageOrder || order.localOutageIntentId == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message:
            'Only locally captured outage orders can record manual claims.',
      );
    }

    final scope = ref.read(saleOutageScopeProvider);
    if (scope == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.branchRequired,
        message: 'Tenant, branch, or account context is missing.',
      );
    }

    final store = ref.read(saleOutageStoreProvider);
    final currentRecord = await store.readByLocalIntentId(
      scope: scope,
      localIntentId: order.localOutageIntentId!,
    );
    if (currentRecord == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'This outage order is no longer available locally.',
      );
    }

    final normalizedProofUrl = proofImageUrl.trim();
    if (normalizedProofUrl.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Proof image URL is required for a manual payment claim.',
      );
    }

    final normalizedCustomerReference = customerReference?.trim();
    final normalizedNote = note?.trim();
    final now = DateTime.now().toUtc();

    await store.write(
      currentRecord.copyWith(
        state: SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
        claimedPaymentMethod: 'KHQR',
        claimedTenderAmount: claimedTenderAmount,
        proofImageUrl: normalizedProofUrl,
        customerReference: normalizedCustomerReference?.isEmpty == true
            ? null
            : normalizedCustomerReference,
        note: normalizedNote?.isEmpty == true ? null : normalizedNote,
        claimRecordedAt: now,
        updatedAt: now,
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
            isLocalOutageOrder: order.isLocalOutageOrder,
            localOutageState: order.localOutageState,
            localOutageIntentId: order.localOutageIntentId,
            localOutageSourceMode: order.localOutageSourceMode,
            localOutageMaterializedOrderId:
                order.localOutageMaterializedOrderId,
            localOutageClaimedPaymentMethod:
                order.localOutageClaimedPaymentMethod,
            localOutageClaimedTenderAmount:
                order.localOutageClaimedTenderAmount,
            localOutageProofImageUrl: order.localOutageProofImageUrl,
            localOutageCustomerReference: order.localOutageCustomerReference,
            localOutageNote: order.localOutageNote,
            localOutageClaimRecordedAt: order.localOutageClaimRecordedAt,
          )
        else
          order,
    ];
  }

  SaleCashReceivedInputDto _cashReceivedForOutageRecord(
    SaleOutageOrderRecord record, {
    required double cashReceivedAmount,
  }) {
    final tenderCurrency = record.tenderCurrency.trim().toUpperCase();
    if (tenderCurrency == 'KHR') {
      return SaleCashReceivedInputDto(khr: cashReceivedAmount);
    }
    return SaleCashReceivedInputDto(usd: cashReceivedAmount);
  }

  List<SaleCartLineInputDto> _commandLinesFromOutageRecord(
    SaleOutageOrderRecord record,
  ) {
    return record.lines
        .map((line) {
          final modifiers = line.selectedOptionIds.entries
              .map(
                (entry) => SaleCartModifierInputDto(
                  groupId: entry.key,
                  optionIds: List<String>.from(entry.value),
                ),
              )
              .toList(growable: false);
          return SaleCartLineInputDto(
            menuItemId: line.menuItemId,
            quantity: line.quantity,
            modifiers: modifiers,
            unitPriceUsd: line.unitPriceUsd,
            lineTotalUsdExact: line.lineTotalUsdExact,
          );
        })
        .toList(growable: false);
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
    this.isLocalOutageOrder = false,
    this.localOutageState,
    this.localOutageIntentId,
    this.localOutageSourceMode,
    this.localOutageMaterializedOrderId,
    this.localOutageClaimedPaymentMethod,
    this.localOutageClaimedTenderAmount,
    this.localOutageProofImageUrl,
    this.localOutageCustomerReference,
    this.localOutageNote,
    this.localOutageClaimRecordedAt,
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
  final bool isLocalOutageOrder;
  final String? localOutageState;
  final String? localOutageIntentId;
  final String? localOutageSourceMode;
  final String? localOutageMaterializedOrderId;
  final String? localOutageClaimedPaymentMethod;
  final double? localOutageClaimedTenderAmount;
  final String? localOutageProofImageUrl;
  final String? localOutageCustomerReference;
  final String? localOutageNote;
  final DateTime? localOutageClaimRecordedAt;

  bool get isOpenTicket => openTicketId != null && openTicketId!.isNotEmpty;

  bool get hasManualExternalPaymentClaimRecorded =>
      SaleOutageOrderStates.normalize(localOutageState ?? '') ==
      SaleOutageOrderStates.manualExternalPaymentClaimRecorded;

  bool get isManualClaimOutageOrder =>
      isLocalOutageOrder &&
      (localOutageSourceMode ==
              SaleOutageSourceModes.manualExternalPaymentClaim ||
          hasManualExternalPaymentClaimRecorded);

  bool get isSettleableOpenTicket =>
      isOpenTicket &&
      ticketStatus.trim().toUpperCase() == 'UNPAID' &&
      !hasManualExternalPaymentClaimRecorded;

  bool get isAwaitingOutageSettlement => isLocalOutageOrder && !isOpenTicket;

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

  factory Order.fromOutageRecord(SaleOutageOrderRecord record) {
    final materializedOrderId = (record.backendOrderId ?? '').trim();
    return Order(
      id: materializedOrderId.isNotEmpty
          ? materializedOrderId
          : record.localIntentId,
      saleId: materializedOrderId.isNotEmpty
          ? materializedOrderId
          : record.localIntentId,
      number: record.orderNumber,
      status: 'pending',
      ticketStatus: 'UNPAID',
      placedAt: record.createdAt.toLocal(),
      orderType: record.saleType,
      paymentMethod: record.paymentMethodRequested,
      totalUsd: record.totalUsd,
      totalKhr: record.totalKhr,
      tenderCurrency: record.tenderCurrency.toLowerCase(),
      tenderAmount:
          record.claimedTenderAmount ??
          (record.tenderCurrency.toUpperCase() == 'KHR'
              ? record.cashReceivedKhr
              : record.cashReceivedUsd),
      changeAmount: 0,
      lines: record.lines
          .map(
            (line) => OrderLine(
              name: line.name,
              modifiers: line.modifierLabels,
              quantity: line.quantity,
            ),
          )
          .toList(growable: false),
      openTicketId: materializedOrderId.isNotEmpty ? materializedOrderId : null,
      isLocalOutageOrder: true,
      localOutageState: record.state,
      localOutageIntentId: record.localIntentId,
      localOutageSourceMode: record.sourceMode,
      localOutageMaterializedOrderId: materializedOrderId.isEmpty
          ? null
          : materializedOrderId,
      localOutageClaimedPaymentMethod: record.claimedPaymentMethod,
      localOutageClaimedTenderAmount: record.claimedTenderAmount,
      localOutageProofImageUrl: record.proofImageUrl,
      localOutageCustomerReference: record.customerReference,
      localOutageNote: record.note,
      localOutageClaimRecordedAt: record.claimRecordedAt?.toLocal(),
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
