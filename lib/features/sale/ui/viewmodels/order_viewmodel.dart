import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/sync/offline_command_queue_store.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/data/sale_outage_store.dart';
import 'package:modular_pos/features/sale/data/sale_mappers.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';
import 'package:modular_pos/features/sale/domain/models/sale_outage_order.dart';

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(
  OrdersNotifier.new,
);

const orderFulfillmentActiveView = 'FULFILLMENT_ACTIVE';
const orderManualClaimReviewView = 'MANUAL_CLAIM_REVIEW';

enum FulfillmentWorkspaceTab { kitchen, externalClaims }

final fulfillmentWorkspaceTabProvider =
    NotifierProvider<FulfillmentWorkspaceTabNotifier, FulfillmentWorkspaceTab>(
      FulfillmentWorkspaceTabNotifier.new,
    );

class FulfillmentWorkspaceTabNotifier
    extends Notifier<FulfillmentWorkspaceTab> {
  @override
  FulfillmentWorkspaceTab build() => FulfillmentWorkspaceTab.kitchen;

  void setTab(FulfillmentWorkspaceTab tab) {
    state = tab;
  }
}

class OrdersNotifier extends Notifier<List<Order>> {
  static const fulfillmentActiveView = orderFulfillmentActiveView;
  static const manualClaimReviewView = orderManualClaimReviewView;

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
      sourceMode: 'DIRECT_CHECKOUT',
    );
    state = [order, ...state];
  }

  Future<void> load({DateTime? date, String? status, String? view}) async {
    final target = date ?? DateTime.now();
    final resolvedView =
        (view == null || view.trim().isEmpty) &&
            (status == null || status.trim().isEmpty)
        ? fulfillmentActiveView
        : view;
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
        SaleOrdersQueryDto(
          from: start,
          to: end,
          limit: 100,
          status: status,
          view: resolvedView,
        ),
      );
      final orders = page.items
          .map(Order.fromSummary)
          .where((o) => o.orderId.isNotEmpty)
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
    final outageStore = ref.read(saleOutageStoreProvider);
    final queueStore = ref.read(offlineCommandQueueStoreProvider);
    final records = await outageStore.list(scope);
    final orders = <Order>[];
    for (final record in records) {
      final reconciled = await _reconcileLocalCashReplayRecord(
        scope: scope,
        outageStore: outageStore,
        queueStore: queueStore,
        record: record,
      );
      if (reconciled == null) continue;
      orders.add(Order.fromOutageRecord(reconciled));
    }
    return orders;
  }

  Future<SaleOutageOrderRecord?> _reconcileLocalCashReplayRecord({
    required SaleOutageScope scope,
    required SaleOutageStore outageStore,
    required OfflineCommandQueueStore queueStore,
    required SaleOutageOrderRecord record,
  }) async {
    final isManualClaim =
        SaleOutageSourceModes.normalize(record.sourceMode) ==
        SaleOutageSourceModes.manualExternalPaymentClaim;
    if (isManualClaim) {
      return _reconcileLocalManualClaimCaptureRecord(
        scope: scope,
        outageStore: outageStore,
        queueStore: queueStore,
        record: record,
      );
    }

    final queueRecord =
        await queueStore.read(record.localIntentId) ??
        await _findCheckoutCashReplayRecord(
          scope: scope,
          queueStore: queueStore,
          localIntentId: record.localIntentId,
        );
    if (queueRecord == null ||
        queueRecord.operationType !=
            OfflineOperationType.checkoutCashFinalize) {
      return record;
    }

    switch (queueRecord.status) {
      case OfflineCommandQueueStatus.applied:
      case OfflineCommandQueueStatus.duplicate:
        await outageStore.deleteByLocalIntentId(
          scope: scope,
          localIntentId: record.localIntentId,
        );
        return null;
      case OfflineCommandQueueStatus.pending:
        return _syncOutageReplayState(
          outageStore: outageStore,
          record: record,
          state: SaleOutageOrderStates.awaitingSettlement,
        );
      case OfflineCommandQueueStatus.syncing:
        return _syncOutageReplayState(
          outageStore: outageStore,
          record: record,
          state: SaleOutageOrderStates.settlementInProgress,
        );
      case OfflineCommandQueueStatus.failed:
        return _syncOutageReplayState(
          outageStore: outageStore,
          record: record,
          state: SaleOutageOrderStates.finalizationFailed,
          lastErrorCode: queueRecord.lastErrorCode,
          lastErrorMessage: queueRecord.lastErrorMessage,
        );
    }
  }

  Future<SaleOutageOrderRecord> _reconcileLocalManualClaimCaptureRecord({
    required SaleOutageScope scope,
    required SaleOutageStore outageStore,
    required OfflineCommandQueueStore queueStore,
    required SaleOutageOrderRecord record,
  }) async {
    final queueRecord = await _findManualClaimCaptureReplayRecord(
      scope: scope,
      queueStore: queueStore,
      localIntentId: record.localIntentId,
    );
    if (queueRecord == null ||
        queueRecord.operationType !=
            OfflineOperationType.orderManualExternalPaymentClaimCapture) {
      return record;
    }

    final payload = queueRecord.decodePayload();
    final resultRefId = (payload['resultRefId'] ?? '').toString().trim();
    switch (queueRecord.status) {
      case OfflineCommandQueueStatus.applied:
      case OfflineCommandQueueStatus.duplicate:
        if (resultRefId.isEmpty) return record;
        return _syncManualClaimCaptureMaterialization(
          outageStore: outageStore,
          record: record,
          backendOrderId: resultRefId,
          materializedAt: queueRecord.lastSyncedAt ?? DateTime.now().toUtc(),
        );
      case OfflineCommandQueueStatus.pending:
      case OfflineCommandQueueStatus.syncing:
        return _syncOutageReplayState(
          outageStore: outageStore,
          record: record,
          state: record.state,
          lastErrorCode: null,
          lastErrorMessage: null,
        );
      case OfflineCommandQueueStatus.failed:
        return _syncOutageReplayState(
          outageStore: outageStore,
          record: record,
          state: record.state,
          lastErrorCode: queueRecord.lastErrorCode,
          lastErrorMessage: queueRecord.lastErrorMessage,
        );
    }
  }

  Future<OfflineCommandRecord?> _findCheckoutCashReplayRecord({
    required SaleOutageScope scope,
    required OfflineCommandQueueStore queueStore,
    required String localIntentId,
  }) async {
    final queue = await queueStore.listForContext(
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      accountId: scope.accountId,
      statuses: const {
        OfflineCommandQueueStatus.pending,
        OfflineCommandQueueStatus.syncing,
        OfflineCommandQueueStatus.applied,
        OfflineCommandQueueStatus.duplicate,
        OfflineCommandQueueStatus.failed,
      },
      limit: 200,
    );

    for (final record in queue) {
      if (record.operationType != OfflineOperationType.checkoutCashFinalize) {
        continue;
      }
      final payloadLocalIntentId =
          (record.decodePayload()['localIntentId'] ?? '').toString().trim();
      if (payloadLocalIntentId == localIntentId) return record;
    }
    return null;
  }

  Future<OfflineCommandRecord?> _findManualClaimCaptureReplayRecord({
    required SaleOutageScope scope,
    required OfflineCommandQueueStore queueStore,
    required String localIntentId,
  }) async {
    final queue = await queueStore.listForContext(
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      statuses: const {
        OfflineCommandQueueStatus.pending,
        OfflineCommandQueueStatus.syncing,
        OfflineCommandQueueStatus.applied,
        OfflineCommandQueueStatus.duplicate,
        OfflineCommandQueueStatus.failed,
      },
      limit: 200,
    );

    for (final record in queue) {
      if (record.operationType !=
          OfflineOperationType.orderManualExternalPaymentClaimCapture) {
        continue;
      }
      final payloadLocalIntentId =
          (record.decodePayload()['localIntentId'] ?? '').toString().trim();
      if (payloadLocalIntentId == localIntentId) return record;
    }
    return null;
  }

  Future<SaleOutageOrderRecord> _syncOutageReplayState({
    required SaleOutageStore outageStore,
    required SaleOutageOrderRecord record,
    required String state,
    String? lastErrorCode,
    String? lastErrorMessage,
  }) async {
    final normalizedState = SaleOutageOrderStates.normalize(state);
    final nextErrorCode = (lastErrorCode ?? '').trim().isEmpty
        ? null
        : lastErrorCode!.trim();
    final nextErrorMessage = (lastErrorMessage ?? '').trim().isEmpty
        ? null
        : lastErrorMessage!.trim();
    final shouldWrite =
        SaleOutageOrderStates.normalize(record.state) != normalizedState ||
        (record.lastErrorCode ?? '') != (nextErrorCode ?? '') ||
        (record.lastErrorMessage ?? '') != (nextErrorMessage ?? '');
    if (!shouldWrite) return record;

    final updated = record.copyWith(
      state: normalizedState,
      lastErrorCode: nextErrorCode,
      lastErrorMessage: nextErrorMessage,
      updatedAt: DateTime.now().toUtc(),
    );
    await outageStore.write(updated);
    return updated;
  }

  Future<SaleOutageOrderRecord> _syncManualClaimCaptureMaterialization({
    required SaleOutageStore outageStore,
    required SaleOutageOrderRecord record,
    required String backendOrderId,
    required DateTime materializedAt,
  }) async {
    final normalizedBackendOrderId = backendOrderId.trim();
    final shouldWrite =
        (record.backendOrderId ?? '').trim() != normalizedBackendOrderId ||
        record.materializedAt != materializedAt ||
        (record.lastErrorCode ?? '').isNotEmpty ||
        (record.lastErrorMessage ?? '').isNotEmpty;
    if (!shouldWrite) return record;

    final updated = record.copyWith(
      backendOrderId: normalizedBackendOrderId,
      materializedAt: materializedAt,
      lastErrorCode: null,
      lastErrorMessage: null,
      updatedAt: DateTime.now().toUtc(),
    );
    await outageStore.write(updated);
    return updated;
  }

  List<Order> _mergeOrders({
    required List<Order> remoteOrders,
    required List<Order> localOutageOrders,
  }) {
    if (localOutageOrders.isEmpty) return remoteOrders;

    final remoteByKey = <String, Order>{};
    for (final order in remoteOrders) {
      for (final key in _identityKeys(order)) {
        remoteByKey.putIfAbsent(key, () => order);
      }
    }
    final localKeys = <String>{
      for (final order in localOutageOrders) ..._identityKeys(order),
    };
    final mergedLocalOrders = localOutageOrders
        .map((order) {
          for (final key in _identityKeys(order)) {
            final remoteOrder = remoteByKey[key];
            if (remoteOrder != null) {
              return _mergeLocalOutageOrderWithRemoteSummary(
                localOrder: order,
                remoteOrder: remoteOrder,
              );
            }
          }
          return order;
        })
        .toList(growable: false);
    final merged = <Order>[
      ...mergedLocalOrders,
      ...remoteOrders.where((order) {
        for (final key in _identityKeys(order)) {
          if (localKeys.contains(key)) return false;
        }
        return true;
      }),
    ].toList(growable: false);
    return merged;
  }

  Order _mergeLocalOutageOrderWithRemoteSummary({
    required Order localOrder,
    required Order remoteOrder,
  }) {
    final localPaymentMethod = localOrder.paymentMethod.trim().toLowerCase();
    final remotePaymentMethod = remoteOrder.paymentMethod.trim();
    return Order(
      id: localOrder.id,
      saleId: localOrder.saleId.isNotEmpty
          ? localOrder.saleId
          : remoteOrder.saleId,
      number: localOrder.number,
      status: remoteOrder.status,
      ticketStatus: remoteOrder.ticketStatus,
      placedAt: localOrder.placedAt,
      orderType: localOrder.orderType,
      paymentMethod:
          localPaymentMethod == 'unpaid' && remotePaymentMethod.isNotEmpty
          ? remoteOrder.paymentMethod
          : localOrder.paymentMethod,
      totalUsd: localOrder.totalUsd,
      totalKhr: localOrder.totalKhr,
      tenderCurrency: localOrder.tenderCurrency,
      tenderAmount: localOrder.tenderAmount,
      changeAmount: localOrder.changeAmount,
      lines: localOrder.lines.isNotEmpty ? localOrder.lines : remoteOrder.lines,
      sourceMode: localOrder.sourceMode ?? remoteOrder.sourceMode,
      openTicketId: localOrder.openTicketId ?? remoteOrder.openTicketId,
      isLocalOutageOrder: true,
      localOutageState: localOrder.localOutageState,
      localOutageIntentId: localOrder.localOutageIntentId,
      localOutageSourceMode: localOrder.localOutageSourceMode,
      localOutageMaterializedOrderId: localOrder.localOutageMaterializedOrderId,
      localOutageClaimedPaymentMethod:
          localOrder.localOutageClaimedPaymentMethod,
      localOutageClaimedTenderAmount: localOrder.localOutageClaimedTenderAmount,
      localOutageProofImageUrl: localOrder.localOutageProofImageUrl,
      localOutageCustomerReference: localOrder.localOutageCustomerReference,
      localOutageNote: localOrder.localOutageNote,
      localOutageClaimRecordedAt: localOrder.localOutageClaimRecordedAt,
      localOutageBackendClaimId: localOrder.localOutageBackendClaimId,
      localOutageClaimSubmittedAt: localOrder.localOutageClaimSubmittedAt,
      localOutageLastErrorCode: localOrder.localOutageLastErrorCode,
      localOutageLastErrorMessage: localOrder.localOutageLastErrorMessage,
      checkedOutAt: localOrder.checkedOutAt ?? remoteOrder.checkedOutAt,
      remoteManualPaymentClaimId:
          localOrder.remoteManualPaymentClaimId ??
          remoteOrder.remoteManualPaymentClaimId,
      remoteManualPaymentClaimStatus:
          localOrder.remoteManualPaymentClaimStatus ??
          remoteOrder.remoteManualPaymentClaimStatus,
      openedByAccountId:
          localOrder.openedByAccountId ?? remoteOrder.openedByAccountId,
      openedByDisplayName:
          localOrder.openedByDisplayName ?? remoteOrder.openedByDisplayName,
      manualPaymentClaimRequestedByAccountId:
          localOrder.manualPaymentClaimRequestedByAccountId ??
          remoteOrder.manualPaymentClaimRequestedByAccountId,
      manualPaymentClaimRequestedByDisplayName:
          localOrder.manualPaymentClaimRequestedByDisplayName ??
          remoteOrder.manualPaymentClaimRequestedByDisplayName,
      manualPaymentClaimRequestedAt:
          localOrder.manualPaymentClaimRequestedAt ??
          remoteOrder.manualPaymentClaimRequestedAt,
    );
  }

  Iterable<String> _identityKeys(Order order) sync* {
    final localOutageIntentId = (order.localOutageIntentId ?? '').trim();
    if (order.isLocalOutageOrder && localOutageIntentId.isNotEmpty) {
      yield 'local:$localOutageIntentId';
    }
    final orderId = order.orderId;
    if (orderId.isNotEmpty) yield 'order:$orderId';
    final openTicketId = (order.openTicketId ?? '').trim();
    if (openTicketId.isNotEmpty) yield 'ticket:$openTicketId';
    final saleId = order.finalizedSaleId;
    if (saleId.isNotEmpty) yield 'sale:$saleId';
  }

  Future<void> settleOpenTicket(
    Order order, {
    required String tenderCurrency,
  }) async {
    final openTicketId = order.settlementOrderId;
    if (openTicketId == null || openTicketId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Order id is missing for ticket settlement.',
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

  Future<void> updateStatus(String orderIdentityKey, String status) async {
    final targetOrder = _findOrderByIdentity(orderIdentityKey);
    if (targetOrder == null || targetOrder.isLocalOutageOrder) {
      return;
    }

    try {
      if (targetOrder.orderId.isNotEmpty) {
        await _repo.updateFulfillmentStatus(
          orderId: targetOrder.orderId,
          status: status,
        );
      }
    } catch (_) {
      // swallow errors and optimistically update below
    }
    state = [
      for (final order in state)
        if (order.matchesIdentity(orderIdentityKey))
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
            sourceMode: order.sourceMode,
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
            localOutageBackendClaimId: order.localOutageBackendClaimId,
            localOutageClaimSubmittedAt: order.localOutageClaimSubmittedAt,
            localOutageLastErrorCode: order.localOutageLastErrorCode,
            localOutageLastErrorMessage: order.localOutageLastErrorMessage,
            checkedOutAt: order.checkedOutAt,
            remoteManualPaymentClaimId: order.remoteManualPaymentClaimId,
            remoteManualPaymentClaimStatus:
                order.remoteManualPaymentClaimStatus,
            openedByAccountId: order.openedByAccountId,
            openedByDisplayName: order.openedByDisplayName,
            manualPaymentClaimRequestedByAccountId:
                order.manualPaymentClaimRequestedByAccountId,
            manualPaymentClaimRequestedByDisplayName:
                order.manualPaymentClaimRequestedByDisplayName,
            manualPaymentClaimRequestedAt: order.manualPaymentClaimRequestedAt,
          )
        else
          order,
    ];
  }

  Future<SaleCheckoutOpenTicketResultDto> finalizeLocalOutageCashOrder(
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
    final loadedRecord = await store.readByLocalIntentId(
      scope: scope,
      localIntentId: order.localOutageIntentId!,
    );
    if (loadedRecord == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'This outage order is no longer available locally.',
      );
    }
    var currentRecord = loadedRecord;
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
      final existingBackendOrderId = (currentRecord.backendOrderId ?? '')
          .trim();
      if (existingBackendOrderId.isEmpty) {
        final placedOrder = await _repo.placeOrder(
          SalePlaceOrderCommand(
            saleId: currentRecord.localIntentId,
            branchId: currentRecord.branchId,
            saleType: currentRecord.saleType,
            clientOpId:
                'outage-cash-order-${currentRecord.localIntentId}-${now.millisecondsSinceEpoch}',
            cartLines: _commandLinesFromOutageRecord(currentRecord),
          ),
        );
        currentRecord = currentRecord.copyWith(
          backendOrderId: placedOrder.openTicketId,
          materializedAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await store.write(currentRecord);
      }

      final result = await _repo.checkoutOpenTicket(
        SaleCheckoutOpenTicketCommand(
          openTicketId: currentRecord.backendOrderId!,
          paymentMethod: 'cash',
          tenderCurrency: currentRecord.tenderCurrency,
          clientOpId:
              'outage-cash-checkout-${currentRecord.localIntentId}-${DateTime.now().millisecondsSinceEpoch}',
          cashReceived: _cashReceivedForOutageRecord(
            currentRecord,
            cashReceivedAmount: cashReceivedAmount,
          ),
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
        message: 'Proof image is required for a manual payment claim.',
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

  Future<void> recordLocalManualExternalPaymentClaimWithUpload(
    Order order, {
    required double claimedTenderAmount,
    required List<int> proofImageBytes,
    String? customerReference,
    String? note,
  }) async {
    if (proofImageBytes.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Proof image is required for a manual payment claim.',
      );
    }

    final proofImageUrl = await _repo.uploadManualPaymentProofImage(
      imageBytes: proofImageBytes,
    );
    await recordLocalManualExternalPaymentClaim(
      order,
      claimedTenderAmount: claimedTenderAmount,
      proofImageUrl: proofImageUrl,
      customerReference: customerReference,
      note: note,
    );
  }

  Future<SaleCreateManualPaymentClaimResultDto>
  submitManualExternalPaymentClaim(Order order) async {
    if (!order.isLocalOutageOrder || order.localOutageIntentId == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message:
            'Only locally captured outage orders can submit manual claims.',
      );
    }
    if (!order.isManualClaimOutageOrder) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'This outage order is not using the manual-claim flow.',
      );
    }
    if (!order.hasManualExternalPaymentClaimRecorded) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message:
            'Record the manual KHQR claim details locally before submitting it online.',
      );
    }
    if (order.hasSubmittedManualExternalPaymentClaim) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'This manual KHQR claim is already submitted online.',
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
    final loadedRecord = await store.readByLocalIntentId(
      scope: scope,
      localIntentId: order.localOutageIntentId!,
    );
    if (loadedRecord == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'This outage order is no longer available locally.',
      );
    }
    var currentRecord = loadedRecord;

    final claimedMethod = (currentRecord.claimedPaymentMethod ?? '').trim();
    final proofImageUrl = (currentRecord.proofImageUrl ?? '').trim();
    if (claimedMethod.isEmpty || proofImageUrl.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message:
            'Manual claim details are incomplete. Save the claim details before submitting online.',
      );
    }

    await store.write(
      currentRecord.copyWith(
        lastErrorCode: null,
        lastErrorMessage: null,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await load(date: order.placedAt);

    try {
      final existingBackendOrderId = (currentRecord.backendOrderId ?? '')
          .trim();
      if (existingBackendOrderId.isEmpty) {
        final placedOrder = await _repo.placeOrder(
          SalePlaceOrderCommand(
            saleId: currentRecord.localIntentId,
            branchId: currentRecord.branchId,
            saleType: currentRecord.saleType,
            clientOpId:
                'outage-manual-claim-order-${currentRecord.localIntentId}',
            cartLines: _commandLinesFromOutageRecord(currentRecord),
            sourceMode: SaleOutageSourceModes.manualExternalPaymentClaim,
          ),
        );
        currentRecord = currentRecord.copyWith(
          backendOrderId: placedOrder.openTicketId,
          materializedAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await store.write(currentRecord);
      }

      final claimResult = await _repo.createManualPaymentClaim(
        SaleCreateManualPaymentClaimCommand(
          orderId: currentRecord.backendOrderId!,
          claimedPaymentMethod: claimedMethod,
          saleType: currentRecord.saleType,
          tenderCurrency: currentRecord.tenderCurrency,
          claimedTenderAmount:
              currentRecord.claimedTenderAmount ??
              _defaultClaimedAmountForOutageRecord(currentRecord),
          proofImageUrl: proofImageUrl,
          customerReference: currentRecord.customerReference,
          note: currentRecord.note,
          clientOpId:
              'outage-manual-claim-submit-${currentRecord.localIntentId}',
        ),
      );

      await store.write(
        currentRecord.copyWith(
          backendClaimId: claimResult.claimId,
          claimSubmittedAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          lastErrorCode: null,
          lastErrorMessage: null,
        ),
      );
      await load(date: order.placedAt);
      return claimResult;
    } on SaleCheckoutRepositoryException catch (error) {
      await store.write(
        currentRecord.copyWith(
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
          lastErrorCode: SaleCheckoutReasonCodes.unknownError,
          lastErrorMessage: error.toString(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await load(date: order.placedAt);
      rethrow;
    }
  }

  Future<SaleApproveManualPaymentClaimResultDto>
  approveSubmittedManualPaymentClaim(Order order, {String? note}) async {
    if (!order.isLocalOutageOrder || order.localOutageIntentId == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message:
            'Only locally captured outage orders can approve manual claims.',
      );
    }
    if (!order.hasSubmittedManualExternalPaymentClaim) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'No submitted manual claim is waiting for review.',
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
    final backendOrderId = (currentRecord.backendOrderId ?? '').trim();
    final backendClaimId = (currentRecord.backendClaimId ?? '').trim();
    if (backendOrderId.isEmpty || backendClaimId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Backend claim identifiers are missing for this review.',
      );
    }

    try {
      final result = await _repo.approveManualPaymentClaim(
        SaleApproveManualPaymentClaimCommand(
          orderId: backendOrderId,
          claimId: backendClaimId,
          clientOpId:
              'outage-manual-claim-approve-${currentRecord.localIntentId}',
          note: note?.trim().isEmpty == true ? null : note?.trim(),
        ),
      );
      await store.deleteByLocalIntentId(
        scope: scope,
        localIntentId: currentRecord.localIntentId,
      );
      await load(date: DateTime.now());
      return result;
    } on SaleCheckoutRepositoryException catch (error) {
      await store.write(
        currentRecord.copyWith(
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
          lastErrorCode: SaleCheckoutReasonCodes.unknownError,
          lastErrorMessage: error.toString(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await load(date: order.placedAt);
      rethrow;
    }
  }

  Future<SaleRejectManualPaymentClaimResultDto>
  rejectSubmittedManualPaymentClaim(Order order, {String? note}) async {
    if (!order.isLocalOutageOrder || order.localOutageIntentId == null) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message:
            'Only locally captured outage orders can reject manual claims.',
      );
    }
    if (!order.hasSubmittedManualExternalPaymentClaim) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'No submitted manual claim is waiting for review.',
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
    final backendOrderId = (currentRecord.backendOrderId ?? '').trim();
    final backendClaimId = (currentRecord.backendClaimId ?? '').trim();
    if (backendOrderId.isEmpty || backendClaimId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Backend claim identifiers are missing for this review.',
      );
    }

    final trimmedNote = note?.trim();

    try {
      final result = await _repo.rejectManualPaymentClaim(
        SaleRejectManualPaymentClaimCommand(
          orderId: backendOrderId,
          claimId: backendClaimId,
          clientOpId:
              'outage-manual-claim-reject-${currentRecord.localIntentId}',
          note: trimmedNote?.isEmpty == true ? null : trimmedNote,
        ),
      );
      await store.write(
        currentRecord.copyWith(
          state: SaleOutageOrderStates.manualExternalPaymentClaimRecorded,
          backendClaimId: null,
          claimSubmittedAt: null,
          lastErrorCode:
              SaleOutageErrorCodes.manualExternalPaymentClaimRejected,
          lastErrorMessage: trimmedNote?.isEmpty == false
              ? trimmedNote
              : 'Manual KHQR claim was rejected during review.',
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await load(date: order.placedAt);
      return result;
    } on SaleCheckoutRepositoryException catch (error) {
      await store.write(
        currentRecord.copyWith(
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
          lastErrorCode: SaleCheckoutReasonCodes.unknownError,
          lastErrorMessage: error.toString(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await load(date: order.placedAt);
      rethrow;
    }
  }

  Order? _findOrderByIdentity(String orderIdentityKey) {
    for (final order in state) {
      if (order.matchesIdentity(orderIdentityKey)) return order;
    }
    return null;
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

  double _defaultClaimedAmountForOutageRecord(SaleOutageOrderRecord record) {
    if (record.tenderCurrency.trim().toUpperCase() == 'KHR') {
      return record.totalKhr;
    }
    return record.totalUsd;
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
    this.sourceMode,
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
    this.localOutageBackendClaimId,
    this.localOutageClaimSubmittedAt,
    this.localOutageLastErrorCode,
    this.localOutageLastErrorMessage,
    this.checkedOutAt,
    this.remoteManualPaymentClaimId,
    this.remoteManualPaymentClaimStatus,
    this.openedByAccountId,
    this.openedByDisplayName,
    this.manualPaymentClaimRequestedByAccountId,
    this.manualPaymentClaimRequestedByDisplayName,
    this.manualPaymentClaimRequestedAt,
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
  final String? sourceMode;
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
  final String? localOutageBackendClaimId;
  final DateTime? localOutageClaimSubmittedAt;
  final String? localOutageLastErrorCode;
  final String? localOutageLastErrorMessage;
  final DateTime? checkedOutAt;
  final String? remoteManualPaymentClaimId;
  final String? remoteManualPaymentClaimStatus;
  final String? openedByAccountId;
  final String? openedByDisplayName;
  final String? manualPaymentClaimRequestedByAccountId;
  final String? manualPaymentClaimRequestedByDisplayName;
  final DateTime? manualPaymentClaimRequestedAt;

  String get orderId => id.trim();

  String get finalizedSaleId => saleId.trim();

  String get identityKey {
    final localIntentId = (localOutageIntentId ?? '').trim();
    if (isLocalOutageOrder && localIntentId.isNotEmpty) {
      return 'local:$localIntentId';
    }
    if (orderId.isNotEmpty) return 'order:$orderId';
    return 'number:$number';
  }

  String? get settlementOrderId {
    final normalizedOpenTicketId = (openTicketId ?? '').trim();
    if (normalizedOpenTicketId.isNotEmpty) return normalizedOpenTicketId;
    return orderId.isEmpty ? null : orderId;
  }

  bool matchesIdentity(String candidate) {
    final normalizedCandidate = candidate.trim();
    if (normalizedCandidate.isEmpty) return false;
    if (normalizedCandidate == identityKey) return true;
    if (normalizedCandidate == orderId) return true;
    if (normalizedCandidate == number) return true;
    final normalizedOpenTicketId = (openTicketId ?? '').trim();
    if (normalizedCandidate == normalizedOpenTicketId) return true;
    final localIntentId = (localOutageIntentId ?? '').trim();
    if (normalizedCandidate == localIntentId) return true;
    return false;
  }

  bool get isOpenTicket => openTicketId != null && openTicketId!.isNotEmpty;

  String get normalizedSourceMode => (sourceMode ?? '').trim().toUpperCase();

  String get normalizedRemoteManualPaymentClaimStatus =>
      (remoteManualPaymentClaimStatus ?? '').trim().toUpperCase();

  bool get hasRemoteManualPaymentClaim =>
      (remoteManualPaymentClaimId ?? '').trim().isNotEmpty ||
      normalizedRemoteManualPaymentClaimStatus.isNotEmpty;

  bool get hasManualExternalPaymentClaimRecorded =>
      SaleOutageOrderStates.normalize(localOutageState ?? '') ==
      SaleOutageOrderStates.manualExternalPaymentClaimRecorded;

  bool get hasSubmittedManualExternalPaymentClaim =>
      (localOutageBackendClaimId ?? '').trim().isNotEmpty;

  bool get hasPendingRemoteManualPaymentClaim {
    final normalized = normalizedRemoteManualPaymentClaimStatus;
    if (normalized.isEmpty || normalized == 'REJECTED') return false;
    return ticketStatus.trim().toUpperCase() == 'UNPAID';
  }

  bool get hasRejectedManualExternalPaymentClaim =>
      normalizedRemoteManualPaymentClaimStatus == 'REJECTED' ||
      (localOutageLastErrorCode ?? '').trim().toUpperCase() ==
          SaleOutageErrorCodes.manualExternalPaymentClaimRejected;

  String get normalizedLocalOutageState =>
      SaleOutageOrderStates.normalize(localOutageState ?? '');

  bool get isManualClaimOutageOrder =>
      isLocalOutageOrder &&
      (localOutageSourceMode ==
              SaleOutageSourceModes.manualExternalPaymentClaim ||
          hasManualExternalPaymentClaimRecorded);

  bool get isExternalPaymentClaimOrder =>
      isManualClaimOutageOrder ||
      hasRemoteManualPaymentClaim ||
      normalizedSourceMode == 'MANUAL_EXTERNAL_PAYMENT_CLAIM';

  bool get isLegacyOfflineCashOrder =>
      isLocalOutageOrder &&
      !isManualClaimOutageOrder &&
      normalizedLocalOutageState ==
          SaleOutageOrderStates.localOpenOrderCaptured;

  bool get isQueueBackedOfflineCashOrder =>
      isLocalOutageOrder &&
      !isManualClaimOutageOrder &&
      !isLegacyOfflineCashOrder;

  bool get isOfflineCashReplayInProgress =>
      normalizedLocalOutageState == SaleOutageOrderStates.settlementInProgress;

  bool get hasOfflineCashReplayFailure =>
      normalizedLocalOutageState == SaleOutageOrderStates.finalizationFailed;

  String get externalPaymentClaimStatusKey {
    if (hasRejectedManualExternalPaymentClaim) return 'claim_rejected';
    if (hasSubmittedManualExternalPaymentClaim ||
        hasPendingRemoteManualPaymentClaim) {
      return 'claim_pending';
    }
    if (hasManualExternalPaymentClaimRecorded) return 'claim_recorded';
    return 'claim_needs_proof';
  }

  bool get isSettleableOpenTicket =>
      isOpenTicket &&
      ticketStatus.trim().toUpperCase() == 'UNPAID' &&
      !hasManualExternalPaymentClaimRecorded &&
      !hasPendingRemoteManualPaymentClaim;

  bool get isStandardOpenTicket =>
      !isLocalOutageOrder &&
      isSettleableOpenTicket &&
      (normalizedSourceMode.isEmpty || normalizedSourceMode == 'STANDARD');

  bool get isAwaitingOutageSettlement => isLegacyOfflineCashOrder;

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
      sourceMode: 'DIRECT_CHECKOUT',
    );
  }

  factory Order.fromSummary(SaleOrderSummaryDto summary) {
    final ticketStatus = summary.ticketStatus.trim().toUpperCase();
    final normalizedStatus = summary.fulfillmentStatus.trim().isEmpty
        ? (ticketStatus == 'UNPAID' ? 'pending' : 'in_prep')
        : summary.fulfillmentStatus;
    final isOpenTicket = ticketStatus == 'UNPAID';
    return Order(
      id: summary.orderId,
      saleId: summary.saleId,
      number: summary.orderId,
      status: normalizedStatus,
      ticketStatus: ticketStatus,
      placedAt: summary.placedAt.toLocal(),
      orderType: ticketStatus == 'UNPAID' ? 'dine_in' : 'take_away',
      totalUsd: summary.totalUsdExact,
      totalKhr: summary.totalKhrExact,
      tenderCurrency: 'usd',
      tenderAmount: 0,
      changeAmount: 0,
      lines: summary.linesPreview
          .map(
            (line) => OrderLine(
              name: line.name,
              modifiers: line.modifierLabels,
              quantity: line.quantity,
            ),
          )
          .toList(growable: false),
      sourceMode: summary.sourceMode,
      openTicketId: isOpenTicket ? summary.orderId : null,
      checkedOutAt: summary.checkedOutAt?.toLocal(),
      paymentMethod: ticketStatus == 'UNPAID'
          ? 'unpaid'
          : summary.paymentMethod == null
          ? 'cash'
          : SaleMappers.toUiPaymentMethod(summary.paymentMethod!),
      remoteManualPaymentClaimId: summary.manualPaymentClaimId,
      remoteManualPaymentClaimStatus: summary.manualPaymentClaimStatus,
      openedByAccountId: summary.openedByAccountId,
      openedByDisplayName: summary.openedByDisplayName,
      manualPaymentClaimRequestedByAccountId:
          summary.manualPaymentClaimRequestedByAccountId,
      manualPaymentClaimRequestedByDisplayName:
          summary.manualPaymentClaimRequestedByDisplayName,
      manualPaymentClaimRequestedAt: summary.manualPaymentClaimRequestedAt
          ?.toLocal(),
    );
  }

  factory Order.fromOutageRecord(SaleOutageOrderRecord record) {
    final materializedOrderId = (record.backendOrderId ?? '').trim();
    final normalizedState = SaleOutageOrderStates.normalize(record.state);
    final isManualClaim =
        SaleOutageSourceModes.normalize(record.sourceMode) ==
        SaleOutageSourceModes.manualExternalPaymentClaim;
    final isQueueBackedOfflineCash =
        !isManualClaim &&
        normalizedState != SaleOutageOrderStates.localOpenOrderCaptured;
    return Order(
      id: materializedOrderId.isNotEmpty
          ? materializedOrderId
          : record.localIntentId,
      saleId: '',
      number: record.orderNumber,
      status: 'pending',
      ticketStatus: isQueueBackedOfflineCash ? 'PAID' : 'UNPAID',
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
      sourceMode: isManualClaim
          ? 'MANUAL_EXTERNAL_PAYMENT_CLAIM'
          : isQueueBackedOfflineCash
          ? 'DIRECT_CHECKOUT'
          : 'STANDARD',
      openTicketId: isManualClaim && materializedOrderId.isNotEmpty
          ? materializedOrderId
          : null,
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
      localOutageBackendClaimId: record.backendClaimId,
      localOutageClaimSubmittedAt: record.claimSubmittedAt?.toLocal(),
      localOutageLastErrorCode: record.lastErrorCode,
      localOutageLastErrorMessage: record.lastErrorMessage,
      openedByAccountId: record.accountId,
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
