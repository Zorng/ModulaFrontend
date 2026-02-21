import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_khqr_states.dart';

class CartLine {
  const CartLine({
    required this.item,
    required this.quantity,
    required this.selectedOptionIds,
    this.saleItemId,
    this.selectedOptions = const {},
  });

  final MenuItem item;
  final int quantity;
  final Map<String, List<String>> selectedOptionIds;
  final String? saleItemId;
  final Map<String, List<ModifierOption>> selectedOptions;

  CartLine copyWith({
    MenuItem? item,
    int? quantity,
    Map<String, List<String>>? selectedOptionIds,
    String? saleItemId,
    Map<String, List<ModifierOption>>? selectedOptions,
  }) {
    return CartLine(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      saleItemId: saleItemId ?? this.saleItemId,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item.toJson(),
      'quantity': quantity,
      'selectedOptionIds': selectedOptionIds,
      'saleItemId': saleItemId,
      // Note: selectedOptions is not persisted as it can be rebuilt from selectedOptionIds
    };
  }

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      item: MenuItem.fromJson(json['item'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      selectedOptionIds: (json['selectedOptionIds'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, List<String>.from(value as List))),
      saleItemId: json['saleItemId'] as String?,
      selectedOptions: const {}, // Will be rebuilt when needed
    );
  }
}

class SaleCartState {
  static const _unset = Object();

  const SaleCartState({
    this.saleId,
    this.saleType = 'take_away',
    this.lines = const [],
    this.tenderCurrency = 'USD',
    this.paymentMethod = 'cash',
    this.cashUsd = 0,
    this.cashKhr = 0,
    this.isFinalizing = false,
    this.checkoutErrorMessage,
    this.lastFinalizedSaleId,
    this.lastReceiptId,
    this.khqrStatus = SaleKhqrUiStates.readyToGenerate,
    this.khqrAttemptId,
    this.khqrMd5,
    this.khqrQrPayload,
    this.khqrExpiresAt,
    this.khqrConfirmedAt,
    this.khqrErrorMessage,
    this.isKhqrLoading = false,
  });

  final String? saleId;
  final String saleType;
  final List<CartLine> lines;
  final String tenderCurrency;
  final String paymentMethod;
  final double cashUsd;
  final double cashKhr;
  final bool isFinalizing;
  final String? checkoutErrorMessage;
  final String? lastFinalizedSaleId;
  final String? lastReceiptId;
  final String khqrStatus;
  final String? khqrAttemptId;
  final String? khqrMd5;
  final String? khqrQrPayload;
  final DateTime? khqrExpiresAt;
  final DateTime? khqrConfirmedAt;
  final String? khqrErrorMessage;
  final bool isKhqrLoading;

  SaleCartState copyWith({
    String? saleId,
    String? saleType,
    List<CartLine>? lines,
    String? tenderCurrency,
    String? paymentMethod,
    double? cashUsd,
    double? cashKhr,
    bool? isFinalizing,
    Object? checkoutErrorMessage = _unset,
    Object? lastFinalizedSaleId = _unset,
    Object? lastReceiptId = _unset,
    String? khqrStatus,
    Object? khqrAttemptId = _unset,
    Object? khqrMd5 = _unset,
    Object? khqrQrPayload = _unset,
    Object? khqrExpiresAt = _unset,
    Object? khqrConfirmedAt = _unset,
    Object? khqrErrorMessage = _unset,
    bool? isKhqrLoading,
  }) {
    return SaleCartState(
      saleId: saleId ?? this.saleId,
      saleType: saleType ?? this.saleType,
      lines: lines ?? this.lines,
      tenderCurrency: tenderCurrency ?? this.tenderCurrency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashUsd: cashUsd ?? this.cashUsd,
      cashKhr: cashKhr ?? this.cashKhr,
      isFinalizing: isFinalizing ?? this.isFinalizing,
      checkoutErrorMessage: checkoutErrorMessage == _unset
          ? this.checkoutErrorMessage
          : checkoutErrorMessage as String?,
      lastFinalizedSaleId: lastFinalizedSaleId == _unset
          ? this.lastFinalizedSaleId
          : lastFinalizedSaleId as String?,
      lastReceiptId: lastReceiptId == _unset
          ? this.lastReceiptId
          : lastReceiptId as String?,
      khqrStatus: khqrStatus ?? this.khqrStatus,
      khqrAttemptId: khqrAttemptId == _unset
          ? this.khqrAttemptId
          : khqrAttemptId as String?,
      khqrMd5: khqrMd5 == _unset ? this.khqrMd5 : khqrMd5 as String?,
      khqrQrPayload: khqrQrPayload == _unset
          ? this.khqrQrPayload
          : khqrQrPayload as String?,
      khqrExpiresAt: khqrExpiresAt == _unset
          ? this.khqrExpiresAt
          : khqrExpiresAt as DateTime?,
      khqrConfirmedAt: khqrConfirmedAt == _unset
          ? this.khqrConfirmedAt
          : khqrConfirmedAt as DateTime?,
      khqrErrorMessage: khqrErrorMessage == _unset
          ? this.khqrErrorMessage
          : khqrErrorMessage as String?,
      isKhqrLoading: isKhqrLoading ?? this.isKhqrLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'saleType': saleType,
      'lines': lines.map((line) => line.toJson()).toList(),
      'tenderCurrency': tenderCurrency,
      'paymentMethod': paymentMethod,
      'cashUsd': cashUsd,
      'cashKhr': cashKhr,
      'khqrStatus': khqrStatus,
      'khqrAttemptId': khqrAttemptId,
      'khqrMd5': khqrMd5,
      'khqrQrPayload': khqrQrPayload,
      'khqrExpiresAt': khqrExpiresAt?.toIso8601String(),
      'khqrConfirmedAt': khqrConfirmedAt?.toIso8601String(),
    };
  }

  factory SaleCartState.fromJson(Map<String, dynamic> json) {
    return SaleCartState(
      saleId: json['saleId'] as String?,
      saleType: json['saleType'] as String? ?? 'take_away',
      lines:
          (json['lines'] as List<dynamic>?)
              ?.map((e) => CartLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tenderCurrency: json['tenderCurrency'] as String? ?? 'USD',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      cashUsd: (json['cashUsd'] as num?)?.toDouble() ?? 0,
      cashKhr: (json['cashKhr'] as num?)?.toDouble() ?? 0,
      isFinalizing: false,
      checkoutErrorMessage: null,
      lastFinalizedSaleId: null,
      lastReceiptId: null,
      khqrStatus: SaleKhqrUiStates.normalize(
        json['khqrStatus'] as String? ?? SaleKhqrUiStates.readyToGenerate,
      ),
      khqrAttemptId: json['khqrAttemptId'] as String?,
      khqrMd5: json['khqrMd5'] as String?,
      khqrQrPayload: json['khqrQrPayload'] as String?,
      khqrExpiresAt: json['khqrExpiresAt'] == null
          ? null
          : DateTime.tryParse(json['khqrExpiresAt'] as String),
      khqrConfirmedAt: json['khqrConfirmedAt'] == null
          ? null
          : DateTime.tryParse(json['khqrConfirmedAt'] as String),
      khqrErrorMessage: null,
      isKhqrLoading: false,
    );
  }
}
