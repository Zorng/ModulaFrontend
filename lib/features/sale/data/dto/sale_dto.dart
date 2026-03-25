import 'package:modular_pos/features/sale/data/sale_checkout_repository_contract.dart';

class SaleDraftDto {
  const SaleDraftDto({
    required this.id,
    required this.tenderCurrency,
    required this.paymentMethod,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.changeGivenUsd,
    required this.changeGivenKhr,
    required this.items,
  });

  final String id;
  final String tenderCurrency;
  final String paymentMethod;
  final double totalUsdExact;
  final double totalKhrExact;
  final double? cashReceivedUsd;
  final double? cashReceivedKhr;
  final double? changeGivenUsd;
  final double? changeGivenKhr;
  final List<SaleItemDto> items;

  factory SaleDraftDto.fromJson(Map<String, dynamic> json) {
    final tenderCurrency = _readString(json['tenderCurrency']);
    final cashReceivedTenderAmount = _readNullableDouble(
      json['cashReceivedTenderAmount'],
    );
    final cashChangeTenderAmount = _readNullableDouble(
      json['cashChangeTenderAmount'],
    );

    return SaleDraftDto(
      id: _readString(json['id']),
      tenderCurrency: tenderCurrency,
      paymentMethod: _readString(json['paymentMethod']),
      totalUsdExact: _readDouble(
        json['totalUsdExact'] ?? json['grandTotalUsd'],
      ),
      totalKhrExact: _readDouble(
        json['totalKhrExact'] ?? json['grandTotalKhr'],
      ),
      cashReceivedUsd:
          _readNullableDouble(json['cashReceivedUsd']) ??
          (tenderCurrency.toUpperCase() == 'USD'
              ? cashReceivedTenderAmount
              : null),
      cashReceivedKhr:
          _readNullableDouble(json['cashReceivedKhr']) ??
          (tenderCurrency.toUpperCase() == 'KHR'
              ? cashReceivedTenderAmount
              : null),
      changeGivenUsd:
          _readNullableDouble(json['changeGivenUsd']) ??
          (tenderCurrency.toUpperCase() == 'USD'
              ? cashChangeTenderAmount
              : null),
      changeGivenKhr:
          _readNullableDouble(json['changeGivenKhr']) ??
          (tenderCurrency.toUpperCase() == 'KHR'
              ? cashChangeTenderAmount
              : null),
      items: _readSaleItems(json, preferItems: true),
    );
  }
}

class SaleDto {
  const SaleDto({
    required this.id,
    required this.clientUuid,
    required this.tenantId,
    required this.branchId,
    required this.employeeId,
    this.orderId,
    required this.saleType,
    required this.state,
    required this.fxRateUsed,
    required this.tenderCurrency,
    required this.paymentMethod,
    required this.fulfillmentStatus,
    required this.subtotalUsdExact,
    required this.subtotalKhrExact,
    required this.discountUsdExact,
    required this.discountKhrExact,
    required this.taxUsdExact,
    required this.taxKhrExact,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.changeGivenUsd,
    required this.changeGivenKhr,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.finalizedAt,
    this.voidedAt,
    this.voidReason,
  });

  final String id;
  final String clientUuid;
  final String tenantId;
  final String branchId;
  final String employeeId;
  final String? orderId;
  final String saleType;
  final String state;
  final double fxRateUsed;
  final String tenderCurrency;
  final String paymentMethod;
  final String fulfillmentStatus;
  final double subtotalUsdExact;
  final double subtotalKhrExact;
  final double discountUsdExact;
  final double discountKhrExact;
  final double taxUsdExact;
  final double taxKhrExact;
  final double totalUsdExact;
  final double totalKhrExact;
  final double? cashReceivedUsd;
  final double? cashReceivedKhr;
  final double? changeGivenUsd;
  final double? changeGivenKhr;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItemDto> items;
  final DateTime? finalizedAt;
  final DateTime? voidedAt;
  final String? voidReason;

  factory SaleDto.fromJson(Map<String, dynamic> json) {
    final tenderCurrency = _readString(json['tenderCurrency']);
    final cashReceivedTenderAmount = _readNullableDouble(
      json['cashReceivedTenderAmount'],
    );
    final cashChangeTenderAmount = _readNullableDouble(
      json['cashChangeTenderAmount'],
    );

    return SaleDto(
      id: _readString(json['id']),
      clientUuid: _readString(json['clientUuid']),
      tenantId: _readString(json['tenantId']),
      branchId: _readString(json['branchId']),
      employeeId: _readString(
        json['employeeId'] ??
            json['openedByAccountId'] ??
            json['checkedOutByAccountId'],
      ),
      orderId: _readNullableString(json['orderId']),
      saleType: _readString(json['saleType']),
      state: _readString(json['state']).isEmpty
          ? _readString(json['status'])
          : _readString(json['state']),
      fxRateUsed: _readDouble(
        json['fxRateUsed'] ?? json['saleFxRateKhrPerUsd'],
      ),
      tenderCurrency: tenderCurrency,
      paymentMethod: _readString(json['paymentMethod']),
      fulfillmentStatus: _readString(json['fulfillmentStatus']),
      subtotalUsdExact: _readDouble(
        json['subtotalUsdExact'] ?? json['subtotalUsd'],
      ),
      subtotalKhrExact: _readDouble(
        json['subtotalKhrExact'] ?? json['subtotalKhr'],
      ),
      discountUsdExact: _readDouble(
        json['discountUsdExact'] ?? json['discountUsd'] ?? 0,
      ),
      discountKhrExact: _readDouble(
        json['discountKhrExact'] ?? json['discountKhr'] ?? 0,
      ),
      taxUsdExact: _readDouble(json['vatUsdExact'] ?? json['vatUsd'] ?? 0),
      taxKhrExact: _readDouble(json['vatKhrExact'] ?? json['vatKhr'] ?? 0),
      totalUsdExact: _readDouble(
        json['totalUsdExact'] ?? json['grandTotalUsd'],
      ),
      totalKhrExact: _readDouble(
        json['totalKhrExact'] ?? json['grandTotalKhr'],
      ),
      cashReceivedUsd:
          _readNullableDouble(json['cashReceivedUsd']) ??
          (tenderCurrency.toUpperCase() == 'USD'
              ? cashReceivedTenderAmount
              : null),
      cashReceivedKhr:
          _readNullableDouble(json['cashReceivedKhr']) ??
          (tenderCurrency.toUpperCase() == 'KHR'
              ? cashReceivedTenderAmount
              : null),
      changeGivenUsd:
          _readNullableDouble(json['changeGivenUsd']) ??
          (tenderCurrency.toUpperCase() == 'USD'
              ? cashChangeTenderAmount
              : null),
      changeGivenKhr:
          _readNullableDouble(json['changeGivenKhr']) ??
          (tenderCurrency.toUpperCase() == 'KHR'
              ? cashChangeTenderAmount
              : null),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      items: _readSaleItems(json),
      finalizedAt: _readNullableDateTime(json['finalizedAt']),
      voidedAt: _readNullableDateTime(json['voidedAt']),
      voidReason: _readNullableString(json['voidReason']),
    );
  }
}

class SaleItemDto {
  const SaleItemDto({
    required this.id,
    required this.saleId,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.modifiers,
  });

  final String id;
  final String saleId;
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final List<SaleModifierDto> modifiers;

  factory SaleItemDto.fromJson(Map<String, dynamic> json) {
    final modifiers = <SaleModifierDto>[];
    final rawMods = json['modifiers'] ?? json['modifierSnapshot'];
    if (rawMods is List) {
      for (final mod in rawMods) {
        if (mod is Map<String, dynamic>) {
          modifiers.add(SaleModifierDto.fromJson(mod));
        }
      }
    }
    return SaleItemDto(
      id: _readString(json['id']),
      saleId: _readString(json['saleId'] ?? json['orderId']),
      menuItemId: _readString(json['menuItemId']),
      menuItemName: _readString(
        json['menuItemName'] ?? json['menuItemNameSnapshot'],
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      modifiers: modifiers,
    );
  }
}

class SaleModifierDto {
  const SaleModifierDto({
    required this.groupId,
    required this.optionIds,
    required this.options,
  });

  final String groupId;
  final List<String> optionIds;
  final List<SaleModifierOptionDto> options;

  factory SaleModifierDto.fromJson(Map<String, dynamic> json) {
    final rawOptionIds = json['optionIds'];
    final optionIds = <String>[];
    if (rawOptionIds is List) {
      for (final id in rawOptionIds) {
        optionIds.add(id.toString());
      }
    }

    final options = <SaleModifierOptionDto>[];
    final rawOptions = json['options'];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        if (opt is Map<String, dynamic>) {
          options.add(SaleModifierOptionDto.fromJson(opt));
        }
      }
    }

    return SaleModifierDto(
      groupId: _readString(json['groupId']),
      optionIds: optionIds,
      options: options,
    );
  }
}

class SaleModifierOptionDto {
  const SaleModifierOptionDto({required this.id, required this.label});

  final String id;
  final String label;

  factory SaleModifierOptionDto.fromJson(Map<String, dynamic> json) {
    return SaleModifierOptionDto(
      id: _readString(json['id']),
      label: _readString(json['label'] ?? json['name']),
    );
  }
}

class SaleReceiptProjectionDto {
  const SaleReceiptProjectionDto({
    required this.receiptId,
    required this.saleId,
    required this.statusDisplay,
    required this.issuedAt,
  });

  final String receiptId;
  final String saleId;
  final String statusDisplay;
  final DateTime issuedAt;

  factory SaleReceiptProjectionDto.fromJson(Map<String, dynamic> json) {
    return SaleReceiptProjectionDto(
      receiptId: _readString(json['receiptId']),
      saleId: _readString(json['saleId']),
      statusDisplay: _readString(json['statusDisplay']),
      issuedAt: _readDateTime(json['issuedAt']),
    );
  }
}

class SaleReceiptReadDto {
  const SaleReceiptReadDto({
    required this.receiptId,
    required this.saleId,
    required this.receiptNumber,
    required this.statusDisplay,
    required this.issuedAt,
    required this.saleSnapshot,
    required this.lines,
  });

  final String receiptId;
  final String saleId;
  final String receiptNumber;
  final String statusDisplay;
  final DateTime issuedAt;
  final SaleReceiptSaleSnapshotDto saleSnapshot;
  final List<SaleReceiptReadLineDto> lines;

  factory SaleReceiptReadDto.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    final lines = <SaleReceiptReadLineDto>[];
    if (rawLines is List) {
      for (final line in rawLines) {
        if (line is Map<String, dynamic>) {
          lines.add(SaleReceiptReadLineDto.fromJson(line));
        } else if (line is Map) {
          lines.add(
            SaleReceiptReadLineDto.fromJson(
              line.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return SaleReceiptReadDto(
      receiptId: _readString(json['receiptId']),
      saleId: _readString(json['saleId']),
      receiptNumber: _readString(json['receiptNumber']),
      statusDisplay: _readString(json['statusDisplay']),
      issuedAt: _readDateTime(json['issuedAt']),
      saleSnapshot: SaleReceiptSaleSnapshotDto.fromJson(
        _asMap(json['saleSnapshot']),
      ),
      lines: lines,
    );
  }
}

class SaleReceiptSaleSnapshotDto {
  const SaleReceiptSaleSnapshotDto({
    required this.paymentMethod,
    required this.tenderCurrency,
    required this.subtotalUsd,
    required this.subtotalKhr,
    required this.discountUsd,
    required this.discountKhr,
    required this.vatUsd,
    required this.vatKhr,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
  });

  final String paymentMethod;
  final String tenderCurrency;
  final double subtotalUsd;
  final double subtotalKhr;
  final double discountUsd;
  final double discountKhr;
  final double vatUsd;
  final double vatKhr;
  final double grandTotalUsd;
  final double grandTotalKhr;

  factory SaleReceiptSaleSnapshotDto.fromJson(Map<String, dynamic> json) {
    return SaleReceiptSaleSnapshotDto(
      paymentMethod: _readString(json['paymentMethod']),
      tenderCurrency: _readString(json['tenderCurrency']),
      subtotalUsd: _readDouble(
        json['subtotalUsd'] ??
            json['subtotalUsdExact'] ??
            json['grandTotalUsd'],
      ),
      subtotalKhr: _readDouble(
        json['subtotalKhr'] ??
            json['subtotalKhrExact'] ??
            json['grandTotalKhr'],
      ),
      discountUsd: _readDouble(json['discountUsd'] ?? 0),
      discountKhr: _readDouble(json['discountKhr'] ?? 0),
      vatUsd: _readDouble(json['vatUsd'] ?? json['vatAmountUsd'] ?? 0),
      vatKhr: _readDouble(json['vatKhr'] ?? json['vatAmountKhr'] ?? 0),
      grandTotalUsd: _readDouble(json['grandTotalUsd']),
      grandTotalKhr: _readDouble(json['grandTotalKhr']),
    );
  }
}

class SaleReceiptReadLineDto {
  const SaleReceiptReadLineDto({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotalAmount,
    this.modifiers = const <SaleReceiptReadModifierDto>[],
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final double lineTotalAmount;
  final List<SaleReceiptReadModifierDto> modifiers;

  factory SaleReceiptReadLineDto.fromJson(Map<String, dynamic> json) {
    final modifiers = <SaleReceiptReadModifierDto>[];
    final rawModifiers = json['modifierSnapshot'];
    if (rawModifiers is List) {
      for (final modifier in rawModifiers) {
        if (modifier is Map<String, dynamic>) {
          modifiers.add(SaleReceiptReadModifierDto.fromJson(modifier));
        } else if (modifier is Map) {
          modifiers.add(
            SaleReceiptReadModifierDto.fromJson(
              modifier.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return SaleReceiptReadLineDto(
      name: _readString(json['menuItemNameSnapshot'] ?? json['name']),
      quantity: _readInt(json['quantity']),
      unitPrice: _readDouble(json['unitPrice']),
      lineTotalAmount: _readDouble(
        json['lineTotalAmount'] ?? json['lineTotalUsdExact'],
      ),
      modifiers: modifiers,
    );
  }
}

class SaleReceiptReadModifierDto {
  const SaleReceiptReadModifierDto({
    required this.name,
    this.priceDeltaUsd = 0,
  });

  final String name;
  final double priceDeltaUsd;

  factory SaleReceiptReadModifierDto.fromJson(Map<String, dynamic> json) {
    return SaleReceiptReadModifierDto(
      name: _readString(
        json['label'] ??
            json['name'] ??
            json['optionLabel'] ??
            json['optionNameSnapshot'],
      ),
      priceDeltaUsd: _readDouble(
        json['priceAdjustmentUsd'] ??
            json['priceDeltaUsd'] ??
            json['price'] ??
            0,
      ),
    );
  }
}

class SaleCashCheckoutResponseDto {
  const SaleCashCheckoutResponseDto({
    required this.sale,
    this.orderId,
    this.order,
    this.receipt,
  });

  final SaleDto sale;
  final String? orderId;
  final SaleCheckoutOrderAnchorDto? order;
  final SaleReceiptProjectionDto? receipt;

  factory SaleCashCheckoutResponseDto.fromJson(Map<String, dynamic> json) {
    final salePayload = json['sale'] is Map<String, dynamic>
        ? _asMap(json['sale'])
        : json;
    final orderPayload = _asMap(json['order']);
    return SaleCashCheckoutResponseDto(
      sale: SaleDto.fromJson(salePayload),
      orderId: _readNullableString(
        json['orderId'] ?? salePayload['orderId'] ?? orderPayload['id'],
      ),
      order: orderPayload.isEmpty
          ? null
          : SaleCheckoutOrderAnchorDto.fromJson(orderPayload),
      receipt: json['receipt'] == null
          ? null
          : SaleReceiptProjectionDto.fromJson(_asMap(json['receipt'])),
    );
  }
}

class SaleCheckoutOrderAnchorDto {
  const SaleCheckoutOrderAnchorDto({
    required this.id,
    required this.status,
    required this.sourceMode,
    this.checkedOutAt,
  });

  final String id;
  final String status;
  final String sourceMode;
  final DateTime? checkedOutAt;

  factory SaleCheckoutOrderAnchorDto.fromJson(Map<String, dynamic> json) {
    return SaleCheckoutOrderAnchorDto(
      id: _readString(json['id']),
      status: _readString(json['status']),
      sourceMode: _readString(json['sourceMode']),
      checkedOutAt: _readNullableDateTime(json['checkedOutAt']),
    );
  }
}

class SaleKhqrIntentStateDto {
  const SaleKhqrIntentStateDto({
    required this.paymentIntentId,
    required this.status,
    this.saleId,
    this.reasonCode,
  });

  final String paymentIntentId;
  final String status;
  final String? saleId;
  final String? reasonCode;

  factory SaleKhqrIntentStateDto.fromJson(Map<String, dynamic> json) {
    return SaleKhqrIntentStateDto(
      paymentIntentId: _readString(json['paymentIntentId']),
      status: _readString(json['status']),
      saleId: _readNullableString(json['saleId']),
      reasonCode: SaleCheckoutReasonCodes.normalize(
        _readNullableString(json['reasonCode']),
      ),
    );
  }
}

class SaleKhqrAttemptResponseDto {
  const SaleKhqrAttemptResponseDto({
    required this.attemptId,
    required this.paymentIntentId,
    this.saleId,
    required this.md5,
    required this.status,
  });

  final String attemptId;
  final String paymentIntentId;
  final String? saleId;
  final String md5;
  final String status;

  factory SaleKhqrAttemptResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleKhqrAttemptResponseDto(
      attemptId: _readString(json['attemptId']),
      paymentIntentId: _readString(json['paymentIntentId']),
      saleId: _readNullableString(json['saleId']),
      md5: _readString(json['md5']),
      status: _readString(json['status']),
    );
  }
}

class SaleKhqrPaymentRequestDto {
  const SaleKhqrPaymentRequestDto({
    required this.md5,
    required this.payload,
    required this.payloadType,
    this.deepLinkUrl,
    this.amount,
    this.currency,
    this.toAccountId,
    this.receiverName,
    this.expiresAt,
  });

  final String md5;
  final String payload;
  final String payloadType;
  final String? deepLinkUrl;
  final double? amount;
  final String? currency;
  final String? toAccountId;
  final String? receiverName;
  final DateTime? expiresAt;

  factory SaleKhqrPaymentRequestDto.fromJson(Map<String, dynamic> json) {
    return SaleKhqrPaymentRequestDto(
      md5: _readString(json['md5']),
      payload: _readString(json['payload']),
      payloadType: _readString(json['payloadType']),
      deepLinkUrl: _readNullableString(json['deepLinkUrl']),
      amount: _readNullableDouble(json['amount']),
      currency: _readNullableString(json['currency']),
      toAccountId: _readNullableString(json['toAccountId']),
      receiverName: _readNullableString(json['receiverName']),
      expiresAt: _readNullableDateTime(json['expiresAt']),
    );
  }
}

class SaleKhqrPreviewDto {
  const SaleKhqrPreviewDto({
    required this.itemCount,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
  });

  final int itemCount;
  final double grandTotalUsd;
  final double grandTotalKhr;

  factory SaleKhqrPreviewDto.fromJson(Map<String, dynamic> json) {
    return SaleKhqrPreviewDto(
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      grandTotalUsd: _readDouble(json['grandTotalUsd']),
      grandTotalKhr: _readDouble(json['grandTotalKhr']),
    );
  }
}

class SaleKhqrInitiateResponseDto {
  const SaleKhqrInitiateResponseDto({
    required this.id,
    required this.intent,
    required this.attempt,
    required this.paymentRequest,
    required this.preview,
  });

  final String id;
  final SaleKhqrIntentStateDto intent;
  final SaleKhqrAttemptResponseDto attempt;
  final SaleKhqrPaymentRequestDto paymentRequest;
  final SaleKhqrPreviewDto preview;

  factory SaleKhqrInitiateResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleKhqrInitiateResponseDto(
      id: _readString(json['id']),
      intent: SaleKhqrIntentStateDto.fromJson(_asMap(json['intent'])),
      attempt: SaleKhqrAttemptResponseDto.fromJson(_asMap(json['attempt'])),
      paymentRequest: SaleKhqrPaymentRequestDto.fromJson(
        _asMap(json['paymentRequest']),
      ),
      preview: SaleKhqrPreviewDto.fromJson(_asMap(json['preview'])),
    );
  }
}

class SaleKhqrIntentCancelDto {
  const SaleKhqrIntentCancelDto({
    required this.paymentIntentId,
    required this.status,
  });

  final String paymentIntentId;
  final String status;

  factory SaleKhqrIntentCancelDto.fromJson(Map<String, dynamic> json) {
    return SaleKhqrIntentCancelDto(
      paymentIntentId: _readString(json['paymentIntentId']),
      status: _readString(json['status']),
    );
  }
}

class SaleKhqrConfirmSaleDto {
  const SaleKhqrConfirmSaleDto({
    required this.saleId,
    required this.status,
    required this.saleType,
  });

  final String saleId;
  final String status;
  final String saleType;

  factory SaleKhqrConfirmSaleDto.fromJson(Map<String, dynamic> json) {
    return SaleKhqrConfirmSaleDto(
      saleId: _readString(json['saleId'] ?? json['id']),
      status: _readString(json['status']),
      saleType: _readString(json['saleType']),
    );
  }
}

class SaleKhqrConfirmResponseDto {
  const SaleKhqrConfirmResponseDto({
    required this.verificationStatus,
    required this.saleFinalized,
    this.sale,
    this.receipt,
  });

  final String verificationStatus;
  final bool saleFinalized;
  final SaleKhqrConfirmSaleDto? sale;
  final SaleReceiptProjectionDto? receipt;

  factory SaleKhqrConfirmResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleKhqrConfirmResponseDto(
      verificationStatus: _readString(json['verificationStatus']),
      saleFinalized: json['saleFinalized'] == true,
      sale: json['sale'] == null
          ? null
          : SaleKhqrConfirmSaleDto.fromJson(_asMap(json['sale'])),
      receipt: json['receipt'] == null
          ? null
          : SaleReceiptProjectionDto.fromJson(_asMap(json['receipt'])),
    );
  }
}

class SaleFinalizeResponseDto {
  const SaleFinalizeResponseDto({required this.sale, this.receipt});

  final SaleDto sale;
  final SaleReceiptProjectionDto? receipt;

  factory SaleFinalizeResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleFinalizeResponseDto(
      sale: SaleDto.fromJson(json),
      receipt: json['receipt'] == null
          ? null
          : SaleReceiptProjectionDto.fromJson(_asMap(json['receipt'])),
    );
  }
}

class SaleOrderPlacementResponseDto {
  const SaleOrderPlacementResponseDto({
    required this.orderId,
    required this.saleId,
    required this.status,
    required this.batchId,
  });

  final String orderId;
  final String saleId;
  final String status;
  final String batchId;

  factory SaleOrderPlacementResponseDto.fromJson(Map<String, dynamic> json) {
    final order = _asMap(json['order']);
    final batch = _asMap(json['batch']);
    final orderId = _readString(
      json['orderId'] ?? json['openTicketId'] ?? json['id'] ?? order['id'],
    );
    return SaleOrderPlacementResponseDto(
      orderId: orderId,
      saleId: _readString(json['saleId'] ?? order['saleId']).isEmpty
          ? orderId
          : _readString(json['saleId'] ?? order['saleId']),
      status: _readString(json['status'] ?? order['status']),
      batchId: _readString(json['batchId'] ?? batch['id']).isEmpty
          ? orderId
          : _readString(json['batchId'] ?? batch['id']),
    );
  }
}

class SaleManualPaymentClaimResponseDto {
  const SaleManualPaymentClaimResponseDto({
    required this.claimId,
    required this.orderId,
    required this.status,
  });

  final String claimId;
  final String orderId;
  final String status;

  factory SaleManualPaymentClaimResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final claim = _asMap(json['claim']);
    final claimId = _readString(json['claimId'] ?? json['id'] ?? claim['id']);
    return SaleManualPaymentClaimResponseDto(
      claimId: claimId,
      orderId: _readString(json['orderId'] ?? claim['orderId']),
      status: _readString(json['status'] ?? json['state'] ?? claim['status']),
    );
  }
}

class SaleApproveManualPaymentClaimResponseDto {
  const SaleApproveManualPaymentClaimResponseDto({
    required this.claimId,
    required this.orderId,
    required this.status,
    this.saleId,
    this.receipt,
  });

  final String claimId;
  final String orderId;
  final String status;
  final String? saleId;
  final SaleReceiptProjectionDto? receipt;

  factory SaleApproveManualPaymentClaimResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final claim = _asMap(json['claim']);
    final receipt = json['receipt'] == null
        ? null
        : SaleReceiptProjectionDto.fromJson(_asMap(json['receipt']));
    final saleId = _readString(
      json['saleId'] ??
          json['sale_id'] ??
          claim['saleId'] ??
          claim['sale_id'] ??
          receipt?.saleId,
    );
    return SaleApproveManualPaymentClaimResponseDto(
      claimId: _readString(json['claimId'] ?? json['id'] ?? claim['id']),
      orderId: _readString(json['orderId'] ?? claim['orderId']),
      status: _readString(
        json['status'] ?? json['state'] ?? claim['status'] ?? claim['state'],
      ),
      saleId: saleId.isEmpty ? null : saleId,
      receipt: receipt,
    );
  }
}

class SaleRejectManualPaymentClaimResponseDto {
  const SaleRejectManualPaymentClaimResponseDto({
    required this.claimId,
    required this.orderId,
    required this.status,
  });

  final String claimId;
  final String orderId;
  final String status;

  factory SaleRejectManualPaymentClaimResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final claim = _asMap(json['claim']);
    return SaleRejectManualPaymentClaimResponseDto(
      claimId: _readString(json['claimId'] ?? json['id'] ?? claim['id']),
      orderId: _readString(json['orderId'] ?? claim['orderId']),
      status: _readString(
        json['status'] ?? json['state'] ?? claim['status'] ?? claim['state'],
      ),
    );
  }
}

class SaleOrderListItemResponseDto {
  const SaleOrderListItemResponseDto({
    required this.orderId,
    required this.saleId,
    required this.status,
    required this.sourceMode,
    required this.openedByAccountId,
    required this.openedByDisplayName,
    required this.fulfillmentStatus,
    required this.totalUsdExact,
    required this.linesPreview,
    required this.createdAt,
    required this.updatedAt,
    this.saleStatus,
    this.checkedOutAt,
    this.paymentMethod,
    this.manualPaymentClaimId,
    this.manualPaymentClaimStatus,
    this.manualPaymentClaimRequestedByAccountId,
    this.manualPaymentClaimRequestedByDisplayName,
    this.manualPaymentClaimRequestedAt,
  });

  final String orderId;
  final String saleId;
  final String status;
  final String sourceMode;
  final String openedByAccountId;
  final String? openedByDisplayName;
  final String? fulfillmentStatus;
  final double totalUsdExact;
  final List<SaleOrderListLinePreviewResponseDto> linesPreview;
  final String? saleStatus;
  final DateTime? checkedOutAt;
  final String? paymentMethod;
  final String? manualPaymentClaimId;
  final String? manualPaymentClaimStatus;
  final String? manualPaymentClaimRequestedByAccountId;
  final String? manualPaymentClaimRequestedByDisplayName;
  final DateTime? manualPaymentClaimRequestedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SaleOrderListItemResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleOrderListItemResponseDto(
      orderId: _readString(json['orderId'] ?? json['id']),
      saleId: _readString(json['saleId']),
      status: _readString(json['status']),
      sourceMode: _readString(json['sourceMode']),
      openedByAccountId: _readString(json['openedByAccountId']),
      openedByDisplayName: _readNullableString(json['openedByDisplayName']),
      fulfillmentStatus: _readNullableString(json['fulfillmentStatus']),
      totalUsdExact: _readDouble(json['totalUsdExact']),
      saleStatus: _readNullableString(json['saleStatus']),
      linesPreview: _readTypedList(
        json['linesPreview'],
        SaleOrderListLinePreviewResponseDto.fromJson,
      ),
      checkedOutAt: _readNullableDateTime(json['checkedOutAt']),
      paymentMethod: _readNullableString(json['paymentMethod']),
      manualPaymentClaimId: _readNullableString(json['manualPaymentClaimId']),
      manualPaymentClaimStatus: _readNullableString(
        json['manualPaymentClaimStatus'],
      ),
      manualPaymentClaimRequestedByAccountId: _readNullableString(
        json['manualPaymentClaimRequestedByAccountId'],
      ),
      manualPaymentClaimRequestedByDisplayName: _readNullableString(
        json['manualPaymentClaimRequestedByDisplayName'],
      ),
      manualPaymentClaimRequestedAt: _readNullableDateTime(
        json['manualPaymentClaimRequestedAt'],
      ),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }
}

class SaleOrderListLinePreviewResponseDto {
  const SaleOrderListLinePreviewResponseDto({
    required this.menuItemNameSnapshot,
    required this.quantity,
    required this.modifierLabels,
  });

  final String menuItemNameSnapshot;
  final int quantity;
  final List<String> modifierLabels;

  factory SaleOrderListLinePreviewResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final modifierLabels = <String>[];
    final rawLabels = json['modifierLabels'];
    if (rawLabels is List) {
      for (final label in rawLabels) {
        final value = label?.toString().trim() ?? '';
        if (value.isNotEmpty) modifierLabels.add(value);
      }
    }

    return SaleOrderListLinePreviewResponseDto(
      menuItemNameSnapshot: _readString(json['menuItemNameSnapshot']),
      quantity: _readInt(json['quantity']),
      modifierLabels: modifierLabels,
    );
  }
}

class SaleOrdersListResponseDto {
  const SaleOrdersListResponseDto({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final List<SaleOrderListItemResponseDto> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;

  factory SaleOrdersListResponseDto.fromJson(Map<String, dynamic> json) {
    final items = <SaleOrderListItemResponseDto>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(SaleOrderListItemResponseDto.fromJson(item));
        } else if (item is Map) {
          items.add(
            SaleOrderListItemResponseDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return SaleOrdersListResponseDto(
      items: items,
      limit: _readInt(json['limit']),
      offset: _readInt(json['offset']),
      total: _readInt(json['total']),
      hasMore: json['hasMore'] == true,
    );
  }
}

class SaleOrderLineReadDto {
  const SaleOrderLineReadDto({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.menuItemNameSnapshot,
    required this.unitPrice,
    required this.quantity,
    required this.lineSubtotal,
    required this.note,
  });

  final String id;
  final String orderId;
  final String menuItemId;
  final String menuItemNameSnapshot;
  final double unitPrice;
  final int quantity;
  final double lineSubtotal;
  final String? note;

  factory SaleOrderLineReadDto.fromJson(Map<String, dynamic> json) {
    return SaleOrderLineReadDto(
      id: _readString(json['id']),
      orderId: _readString(json['orderId']),
      menuItemId: _readString(json['menuItemId']),
      menuItemNameSnapshot: _readString(
        json['menuItemNameSnapshot'] ?? json['menuItemName'],
      ),
      unitPrice: _readDouble(json['unitPrice']),
      quantity: _readInt(json['quantity']),
      lineSubtotal: _readDouble(json['lineSubtotal']),
      note: _readNullableString(json['note']),
    );
  }
}

class SaleOrderFulfillmentBatchReadDto {
  const SaleOrderFulfillmentBatchReadDto({
    required this.id,
    required this.orderId,
    required this.status,
    required this.createdByAccountId,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.completedAt,
  });

  final String id;
  final String orderId;
  final String status;
  final String createdByAccountId;
  final String? note;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SaleOrderFulfillmentBatchReadDto.fromJson(Map<String, dynamic> json) {
    return SaleOrderFulfillmentBatchReadDto(
      id: _readString(json['id']),
      orderId: _readString(json['orderId']),
      status: _readString(json['status']),
      createdByAccountId: _readString(json['createdByAccountId']),
      note: _readNullableString(json['note']),
      completedAt: _readNullableDateTime(json['completedAt']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }
}

class SaleManualPaymentClaimReadDto {
  const SaleManualPaymentClaimReadDto({
    required this.claimId,
    required this.orderId,
    required this.status,
    this.claimedPaymentMethod,
    this.tenderCurrency,
    this.claimedTenderAmount,
    this.proofImageUrl,
    this.customerReference,
    this.note,
  });

  final String claimId;
  final String orderId;
  final String status;
  final String? claimedPaymentMethod;
  final String? tenderCurrency;
  final double? claimedTenderAmount;
  final String? proofImageUrl;
  final String? customerReference;
  final String? note;

  factory SaleManualPaymentClaimReadDto.fromJson(Map<String, dynamic> json) {
    final claim = _asMap(json['claim']);
    return SaleManualPaymentClaimReadDto(
      claimId: _readString(json['claimId'] ?? json['id'] ?? claim['id']),
      orderId: _readString(json['orderId'] ?? claim['orderId']),
      status: _readString(json['status'] ?? claim['status']),
      claimedPaymentMethod: _readNullableString(
        json['claimedPaymentMethod'] ?? claim['claimedPaymentMethod'],
      ),
      tenderCurrency: _readNullableString(
        json['tenderCurrency'] ?? claim['tenderCurrency'],
      ),
      claimedTenderAmount: _readNullableDouble(
        json['claimedTenderAmount'] ?? claim['claimedTenderAmount'],
      ),
      proofImageUrl: _readNullableString(
        json['proofImageUrl'] ?? claim['proofImageUrl'],
      ),
      customerReference: _readNullableString(
        json['customerReference'] ?? claim['customerReference'],
      ),
      note: _readNullableString(json['note'] ?? claim['note']),
    );
  }
}

class SaleOrderDetailResponseDto {
  const SaleOrderDetailResponseDto({
    required this.orderId,
    required this.tenantId,
    required this.branchId,
    required this.openedByAccountId,
    required this.status,
    required this.sourceMode,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
    required this.fulfillmentBatches,
    required this.manualPaymentClaims,
    this.saleId,
    this.saleStatus,
    this.paymentMethod,
    this.checkedOutAt,
    this.checkedOutByAccountId,
    this.cancelledAt,
    this.cancelledByAccountId,
    this.cancelReason,
  });

  final String orderId;
  final String tenantId;
  final String branchId;
  final String openedByAccountId;
  final String status;
  final String sourceMode;
  final String? saleId;
  final String? saleStatus;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? checkedOutAt;
  final String? checkedOutByAccountId;
  final DateTime? cancelledAt;
  final String? cancelledByAccountId;
  final String? cancelReason;
  final List<SaleOrderLineReadDto> lines;
  final List<SaleOrderFulfillmentBatchReadDto> fulfillmentBatches;
  final List<SaleManualPaymentClaimReadDto> manualPaymentClaims;

  factory SaleOrderDetailResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleOrderDetailResponseDto(
      orderId: _readString(json['orderId'] ?? json['id']),
      tenantId: _readString(json['tenantId']),
      branchId: _readString(json['branchId']),
      openedByAccountId: _readString(json['openedByAccountId']),
      status: _readString(json['status']),
      sourceMode: _readString(json['sourceMode']),
      saleId: _readNullableString(json['saleId']),
      saleStatus: _readNullableString(json['saleStatus']),
      paymentMethod: _readNullableString(json['paymentMethod']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      checkedOutAt: _readNullableDateTime(json['checkedOutAt']),
      checkedOutByAccountId: _readNullableString(json['checkedOutByAccountId']),
      cancelledAt: _readNullableDateTime(json['cancelledAt']),
      cancelledByAccountId: _readNullableString(json['cancelledByAccountId']),
      cancelReason: _readNullableString(json['cancelReason']),
      lines: _readTypedList(json['lines'], SaleOrderLineReadDto.fromJson),
      fulfillmentBatches: _readTypedList(
        json['fulfillmentBatches'],
        SaleOrderFulfillmentBatchReadDto.fromJson,
      ),
      manualPaymentClaims: _readTypedList(
        json['manualPaymentClaims'],
        SaleManualPaymentClaimReadDto.fromJson,
      ),
    );
  }
}

class SaleOrderFulfillmentUpdateResponseDto {
  const SaleOrderFulfillmentUpdateResponseDto({
    required this.id,
    required this.orderId,
    required this.status,
    required this.createdByAccountId,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.completedAt,
  });

  final String id;
  final String orderId;
  final String status;
  final String createdByAccountId;
  final String? note;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SaleOrderFulfillmentUpdateResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return SaleOrderFulfillmentUpdateResponseDto(
      id: _readString(json['id']),
      orderId: _readString(json['orderId']),
      status: _readString(json['status']),
      createdByAccountId: _readString(json['createdByAccountId']),
      note: _readNullableString(json['note']),
      completedAt: _readNullableDateTime(json['completedAt']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }
}

class SaleVoidRequestDto {
  const SaleVoidRequestDto({
    required this.id,
    required this.saleId,
    required this.status,
    required this.reason,
    this.reviewNote,
    required this.requestedAt,
    this.reviewedAt,
    this.requestedByAccountId,
    this.reviewedByAccountId,
  });

  final String id;
  final String saleId;
  final String status;
  final String reason;
  final String? reviewNote;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? requestedByAccountId;
  final String? reviewedByAccountId;

  factory SaleVoidRequestDto.fromJson(Map<String, dynamic> json) {
    return SaleVoidRequestDto(
      id: _readString(json['id']),
      saleId: _readString(json['saleId']),
      status: _readString(json['status']),
      reason: _readString(json['reason']),
      reviewNote: _readNullableString(json['reviewNote']),
      requestedAt: _readDateTime(json['requestedAt']),
      reviewedAt: _readNullableDateTime(json['reviewedAt']),
      requestedByAccountId: _readNullableString(json['requestedByAccountId']),
      reviewedByAccountId: _readNullableString(json['reviewedByAccountId']),
    );
  }
}

class SaleVoidRequestQueueItemResponseDto {
  const SaleVoidRequestQueueItemResponseDto({
    required this.voidRequestId,
    required this.saleId,
    required this.tenantId,
    required this.branchId,
    required this.saleStatus,
    required this.voidRequestStatus,
    required this.requestedAt,
    required this.requestedByAccountId,
    required this.reason,
    required this.paymentMethod,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
    required this.saleCreatedAt,
    this.orderId,
    this.branchName,
    this.requestedByDisplayName,
    this.fulfillmentStatus,
  });

  final String voidRequestId;
  final String saleId;
  final String? orderId;
  final String tenantId;
  final String branchId;
  final String? branchName;
  final String saleStatus;
  final String voidRequestStatus;
  final DateTime requestedAt;
  final String requestedByAccountId;
  final String? requestedByDisplayName;
  final String reason;
  final String paymentMethod;
  final double grandTotalUsd;
  final double grandTotalKhr;
  final String? fulfillmentStatus;
  final DateTime saleCreatedAt;

  factory SaleVoidRequestQueueItemResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return SaleVoidRequestQueueItemResponseDto(
      voidRequestId: _readString(json['voidRequestId']),
      saleId: _readString(json['saleId']),
      orderId: _readNullableString(json['orderId']),
      tenantId: _readString(json['tenantId']),
      branchId: _readString(json['branchId']),
      branchName: _readNullableString(json['branchName']),
      saleStatus: _readString(json['saleStatus']),
      voidRequestStatus: _readString(json['voidRequestStatus']),
      requestedAt: _readDateTime(json['requestedAt']),
      requestedByAccountId: _readString(json['requestedByAccountId']),
      requestedByDisplayName: _readNullableString(
        json['requestedByDisplayName'],
      ),
      reason: _readString(json['reason']),
      paymentMethod: _readString(json['paymentMethod']),
      grandTotalUsd: _readDouble(json['grandTotalUsd']),
      grandTotalKhr: _readDouble(json['grandTotalKhr']),
      fulfillmentStatus: _readNullableString(json['fulfillmentStatus']),
      saleCreatedAt: _readDateTime(json['saleCreatedAt']),
    );
  }
}

class SaleVoidRequestQueueResponseDto {
  const SaleVoidRequestQueueResponseDto({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final List<SaleVoidRequestQueueItemResponseDto> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;

  factory SaleVoidRequestQueueResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleVoidRequestQueueResponseDto(
      items: _readTypedList(
        json['items'],
        SaleVoidRequestQueueItemResponseDto.fromJson,
      ),
      limit: _readInt(json['limit']),
      offset: _readInt(json['offset']),
      total: _readInt(json['total']),
      hasMore: json['hasMore'] == true,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

List<T> _readTypedList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) parser,
) {
  final items = <T>[];
  if (raw is! List) return items;
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      items.add(parser(item));
    } else if (item is Map) {
      items.add(parser(Map<String, dynamic>.from(item)));
    }
  }
  return items;
}

List<SaleItemDto> _readSaleItems(
  Map<String, dynamic> json, {
  bool preferItems = false,
}) {
  final items = <SaleItemDto>[];
  final rawItems = preferItems ? json['items'] ?? json['lines'] : json['lines'];
  if (rawItems is List) {
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        items.add(SaleItemDto.fromJson(item));
      }
    }
  }
  return items;
}

String _readString(dynamic value) => value?.toString().trim() ?? '';

String? _readNullableString(dynamic value) {
  final text = _readString(value);
  return text.isEmpty ? null : text;
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readNullableDouble(dynamic value) {
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  return parsed;
}

int _readInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _readDateTime(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _readNullableDateTime(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '');
}
