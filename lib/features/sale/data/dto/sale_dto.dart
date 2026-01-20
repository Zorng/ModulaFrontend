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
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt =
        DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final items = <SaleItemDto>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(SaleItemDto.fromJson(item));
        }
      }
    }

    double? numOrNull(dynamic value) => (value is num) ? value.toDouble() : null;

    return SaleDto(
      id: json['id']?.toString() ?? '',
      clientUuid: json['clientUuid']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      saleType: json['saleType']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      fxRateUsed: (json['fxRateUsed'] as num?)?.toDouble() ?? 0,
      tenderCurrency: json['tenderCurrency']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      fulfillmentStatus: json['fulfillmentStatus']?.toString() ?? '',
      subtotalUsdExact: (json['subtotalUsdExact'] as num?)?.toDouble() ?? 0,
      subtotalKhrExact: (json['subtotalKhrExact'] as num?)?.toDouble() ?? 0,
      totalUsdExact: (json['totalUsdExact'] as num?)?.toDouble() ?? 0,
      totalKhrExact: (json['totalKhrExact'] as num?)?.toDouble() ?? 0,
      cashReceivedUsd: numOrNull(json['cashReceivedUsd']),
      cashReceivedKhr: numOrNull(json['cashReceivedKhr']),
      changeGivenUsd: numOrNull(json['changeGivenUsd']),
      changeGivenKhr: numOrNull(json['changeGivenKhr']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: items,
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
    final rawMods = json['modifiers'];
    if (rawMods is List) {
      for (final mod in rawMods) {
        if (mod is Map<String, dynamic>) {
          modifiers.add(SaleModifierDto.fromJson(mod));
        }
      }
    }
    return SaleItemDto(
      id: json['id']?.toString() ?? '',
      saleId: json['saleId']?.toString() ?? '',
      menuItemId: json['menuItemId']?.toString() ?? '',
      menuItemName: json['menuItemName']?.toString() ?? '',
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
      groupId: json['groupId']?.toString() ?? '',
      optionIds: optionIds,
      options: options,
    );
  }
}

class SaleModifierOptionDto {
  const SaleModifierOptionDto({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  factory SaleModifierOptionDto.fromJson(Map<String, dynamic> json) {
    return SaleModifierOptionDto(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}

