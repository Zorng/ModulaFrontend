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
    required String saleId,
    required String status,
  }) async {
    await _api.updateFulfillmentStatus(saleId, status: status);
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

      final paidAmount = _estimatePaidAmount(
        cartLines: command.cartLines,
        tenderCurrency: command.tenderCurrency,
      );
      final finalizePayload = <String, dynamic>{
        'paidAmount': paidAmount,
        if (command.khqrMd5 != null && command.khqrMd5!.isNotEmpty)
          'khqrMd5': command.khqrMd5,
      };
      final normalizedSaleId = command.saleId.trim();
      if (normalizedSaleId.isEmpty) {
        final md5 = _readString(command.khqrMd5);
        if (md5.isEmpty) {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
            message: 'KHQR proof is missing. Generate KHQR again.',
          );
        }
        final data = await _api.confirmKhqrPayment(
          md5,
          idempotency: IdempotencyRequest(
            actionKey: 'payment.khqr.confirm',
            intentId: command.clientOpId,
            payload: {'md5': md5},
          ),
        );
        if (!data.saleFinalized || data.sale == null) {
          throw const SaleCheckoutRepositoryException(
            reasonCode: SaleCheckoutReasonCodes.khqrNotConfirmed,
            message: 'KHQR payment is not confirmed yet.',
          );
        }
        final preview = _estimateCheckoutPreview(
          saleId: data.sale!.saleId,
          paymentMethod: 'khqr',
          cartLines: command.cartLines,
          tenderCurrency: command.tenderCurrency,
          cashReceived: null,
        );
        return SaleFinalizeSaleResultDto(
          saleId: data.sale!.saleId,
          status: SaleMappers.normalizeSaleState(data.sale!.status),
          totalUsdExact: preview.totalUsdExact,
          totalKhrExact: preview.totalKhrExact,
          idempotentReplay: false,
          receiptId: data.receipt?.receiptId,
          receipt: SaleMappers.toImmediateReceipt(data.receipt),
        );
      }
      final data = await _api.finalizeSaleContract(
        normalizedSaleId,
        finalizePayload,
        idempotency: IdempotencyRequest(
          actionKey: 'sale.finalize',
          intentId: command.clientOpId,
          payload: {'saleId': normalizedSaleId, ...finalizePayload},
        ),
      );
      return SaleMappers.toFinalizeResultFromFinalizeResponse(data);
    } on ApiClientException catch (error) {
      throw _toSaleRepoException(error);
    }
  }

  @override
  Future<SalePlaceOrderResultDto> placeOrder(
    SalePlaceOrderCommand command,
  ) async {
    throw UnimplementedError(
      'FE-SALE-09 will implement pay-later place order in API repository.',
    );
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
    throw UnimplementedError(
      'FE-SALE-11 will implement checkout open ticket in API repository.',
    );
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
    final sales = await listSales(
      status: query.status,
      startDate: query.from,
      endDate: query.to,
      page: query.page,
      limit: query.limit,
    );
    final items = sales
        .map(
          (sale) => SaleOrderSummaryDto(
            saleId: sale.id,
            orderId: sale.id,
            ticketStatus: sale.state,
            fulfillmentStatus: sale.fulfillmentStatus,
            totalUsdExact: sale.totalUsdExact,
            totalKhrExact: sale.totalKhrExact,
            placedAt: sale.createdAt,
          ),
        )
        .toList();
    return SaleOrdersPageDto(
      items: items,
      page: query.page,
      limit: query.limit,
      total: items.length,
    );
  }

  @override
  Future<SaleOpenTicketDetailDto> getOpenTicketDetail({
    required String saleId,
  }) async {
    throw UnimplementedError(
      'FE-SALE-13 will implement open ticket detail in API repository.',
    );
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
    final modifiers = _normalizeModifierSelections(line.modifiers);
    return {
      'menuItemId': line.menuItemId,
      'quantity': line.quantity,
      // Live checkout implementation still consumes `modifiers` here.
      if (modifiers.isNotEmpty) 'modifiers': modifiers,
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

  double _estimatePaidAmount({
    required List<SaleCartLineInputDto> cartLines,
    required String tenderCurrency,
  }) {
    final totalUsd = cartLines.fold<double>(
      0,
      (sum, line) => sum + _lineTotalUsd(line),
    );
    if (tenderCurrency.toUpperCase() == 'KHR') {
      return totalUsd * 4100;
    }
    return totalUsd;
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
