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
    required this.saleType,
    required this.state,
    required this.fxRateUsed,
    required this.tenderCurrency,
    required this.paymentMethod,
    required this.fulfillmentStatus,
    required this.subtotalUsdExact,
    required this.subtotalKhrExact,
    required this.totalUsdExact,
    required this.totalKhrExact,
    required this.cashReceivedUsd,
    required this.cashReceivedKhr,
    required this.changeGivenUsd,
    required this.changeGivenKhr,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  final String id;
  final String clientUuid;
  final String tenantId;
  final String branchId;
  final String employeeId;
  final String saleType;
  final String state;
  final double fxRateUsed;
  final String tenderCurrency;
  final String paymentMethod;
  final String fulfillmentStatus;
  final double subtotalUsdExact;
  final double subtotalKhrExact;
  final double totalUsdExact;
  final double totalKhrExact;
  final double? cashReceivedUsd;
  final double? cashReceivedKhr;
  final double? changeGivenUsd;
  final double? changeGivenKhr;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItemDto> items;

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
    required this.vatUsd,
    required this.grandTotalUsd,
    required this.grandTotalKhr,
  });

  final String paymentMethod;
  final String tenderCurrency;
  final double subtotalUsd;
  final double vatUsd;
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
      vatUsd: _readDouble(json['vatUsd'] ?? json['vatAmountUsd'] ?? 0),
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
  const SaleCashCheckoutResponseDto({required this.sale, this.receipt});

  final SaleDto sale;
  final SaleReceiptProjectionDto? receipt;

  factory SaleCashCheckoutResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleCashCheckoutResponseDto(
      sale: SaleDto.fromJson(_asMap(json['sale'])),
      receipt: json['receipt'] == null
          ? null
          : SaleReceiptProjectionDto.fromJson(_asMap(json['receipt'])),
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
    this.expiresAt,
  });

  final String md5;
  final String payload;
  final String payloadType;
  final String? deepLinkUrl;
  final double? amount;
  final String? currency;
  final String? toAccountId;
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

class SaleVoidRequestDto {
  const SaleVoidRequestDto({
    required this.id,
    required this.saleId,
    required this.status,
    required this.reason,
    this.reviewNote,
    required this.requestedAt,
    this.reviewedAt,
  });

  final String id;
  final String saleId;
  final String status;
  final String reason;
  final String? reviewNote;
  final DateTime requestedAt;
  final DateTime? reviewedAt;

  factory SaleVoidRequestDto.fromJson(Map<String, dynamic> json) {
    return SaleVoidRequestDto(
      id: _readString(json['id']),
      saleId: _readString(json['saleId']),
      status: _readString(json['status']),
      reason: _readString(json['reason']),
      reviewNote: _readNullableString(json['reviewNote']),
      requestedAt: _readDateTime(json['requestedAt']),
      reviewedAt: _readNullableDateTime(json['reviewedAt']),
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
