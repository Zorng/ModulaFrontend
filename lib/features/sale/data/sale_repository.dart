import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';
import 'package:modular_pos/features/branchV2/domain/models/branch_models.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/policy/domain/models/policy.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';
import 'package:modular_pos/features/sale/data/dto/sale_dto.dart';
import 'package:modular_pos/features/sale/data/sale_mappers.dart';
import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';
import 'package:modular_pos/features/sale/domain/models/sale.dart';

final remoteSaleRepositoryProvider = Provider<SaleCheckoutRepository>((ref) {
  final api = ref.watch(saleApiProvider);
  final loginState = ref.watch(loginControllerProvider);
  final branchState = ref.watch(branchControllerProvider);
  final cashSessionState = ref.watch(cashSessionViewModelProvider);
  final policyState = ref.watch(policyNotifierProvider);
  return SaleRepository(
    api,
    loginStateReader: () => loginState,
    branchStateReader: () => branchState,
    cashSessionStateReader: () => cashSessionState,
    policyStateReader: () => policyState,
  );
});

final mockSaleRepositoryProvider = Provider<SaleCheckoutRepository>((ref) {
  return MockSaleRepository();
});

final saleRepositoryProvider = Provider<SaleCheckoutRepository>((ref) {
  // Sale runtime stays on the real API lane; tests can explicitly override
  // either this provider or the dedicated mock/remote providers.
  return ref.watch(remoteSaleRepositoryProvider);
});

final saleCartRepositoryProvider = Provider<SaleCartRepository>((ref) {
  return ref.watch(saleRepositoryProvider);
});

class SaleRepository implements SaleCheckoutRepository {
  SaleRepository(
    this._api, {
    LoginState Function()? loginStateReader,
    BranchState Function()? branchStateReader,
    CashSessionState Function()? cashSessionStateReader,
    PolicyState Function()? policyStateReader,
  }) : _loginStateReader = loginStateReader ?? _defaultLoginStateReader,
       _branchStateReader = branchStateReader ?? _defaultBranchStateReader,
       _cashSessionStateReader =
           cashSessionStateReader ?? _defaultCashSessionStateReader,
       _policyStateReader = policyStateReader ?? _defaultPolicyStateReader;

  final SaleApi _api;
  final LoginState Function() _loginStateReader;
  final BranchState Function() _branchStateReader;
  final CashSessionState Function() _cashSessionStateReader;
  final PolicyState Function() _policyStateReader;

  @override
  Future<String> ensureDraft({
    String? clientUuid,
    required String saleType,
    double fxRateUsed = 4100,
  }) async {
    final uuid = clientUuid ?? _randomUuid();

    // Always create explicit draft with required fields to avoid missing fxRate errors.
    final created = await _api.createDraft({
      'clientUuid': uuid,
      'saleType': saleType,
      'fxRateUsed': fxRateUsed,
    });
    final createdId = created.id;
    if (createdId.isEmpty) {
      throw Exception('Failed to create draft sale');
    }
    return createdId;
  }

  @override
  Future<String?> addItem({
    required String saleId,
    required SaleDraftItemInputDto item,
  }) async {
    final sale = await _api.addItem(saleId, item.toLegacyApiJson());

    // Best-effort: find the most recently-added matching item.
    for (final saleItem in sale.items.reversed) {
      if (saleItem.menuItemId != item.menuItemId) continue;
      if (_modifiersMatch(saleItem.modifiers, item.selectedOptionIds)) {
        if (saleItem.id.isNotEmpty) return saleItem.id;
      }
    }
    return null;
  }

  @override
  Future<void> updateItemQuantity({
    required String saleId,
    required String itemId,
    required int quantity,
  }) async {
    await _api.updateItemQuantity(saleId, itemId, quantity);
  }

  @override
  Future<void> removeItem({
    required String saleId,
    required String itemId,
  }) async {
    await _api.removeItem(saleId, itemId);
  }

  @override
  Future<SaleCheckoutSummary> preCheckout({
    required String saleId,
    required String tenderCurrency,
    required String paymentMethod,
    Map<String, num>? cashReceived,
  }) async {
    final body = {
      // API expects uppercase currency codes (see docs/apiSchema/saleSchema.ts).
      'tenderCurrency': tenderCurrency.toUpperCase(),
      'paymentMethod': paymentMethod,
      if (cashReceived != null && cashReceived.isNotEmpty)
        'cashReceived': cashReceived,
    };
    final sale = await _api.preCheckout(saleId, body);
    return SaleMappers.toCheckoutSummaryFromDraft(sale);
  }

  @override
  Future<SaleCheckoutSummary> finalize(String saleId) async {
    final sale = await _api.finalize(saleId);
    return SaleMappers.toCheckoutSummaryFromDraft(sale);
  }

  @override
  Future<void> updateFulfillmentStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    final normalizedOrderId = orderId.trim();
    final normalizedStatus = status.trim().toUpperCase();
    final normalizedNote = note?.trim();
    await _api.updateOrderFulfillmentStatus(
      normalizedOrderId,
      status: normalizedStatus,
      note: normalizedNote,
      idempotency: IdempotencyRequest(
        actionKey: 'order.fulfillment.update',
        intentId:
            'order-fulfillment-$normalizedOrderId-$normalizedStatus-'
            '${DateTime.now().microsecondsSinceEpoch}',
        payload: {
          'orderId': normalizedOrderId,
          'status': normalizedStatus,
          if (normalizedNote != null && normalizedNote.isNotEmpty)
            'note': normalizedNote,
        },
      ),
    );
  }

  @override
  Future<List<Sale>> listSales({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final data = await _api.listSales(
      status: status,
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
    );
    return data
        .map(SaleMappers.toDomainSale)
        .where((sale) => sale.id.isNotEmpty)
        .toList();
  }

  @override
  Future<SaleVoidRequestQueuePageDto> getSaleVoidRequests(
    SaleVoidRequestQueueQueryDto query,
  ) async {
    final normalizedStatus = query.status?.trim().toUpperCase();
    try {
      final page = await _api.listSaleVoidRequests(
        status: normalizedStatus == null || normalizedStatus.isEmpty
            ? null
            : normalizedStatus,
        limit: query.limit,
        offset: query.offset,
      );
      return SaleMappers.toSaleVoidRequestQueuePage(page);
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleDetailReadDto> getSaleDetail({required String saleId}) async {
    try {
      final sale = await _api.getSaleDetail(saleId.trim());
      return SaleMappers.toSaleDetailRead(sale);
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleVoidRequestReadDto?> getSaleVoidRequest({
    required String saleId,
  }) async {
    try {
      final request = await _api.getSaleVoidRequest(saleId.trim());
      return SaleMappers.toSaleVoidRequestRead(request);
    } on ApiClientException catch (error) {
      final normalizedCode = _readString(error.code).toUpperCase();
      if (error.statusCode == 404 ||
          normalizedCode == 'VOID_REQUEST_NOT_FOUND') {
        return null;
      }
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleVoidRequestReadDto> requestSaleVoid(
    SaleRequestVoidCommand command,
  ) async {
    final normalizedSaleId = command.saleId.trim();
    final normalizedReason = command.reason.trim();
    if (normalizedSaleId.isEmpty || normalizedReason.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Sale id and reason are required before requesting void.',
      );
    }

    final payload = <String, dynamic>{'reason': normalizedReason};
    try {
      final request = await _api.requestSaleVoid(
        normalizedSaleId,
        payload,
        idempotency: IdempotencyRequest(
          actionKey: 'sale.void.request',
          intentId: command.clientOpId.trim().isEmpty
              ? _randomUuid()
              : command.clientOpId.trim(),
          payload: {'saleId': normalizedSaleId, ...payload},
        ),
      );
      return SaleMappers.toSaleVoidRequestRead(request);
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleVoidRequestReadDto> approveSaleVoid(
    SaleApproveVoidCommand command,
  ) async {
    final normalizedSaleId = command.saleId.trim();
    if (normalizedSaleId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Sale id is required before approving void.',
      );
    }

    final normalizedNote = command.note?.trim();
    final payload = <String, dynamic>{
      if (normalizedNote != null && normalizedNote.isNotEmpty)
        'note': normalizedNote,
    };
    try {
      final request = await _api.approveSaleVoid(
        normalizedSaleId,
        payload,
        idempotency: IdempotencyRequest(
          actionKey: 'sale.void.approve',
          intentId: command.clientOpId.trim().isEmpty
              ? _randomUuid()
              : command.clientOpId.trim(),
          payload: {'saleId': normalizedSaleId, ...payload},
        ),
      );
      return SaleMappers.toSaleVoidRequestRead(request);
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleVoidRequestReadDto> rejectSaleVoid(
    SaleRejectVoidCommand command,
  ) async {
    final normalizedSaleId = command.saleId.trim();
    if (normalizedSaleId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Sale id is required before rejecting void.',
      );
    }

    final normalizedNote = command.note?.trim();
    final payload = <String, dynamic>{
      if (normalizedNote != null && normalizedNote.isNotEmpty)
        'note': normalizedNote,
    };
    try {
      final request = await _api.rejectSaleVoid(
        normalizedSaleId,
        payload,
        idempotency: IdempotencyRequest(
          actionKey: 'sale.void.reject',
          intentId: command.clientOpId.trim().isEmpty
              ? _randomUuid()
              : command.clientOpId.trim(),
          payload: {'saleId': normalizedSaleId, ...payload},
        ),
      );
      return SaleMappers.toSaleVoidRequestRead(request);
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<void> voidSale(String saleId, {required String reason}) async {
    await _api.voidSale(saleId, reason: reason);
  }

  @override
  Future<SaleContextDto> getSaleContext({required String branchId}) async {
    final normalizedBranchId = branchId.trim();
    final session = _loginStateReader().session;
    if (session == null || session.accessToken.trim().isEmpty) {
      return SaleContextDto(
        branchId: normalizedBranchId,
        branchActive: false,
        branchFrozen: false,
        cashSessionOpen: false,
        canMutateCart: false,
        canCheckout: false,
        canPlacePayLater: false,
        reasonCode: SaleCheckoutReasonCodes.unauthorized,
        reasonMessage: 'Your account no longer has access to sell.',
      );
    }

    if (normalizedBranchId.isEmpty) {
      return const SaleContextDto(
        branchId: '',
        branchActive: false,
        branchFrozen: false,
        cashSessionOpen: false,
        canMutateCart: false,
        canCheckout: false,
        canPlacePayLater: false,
        reasonCode: SaleCheckoutReasonCodes.branchRequired,
        reasonMessage: 'Active branch context is required.',
      );
    }

    final branch = _findBranch(normalizedBranchId);
    final authBranch = _findAuthBranch(normalizedBranchId);
    final branchActive = branch?.isActive ?? authBranch?.active ?? true;
    final branchFrozen = branch?.isFrozen ?? !branchActive;
    final cashSessionOpen = _hasOpenCashSessionForBranch(normalizedBranchId);
    final payLaterEnabled = _policyAllowsPayLater(normalizedBranchId);

    String? reasonCode;
    String? reasonMessage;
    if (branchFrozen) {
      reasonCode = SaleCheckoutReasonCodes.branchFrozen;
      reasonMessage = 'Branch is currently frozen for write operations.';
    } else if (!cashSessionOpen) {
      reasonCode = SaleCheckoutReasonCodes.cashSessionRequired;
      reasonMessage = 'Open cash session is required before this action.';
    }

    return SaleContextDto(
      branchId: normalizedBranchId,
      branchActive: branchActive,
      branchFrozen: branchFrozen,
      cashSessionOpen: cashSessionOpen,
      canMutateCart:
          reasonCode == null ||
          reasonCode == SaleCheckoutReasonCodes.cashSessionRequired,
      canCheckout: reasonCode == null,
      canPlacePayLater: reasonCode == null && payLaterEnabled,
      reasonCode: reasonCode,
      reasonMessage: reasonMessage,
    );
  }

  @override
  Future<SaleCheckoutPreviewDto> computeCheckoutPreview(
    SaleComputeCheckoutPreviewCommand command,
  ) async {
    return _estimateCheckoutPreview(
      saleId: command.saleId,
      paymentMethod: command.paymentMethod,
      cartLines: command.cartLines,
      tenderCurrency: command.tenderCurrency,
      cashReceived: command.cashReceived,
    );
  }

  @override
  Future<SaleKhqrAttemptDto> generateKhqrAttempt(
    SaleGenerateKhqrAttemptCommand command,
  ) async {
    try {
      final payload = <String, dynamic>{
        'items': command.cartLines.map(_toCheckoutItemPayload).toList(),
        if (command.saleType != null)
          'saleType': _normalizeSaleType(command.saleType!),
        if (command.expiresInSeconds != null)
          'expiresInSeconds': command.expiresInSeconds,
      };
      final data = await _api.initiateKhqrIntent(
        payload,
        idempotency: IdempotencyRequest(
          actionKey: 'checkout.khqr.initiate',
          intentId: command.clientOpId,
          payload: payload,
        ),
      );
      return SaleMappers.toKhqrAttempt(
        command: command,
        response: data,
        expiresAt: DateTime.now().add(
          Duration(seconds: command.expiresInSeconds ?? 180),
        ),
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleKhqrStatusDto> checkKhqrStatus(
    SaleCheckKhqrStatusCommand command,
  ) async {
    final intentId = _readString(command.intentId);
    if (intentId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'KHQR intent is not available for this cart.',
      );
    }
    try {
      final data = await _api.getKhqrIntentStatus(intentId);
      return SaleMappers.toKhqrStatus(command: command, state: data);
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleKhqrStatusDto> cancelKhqrAttempt(
    SaleCancelKhqrAttemptCommand command,
  ) async {
    final intentId = _readString(command.intentId);
    if (intentId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'KHQR intent is not available for this cart.',
      );
    }
    try {
      final data = await _api.cancelKhqrIntent(
        intentId,
        idempotency: IdempotencyRequest(
          actionKey: 'checkout.khqr.cancel',
          intentId: command.clientOpId,
          payload: command.toJson(),
        ),
      );
      return SaleKhqrStatusDto(
        saleId: command.saleId,
        md5: command.md5,
        status: SaleMappers.normalizeKhqrStatus(
          rawStatus: data.status,
          saleId: null,
        ),
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleFinalizeSaleResultDto> finalizeSale(
    SaleFinalizeSaleCommand command,
  ) async {
    try {
      final paymentMethod = command.paymentMethod.toLowerCase();
      if (paymentMethod == 'cash') {
        final tenderCurrency = command.tenderCurrency.toUpperCase();
        final payload = <String, dynamic>{
          'items': command.cartLines.map(_toCheckoutItemPayload).toList(),
          if (command.saleType != null)
            'saleType': _normalizeSaleType(command.saleType!),
          'tenderCurrency': tenderCurrency,
        };
        final cashReceivedTenderAmount = _cashReceivedTenderAmount(
          tenderCurrency: tenderCurrency,
          cashReceived: command.cashReceived,
        );
        if (cashReceivedTenderAmount != null) {
          payload['cashReceivedTenderAmount'] = cashReceivedTenderAmount;
        }
        final data = await _api.finalizeCashCheckout(
          payload,
          idempotency: IdempotencyRequest(
            actionKey: 'checkout.cash.finalize',
            intentId: command.clientOpId,
            payload: payload,
          ),
        );
        return SaleMappers.toFinalizeResultFromCashCheckout(data);
      }

      final normalizedIntentId = _readString(command.khqrIntentId);
      final normalizedSaleId = command.saleId.trim();
      if (normalizedIntentId.isNotEmpty) {
        final intentState = await _api.getKhqrIntentStatus(normalizedIntentId);
        final finalizedSaleId = _readString(intentState.saleId);
        if (finalizedSaleId.isNotEmpty) {
          return _buildMaterializedKhqrFinalizeResult(finalizedSaleId);
        }
        final normalizedStatus = intentState.status.trim().toUpperCase();
        if (normalizedStatus == 'PAID_CONFIRMED') {
          final normalizedMd5 = _readString(command.khqrMd5);
          if (normalizedMd5.isEmpty) {
            throw const SaleCheckoutRepositoryException(
              reasonCode: SaleCheckoutReasonCodes.khqrFinalizationPending,
              message:
                  'KHQR payment is confirmed, but finalize fallback cannot continue because the payment reference is missing.',
            );
          }
          final confirm = await _api.confirmKhqrPayment(
            normalizedMd5,
            idempotency: IdempotencyRequest(
              actionKey: 'payment.khqr.confirm',
              intentId: 'checkout-khqr-confirm-$normalizedIntentId',
              payload: {
                'md5': normalizedMd5,
                'paymentIntentId': normalizedIntentId,
              },
            ),
          );
          final confirmedSaleId = _readString(confirm.sale?.saleId);
          if (confirm.saleFinalized && confirmedSaleId.isNotEmpty) {
            return _buildMaterializedKhqrFinalizeResult(confirmedSaleId);
          }
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.khqrFinalizationPending,
            message:
                'KHQR payment is confirmed, but backend finalization is still pending. Please wait a moment and try again.',
          );
        }
        throw const SaleCheckoutRepositoryException(
          reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
          message: 'KHQR payment is not confirmed yet.',
        );
      }
      if (normalizedSaleId.isNotEmpty) {
        return _buildMaterializedKhqrFinalizeResult(normalizedSaleId);
      }
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
        message: 'KHQR intent is not available for this cart.',
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  Future<SaleFinalizeSaleResultDto> _buildMaterializedKhqrFinalizeResult(
    String saleId,
  ) async {
    final sale = await _api.getSaleDetail(saleId);
    SaleImmediateReceiptDto? receipt;
    String? receiptId;
    try {
      final receiptRead = await _api.getReceiptBySaleId(saleId);
      receiptId = receiptRead.receiptId;
      receipt = SaleImmediateReceiptDto(
        receiptId: receiptRead.receiptId,
        saleId: receiptRead.saleId,
        statusDisplay: receiptRead.statusDisplay,
        issuedAt: receiptRead.issuedAt.toLocal(),
      );
    } on ApiClientException catch (error) {
      // KHQR quick checkout should still succeed even if receipt hydration lags.
      if (error.statusCode != 404) {
        throw _toSaleRepoException(error);
      }
    }

    return SaleFinalizeSaleResultDto(
      saleId: sale.id,
      status: SaleMappers.normalizeSaleState(sale.state),
      totalUsdExact: sale.totalUsdExact,
      totalKhrExact: sale.totalKhrExact,
      idempotentReplay: false,
      cashReceivedUsd: sale.cashReceivedUsd,
      cashReceivedKhr: sale.cashReceivedKhr,
      changeGivenUsd: sale.changeGivenUsd,
      changeGivenKhr: sale.changeGivenKhr,
      orderId: sale.orderId,
      receiptId: receiptId,
      receipt: receipt,
    );
  }

  @override
  Future<SalePlaceOrderResultDto> placeOrder(
    SalePlaceOrderCommand command,
  ) async {
    final normalizedSourceMode = _readString(command.sourceMode).toUpperCase();
    final isManualClaimOrder =
        normalizedSourceMode == 'MANUAL_EXTERNAL_PAYMENT_CLAIM';
    if (!isManualClaimOrder && !_policyAllowsPayLater(command.branchId)) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.payLaterDisabled,
        message: 'Pay-later order placement is disabled for this branch.',
      );
    }

    if (command.cartLines.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Cannot place an order with an empty cart.',
      );
    }

    final payload = <String, dynamic>{
      'items': command.cartLines.map(_toCheckoutItemPayload).toList(),
      if (command.saleType.trim().isNotEmpty)
        'saleType': _normalizeSaleType(command.saleType),
      if (isManualClaimOrder) 'sourceMode': normalizedSourceMode,
    };

    try {
      final data = await _api.placeOrder(
        payload,
        idempotency: IdempotencyRequest(
          actionKey: isManualClaimOrder
              ? 'order.place.manual_external_payment_claim'
              : 'order.place.standard_open_order',
          intentId: command.clientOpId,
          payload: payload,
        ),
      );
      return SalePlaceOrderResultDto(
        openTicketId: data.orderId,
        saleId: data.saleId,
        status: data.status,
        batchId: data.batchId,
        idempotentReplay: false,
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<String> uploadManualPaymentProofImage({
    required List<int> imageBytes,
  }) async {
    try {
      return await _api.uploadManualPaymentProofImage(imageBytes: imageBytes);
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleCreateManualPaymentClaimResultDto> createManualPaymentClaim(
    SaleCreateManualPaymentClaimCommand command,
  ) async {
    final normalizedOrderId = command.orderId.trim();
    if (normalizedOrderId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Order id is required before creating a manual claim.',
      );
    }

    final normalizedProofUrl = command.proofImageUrl.trim();
    if (normalizedProofUrl.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Proof image is required before creating a manual claim.',
      );
    }

    final payload = <String, dynamic>{
      'claimedPaymentMethod': command.claimedPaymentMethod.trim().toUpperCase(),
      'saleType': _normalizeSaleType(command.saleType),
      'tenderCurrency': command.tenderCurrency.trim().toUpperCase(),
      'claimedTenderAmount': command.claimedTenderAmount,
      'proofImageUrl': normalizedProofUrl,
      if ((command.customerReference ?? '').trim().isNotEmpty)
        'customerReference': command.customerReference!.trim(),
      if ((command.note ?? '').trim().isNotEmpty) 'note': command.note!.trim(),
    };

    try {
      final data = await _api.createManualPaymentClaim(
        normalizedOrderId,
        payload,
        idempotency: IdempotencyRequest(
          actionKey: 'order.manual_payment_claim.create',
          intentId: command.clientOpId,
          payload: {'orderId': normalizedOrderId, ...payload},
        ),
      );
      return SaleCreateManualPaymentClaimResultDto(
        claimId: data.claimId,
        orderId: data.orderId.isEmpty ? normalizedOrderId : data.orderId,
        status: data.status,
        idempotentReplay: false,
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleApproveManualPaymentClaimResultDto> approveManualPaymentClaim(
    SaleApproveManualPaymentClaimCommand command,
  ) async {
    final normalizedOrderId = command.orderId.trim();
    final normalizedClaimId = command.claimId.trim();
    if (normalizedOrderId.isEmpty || normalizedClaimId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Order id and claim id are required before approval.',
      );
    }

    final payload = <String, dynamic>{
      if ((command.note ?? '').trim().isNotEmpty) 'note': command.note!.trim(),
    };

    try {
      final data = await _api.approveManualPaymentClaim(
        normalizedOrderId,
        normalizedClaimId,
        payload,
        idempotency: IdempotencyRequest(
          actionKey: 'order.manual_payment_claim.approve',
          intentId: command.clientOpId,
          payload: {
            'orderId': normalizedOrderId,
            'claimId': normalizedClaimId,
            ...payload,
          },
        ),
      );
      return SaleApproveManualPaymentClaimResultDto(
        claimId: data.claimId.isEmpty ? normalizedClaimId : data.claimId,
        orderId: data.orderId.isEmpty ? normalizedOrderId : data.orderId,
        status: data.status,
        idempotentReplay: false,
        saleId: data.saleId,
        receiptId: data.receipt?.receiptId,
        receipt: SaleMappers.toImmediateReceipt(data.receipt),
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleRejectManualPaymentClaimResultDto> rejectManualPaymentClaim(
    SaleRejectManualPaymentClaimCommand command,
  ) async {
    final normalizedOrderId = command.orderId.trim();
    final normalizedClaimId = command.claimId.trim();
    if (normalizedOrderId.isEmpty || normalizedClaimId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Order id and claim id are required before rejection.',
      );
    }

    final payload = <String, dynamic>{
      if ((command.note ?? '').trim().isNotEmpty) 'note': command.note!.trim(),
    };

    try {
      final data = await _api.rejectManualPaymentClaim(
        normalizedOrderId,
        normalizedClaimId,
        payload,
        idempotency: IdempotencyRequest(
          actionKey: 'order.manual_payment_claim.reject',
          intentId: command.clientOpId,
          payload: {
            'orderId': normalizedOrderId,
            'claimId': normalizedClaimId,
            ...payload,
          },
        ),
      );
      return SaleRejectManualPaymentClaimResultDto(
        claimId: data.claimId.isEmpty ? normalizedClaimId : data.claimId,
        orderId: data.orderId.isEmpty ? normalizedOrderId : data.orderId,
        status: data.status,
        idempotentReplay: false,
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleAddItemsToOpenTicketResultDto> addItemsToOpenTicket(
    SaleAddItemsToOpenTicketCommand command,
  ) async {
    throw UnimplementedError(
      'FE-SALE-10 will implement add-items to open ticket in API repository.',
    );
  }

  @override
  Future<SaleCheckoutOpenTicketResultDto> checkoutOpenTicket(
    SaleCheckoutOpenTicketCommand command,
  ) async {
    final normalizedOrderId = command.openTicketId.trim();
    if (normalizedOrderId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Order id is required before settling an open ticket.',
      );
    }

    try {
      final orderDetail = await _api.getOrderDetail(normalizedOrderId);
      final subtotalUsd = orderDetail.lines.fold<double>(
        0,
        (sum, line) => sum + line.lineSubtotal,
      );
      final grandTotalUsd = subtotalUsd;
      final normalizedCurrency = command.tenderCurrency.trim().toUpperCase();
      final grandTotalKhr = _estimateOrderTotalKhrFromCurrentPolicy(
        totalUsdExact: grandTotalUsd,
      );
      final payload = <String, dynamic>{
        'paymentMethod': command.paymentMethod.trim().toUpperCase(),
        'tenderCurrency': normalizedCurrency,
        'tenderAmount': normalizedCurrency == 'KHR'
            ? grandTotalKhr
            : grandTotalUsd,
        'subtotalUsd': subtotalUsd,
        'discountUsd': 0,
        'vatUsd': 0,
        'grandTotalUsd': grandTotalUsd,
        if (_currentSaleFxRate() > 0)
          'saleFxRateKhrPerUsd': _currentSaleFxRate(),
      };
      final cashReceivedTenderAmount = _cashReceivedTenderAmount(
        tenderCurrency: normalizedCurrency,
        cashReceived: command.cashReceived,
      );
      if (cashReceivedTenderAmount != null) {
        payload['cashReceivedTenderAmount'] = cashReceivedTenderAmount;
      }

      final data = await _api.checkoutOrder(
        normalizedOrderId,
        payload,
        idempotency: IdempotencyRequest(
          actionKey: 'order.checkout',
          intentId: command.clientOpId,
          payload: {'orderId': normalizedOrderId, ...payload},
        ),
      );

      return SaleCheckoutOpenTicketResultDto(
        openTicketId: normalizedOrderId,
        saleId: data.sale.id,
        status: _mapOrderTicketStatus(
          orderStatus:
              data.order?.status ??
              (((data.sale.orderId ?? '').isNotEmpty) ? 'CHECKED_OUT' : 'OPEN'),
          isCheckedOutLike:
              (data.sale.orderId ?? '').isNotEmpty ||
              (data.order?.status ?? '').trim().toUpperCase() == 'CHECKED_OUT',
        ),
        idempotentReplay: false,
        receiptId: data.receipt?.receiptId,
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleCancelOpenTicketResultDto> cancelOpenTicket(
    SaleCancelOpenTicketCommand command,
  ) async {
    throw UnimplementedError(
      'FE-SALE-12 will implement cancel open ticket in API repository.',
    );
  }

  @override
  Future<SaleOrdersPageDto> getOrders(SaleOrdersQueryDto query) async {
    final offset = max(0, (query.page - 1) * query.limit);
    final orderPage = await _api.listOrders(
      status: _mapOrderListStatusQuery(query.status),
      view: _mapOrderListViewQuery(query.view),
      from: query.from,
      to: query.to,
      limit: query.limit,
      offset: offset,
    );
    final items = orderPage.items
        .map((item) {
          final isCheckedOutLike = _isEffectivelyCheckedOutOrder(
            orderStatus: item.status,
            sourceMode: item.sourceMode,
            checkedOutAt: item.checkedOutAt,
            paymentMethod: item.paymentMethod,
          );
          return SaleOrderSummaryDto(
            saleId: item.saleId,
            orderId: item.orderId,
            sourceMode: item.sourceMode,
            openedByAccountId: item.openedByAccountId,
            saleStatus: item.saleStatus,
            ticketStatus: _mapOrderTicketStatus(
              orderStatus: item.status,
              isCheckedOutLike: isCheckedOutLike,
            ),
            fulfillmentStatus: _mapListedOrderFulfillmentStatus(
              orderStatus: item.status,
              listedFulfillmentStatus: item.fulfillmentStatus,
              isCheckedOutLike: isCheckedOutLike,
            ),
            totalUsdExact: item.totalUsdExact,
            totalKhrExact: _estimateOrderTotalKhrFromCurrentPolicy(
              totalUsdExact: item.totalUsdExact,
            ),
            placedAt: item.createdAt,
            linesPreview: item.linesPreview
                .map(
                  (line) => SaleOrderLinePreviewDto(
                    name: line.menuItemNameSnapshot,
                    quantity: line.quantity,
                    modifierLabels: line.modifierLabels,
                  ),
                )
                .toList(growable: false),
            openedByDisplayName: item.openedByDisplayName,
            checkedOutAt: item.checkedOutAt,
            paymentMethod: item.paymentMethod,
            manualPaymentClaimId: item.manualPaymentClaimId,
            manualPaymentClaimStatus: item.manualPaymentClaimStatus,
            manualPaymentClaimRequestedByAccountId:
                item.manualPaymentClaimRequestedByAccountId,
            manualPaymentClaimRequestedByDisplayName:
                item.manualPaymentClaimRequestedByDisplayName,
            manualPaymentClaimRequestedAt: item.manualPaymentClaimRequestedAt,
          );
        })
        .toList(growable: false);
    return SaleOrdersPageDto(
      items: items,
      page: query.page,
      limit: orderPage.limit == 0 ? query.limit : orderPage.limit,
      total: orderPage.total,
    );
  }

  @override
  Future<SaleOpenTicketDetailDto> getOpenTicketDetail({
    required String orderId,
  }) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Order id is required before loading ticket detail.',
      );
    }

    try {
      final data = await _api.getOrderDetail(normalizedOrderId);
      final payableUsdExact = data.lines.fold<double>(
        0,
        (sum, line) => sum + line.lineSubtotal,
      );
      return SaleOpenTicketDetailDto(
        openTicketId: data.orderId,
        orderId: data.orderId,
        status: _mapOrderTicketStatus(
          orderStatus: data.status,
          isCheckedOutLike: _isEffectivelyCheckedOutOrder(
            orderStatus: data.status,
            sourceMode: data.sourceMode,
            checkedOutAt: data.checkedOutAt,
            paymentMethod: null,
          ),
        ),
        batches: const <SaleOpenTicketBatchDto>[],
        lineCount: data.lines.length,
        payableUsdExact: payableUsdExact,
        payableKhrExact: _estimateOrderTotalKhrFromCurrentPolicy(
          totalUsdExact: payableUsdExact,
        ),
        saleId: data.saleId,
        saleStatus: data.saleStatus,
        paymentMethod: data.paymentMethod,
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleOrderDetailReadResultDto> getOrderDetail({
    required String orderId,
  }) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Order id is required before loading order detail.',
      );
    }

    try {
      final data = await _api.getOrderDetail(normalizedOrderId);
      return SaleOrderDetailReadResultDto(
        orderId: data.orderId,
        tenantId: data.tenantId,
        branchId: data.branchId,
        openedByAccountId: data.openedByAccountId,
        status: data.status,
        sourceMode: data.sourceMode,
        saleId: data.saleId,
        saleStatus: data.saleStatus,
        paymentMethod: data.paymentMethod,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        checkedOutAt: data.checkedOutAt,
        checkedOutByAccountId: data.checkedOutByAccountId,
        cancelledAt: data.cancelledAt,
        cancelledByAccountId: data.cancelledByAccountId,
        cancelReason: data.cancelReason,
        manualPaymentClaims: data.manualPaymentClaims
            .map(
              (claim) => SaleManualPaymentClaimDetailDto(
                claimId: claim.claimId,
                orderId: claim.orderId,
                status: claim.status,
                claimedPaymentMethod: claim.claimedPaymentMethod,
                tenderCurrency: claim.tenderCurrency,
                claimedTenderAmount: claim.claimedTenderAmount,
                proofImageUrl: claim.proofImageUrl,
                customerReference: claim.customerReference,
                note: claim.note,
              ),
            )
            .toList(growable: false),
      );
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SaleReceiptDto> getReceipt({required String saleId}) async {
    final normalizedSaleId = saleId.trim();
    if (normalizedSaleId.isEmpty) {
      throw const SaleCheckoutRepositoryException(
        reasonCode: SaleCheckoutReasonCodes.invalidRequest,
        message: 'Receipt identifier is missing for this sale.',
      );
    }
    try {
      final data = await _api.getReceiptBySaleId(normalizedSaleId);
      return SaleMappers.toCanonicalReceipt(data);
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  bool _modifiersMatch(
    List<SaleModifierDto> modifiers,
    Map<String, List<String>> selectedOptionIds,
  ) {
    if (selectedOptionIds.isEmpty) return true;
    final normalizedSelected = {
      for (final entry in selectedOptionIds.entries)
        entry.key: [...entry.value]..sort(),
    };
    for (final mod in modifiers) {
      final groupId = mod.groupId;
      if (groupId.isEmpty) continue;
      final selected = normalizedSelected[groupId];
      if (selected == null) continue;
      final optIds = [...mod.optionIds]..sort();
      if (!_listsEqual(selected, optIds)) return false;
    }
    return true;
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  SaleCheckoutPreviewDto _estimateCheckoutPreview({
    required String saleId,
    required String paymentMethod,
    required List<SaleCartLineInputDto> cartLines,
    required String tenderCurrency,
    required SaleCashReceivedInputDto? cashReceived,
  }) {
    final subtotalUsd = cartLines.fold<double>(
      0,
      (sum, line) => sum + _lineTotalUsd(line),
    );
    final subtotalKhr = subtotalUsd * 4100;
    final totalUsd = subtotalUsd;
    final totalKhr = subtotalKhr;
    final normalizedCurrency = tenderCurrency.toUpperCase();
    final cashReceivedUsd =
        (normalizedCurrency == 'USD' ? cashReceived?.usd : null)?.toDouble() ??
        0;
    final cashReceivedKhr =
        (normalizedCurrency == 'KHR' ? cashReceived?.khr : null)?.toDouble() ??
        0;
    return SaleCheckoutPreviewDto(
      saleId: saleId,
      tenderCurrency: normalizedCurrency.toLowerCase(),
      paymentMethod: paymentMethod,
      subtotalUsdExact: subtotalUsd,
      subtotalKhrExact: subtotalKhr,
      totalUsdExact: totalUsd,
      totalKhrExact: totalKhr,
      cashReceivedUsd: cashReceivedUsd,
      cashReceivedKhr: cashReceivedKhr,
      changeGivenUsd: normalizedCurrency == 'USD'
          ? max<double>(0, cashReceivedUsd - totalUsd)
          : 0,
      changeGivenKhr: normalizedCurrency == 'KHR'
          ? max<double>(0, cashReceivedKhr - totalKhr)
          : 0,
    );
  }

  Map<String, dynamic> _toCheckoutItemPayload(SaleCartLineInputDto line) {
    final modifierSelections = _normalizeModifierSelections(line.modifiers);
    return {
      'menuItemId': line.menuItemId,
      'quantity': line.quantity,
      if (modifierSelections.isNotEmpty)
        'modifierSelections': modifierSelections,
    };
  }

  List<Map<String, dynamic>> _normalizeModifierSelections(
    List<SaleCartModifierInputDto> modifiers,
  ) {
    final groupedOptionIds = <String, Set<String>>{};

    for (final modifier in modifiers) {
      final groupId = modifier.groupId.trim();
      if (groupId.isEmpty) continue;

      final optionIds = modifier.optionIds
          .map((optionId) => optionId.trim())
          .where((optionId) => optionId.isNotEmpty)
          .toSet();
      if (optionIds.isEmpty) continue;

      groupedOptionIds.putIfAbsent(groupId, () => <String>{}).addAll(optionIds);
    }

    final entries = groupedOptionIds.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .map((entry) {
          final optionIds = entry.value.toList()..sort();
          return <String, dynamic>{
            'groupId': entry.key,
            'optionIds': optionIds,
          };
        })
        .toList(growable: false);
  }

  String _normalizeSaleType(String saleType) {
    switch (saleType.trim().toLowerCase()) {
      case 'dine_in':
        return 'DINE_IN';
      case 'delivery':
        return 'DELIVERY';
      case 'take_away':
      case 'takeaway':
      default:
        return 'TAKEAWAY';
    }
  }

  num? _cashReceivedTenderAmount({
    required String tenderCurrency,
    required SaleCashReceivedInputDto? cashReceived,
  }) {
    if (cashReceived == null) return null;
    return tenderCurrency == 'KHR' ? cashReceived.khr : cashReceived.usd;
  }

  double _currentSaleFxRate() {
    final fxRate = _policyStateReader().branchPolicy.saleFxRateKhrPerUsd;
    return fxRate > 0 ? fxRate : 0;
  }

  double _lineTotalUsd(SaleCartLineInputDto line) {
    final explicit = line.lineTotalUsdExact?.toDouble();
    if (explicit != null && explicit > 0) return explicit;
    final unit = line.unitPriceUsd?.toDouble() ?? 0;
    return unit * line.quantity;
  }

  String _readString(dynamic value) => value?.toString().trim() ?? '';

  SaleCheckoutRepositoryException _toSaleRepoException(
    ApiClientException error,
  ) {
    return SaleCheckoutRepositoryException(
      reasonCode:
          SaleCheckoutReasonCodes.normalize(error.code) ??
          SaleCheckoutReasonCodes.unknownError,
      message: error.message,
    );
  }

  BranchListItem? _findBranch(String branchId) {
    for (final branch in _branchStateReader().branches) {
      if (branch.branchId.trim() == branchId) {
        return branch;
      }
    }
    return null;
  }

  UserBranch? _findAuthBranch(String branchId) {
    final session = _loginStateReader().session;
    final branches = session?.user.branches ?? const <UserBranch>[];
    for (final branch in branches) {
      final normalizedId = branch.branchId.trim().isNotEmpty
          ? branch.branchId.trim()
          : branch.id.trim();
      if (normalizedId == branchId) {
        return branch;
      }
    }
    return null;
  }

  bool _hasOpenCashSessionForBranch(String branchId) {
    final session = _cashSessionStateReader().session;
    if (session == null || session.id.trim().isEmpty) return false;
    if (session.branchId.trim() != branchId) return false;
    return CashSessionStatuses.normalize(session.status) ==
        CashSessionStatuses.open;
  }

  bool _policyAllowsPayLater(String branchId) {
    final policy = _policyStateReader().branchPolicy;
    if (policy.branchId.trim().isEmpty) return false;
    if (policy.branchId.trim() != branchId) return false;
    return policy.saleAllowPayLater;
  }

  String? _mapOrderListStatusQuery(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'open':
      case 'pending':
        return 'OPEN';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return null;
    }
  }

  String? _mapOrderListViewQuery(String? view) {
    final normalized = (view ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  bool _isEffectivelyCheckedOutOrder({
    required String orderStatus,
    required String sourceMode,
    required DateTime? checkedOutAt,
    required String? paymentMethod,
  }) {
    final normalizedOrderStatus = orderStatus.trim().toUpperCase();
    if (normalizedOrderStatus == 'CHECKED_OUT') return true;

    final normalizedSourceMode = sourceMode.trim().toUpperCase();
    if (normalizedSourceMode == 'DIRECT_CHECKOUT') return true;

    if (checkedOutAt != null) return true;

    final normalizedPaymentMethod = (paymentMethod ?? '').trim().toUpperCase();
    if (normalizedPaymentMethod.isNotEmpty &&
        normalizedPaymentMethod != 'UNPAID') {
      return true;
    }

    return false;
  }

  String _mapOrderTicketStatus({
    required String orderStatus,
    required bool isCheckedOutLike,
  }) {
    switch (orderStatus.trim().toUpperCase()) {
      case 'OPEN':
        return isCheckedOutLike ? 'PAID' : 'UNPAID';
      case 'CANCELLED':
        return 'CANCELLED';
      default:
        return 'PAID';
    }
  }

  String _mapListedOrderFulfillmentStatus({
    required String orderStatus,
    required String? listedFulfillmentStatus,
    required bool isCheckedOutLike,
  }) {
    final normalizedListStatus = (listedFulfillmentStatus ?? '')
        .trim()
        .toUpperCase();
    switch (normalizedListStatus) {
      case 'PENDING':
        return 'pending';
      case 'PREPARING':
        return 'in_prep';
      case 'READY':
        return 'ready';
      case 'DELIVERED':
        return 'delivered';
      case 'CANCELLED':
        return 'cancelled';
    }

    switch (orderStatus.trim().toUpperCase()) {
      case 'OPEN':
        return 'pending';
      case 'CANCELLED':
        return 'cancelled';
      case 'CHECKED_OUT':
        return 'pending';
      default:
        return isCheckedOutLike ? 'pending' : 'in_prep';
    }
  }

  double _estimateOrderTotalKhrFromCurrentPolicy({
    required double totalUsdExact,
  }) {
    final policy = _policyStateReader().branchPolicy;
    if (policy.saleFxRateKhrPerUsd <= 0) return 0;
    final rawKhr = totalUsdExact * policy.saleFxRateKhrPerUsd;
    if (!policy.saleKhrRoundingEnabled) return rawKhr;

    final granularity = BranchPolicyRoundingGranularities.asAmount(
      policy.saleKhrRoundingGranularity,
    );
    if (granularity <= 0) return rawKhr;

    switch (BranchPolicyRoundingModes.normalize(policy.saleKhrRoundingMode)) {
      case BranchPolicyRoundingModes.up:
        return (rawKhr / granularity).ceilToDouble() * granularity;
      case BranchPolicyRoundingModes.down:
        return (rawKhr / granularity).floorToDouble() * granularity;
      case BranchPolicyRoundingModes.nearest:
        return (rawKhr / granularity).roundToDouble() * granularity;
      default:
        return rawKhr;
    }
  }
}

LoginState _defaultLoginStateReader() => const LoginState();

BranchState _defaultBranchStateReader() => const BranchState();

CashSessionState _defaultCashSessionStateReader() => const CashSessionState();

PolicyState _defaultPolicyStateReader() => const PolicyState();

String _randomUuid() {
  final rand = Random();
  String fourHex() => rand.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
  // Ensure correct UUID v4 structure.
  final part1 = '${fourHex()}${fourHex()}';
  final part2 = fourHex();
  final part3 = (int.parse(fourHex(), radix: 16) & 0x0fff | 0x4000)
      .toRadixString(16)
      .padLeft(4, '0'); // version 4
  final part4 = (int.parse(fourHex(), radix: 16) & 0x3fff | 0x8000)
      .toRadixString(16)
      .padLeft(4, '0'); // variant
  final part5 = '${fourHex()}${fourHex()}${fourHex()}';
  return '$part1-$part2-$part3-$part4-$part5';
}
