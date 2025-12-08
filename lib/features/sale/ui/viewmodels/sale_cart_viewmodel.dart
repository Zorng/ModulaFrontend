import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/policy/ui/viewmodels/policy_viewmodel.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';
import 'package:modular_pos/features/sale/ui/view/sale_item_detail_page.dart';

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
}

class SaleCartState {
  const SaleCartState({
    this.saleId,
    this.saleType = 'take_away',
    this.lines = const [],
    this.tenderCurrency = 'USD',
    this.paymentMethod = 'cash',
    this.cashUsd = 0,
    this.cashKhr = 0,
  });

  final String? saleId;
  final String saleType;
  final List<CartLine> lines;
  final String tenderCurrency;
  final String paymentMethod;
  final double cashUsd;
  final double cashKhr;

  SaleCartState copyWith({
    String? saleId,
    String? saleType,
    List<CartLine>? lines,
    String? tenderCurrency,
    String? paymentMethod,
    double? cashUsd,
    double? cashKhr,
  }) {
    return SaleCartState(
      saleId: saleId ?? this.saleId,
      saleType: saleType ?? this.saleType,
      lines: lines ?? this.lines,
      tenderCurrency: tenderCurrency ?? this.tenderCurrency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashUsd: cashUsd ?? this.cashUsd,
      cashKhr: cashKhr ?? this.cashKhr,
    );
  }
}

final saleCartProvider = NotifierProvider<SaleCartNotifier, SaleCartState>(
  SaleCartNotifier.new,
);

class SaleCartNotifier extends Notifier<SaleCartState> {
  SaleCartNotifier();

  late final SaleRepository _repo = ref.read(saleRepositoryProvider);

  @override
  SaleCartState build() => const SaleCartState();

  double _fxRate() {
    final policies = ref.read(policyNotifierProvider);
    return policies.salesPolicy.saleFxRateKhrPerUsd;
  }

  static const bool _enforceCashSession = true;

  void _assertCashSessionOpen() {
    final session = ref.read(cashSessionViewModelProvider);
    if (_enforceCashSession && session.sessionStatus != SessionStatus.open) {
      throw Exception(
        'No active cash session. Please start one to begin selling.',
      );
    }
  }

  Future<void> _ensureSaleId() async {
    if (state.saleId != null && state.saleId!.isNotEmpty) return;
    _assertCashSessionOpen();
    final id = await _repo.ensureDraft(
      saleType: state.saleType,
      fxRateUsed: _fxRate(),
    );
    state = state.copyWith(saleId: id);
  }

  Future<void> addSelection(SaleItemSelectionResult selection) async {
    _assertCashSessionOpen();
    await _ensureSaleId();
    final saleId = state.saleId;
    if (saleId == null) return;

    final addPayload = _buildAddPayloadFromSelection(selection);
    final added = await _repo.addItem(
      saleId: saleId,
      menuItemId: selection.item.id,
      quantity: selection.quantity,
      modifiers: addPayload.modifiers,
      unitPriceUsd: addPayload.unitPriceUsd,
      lineTotalUsdExact: addPayload.lineTotalUsdExact,
      addonTotalUsd: addPayload.addonTotalUsd,
      pricingSnapshot: addPayload.pricingSnapshot,
    );
    final saleItemId = _extractSaleItemId(
      added,
      selection.item.id,
      selection.selectedOptionIds,
    );
    // Only update local state after successful sync.
    final lines = [...state.lines];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.item.id == selection.item.id &&
          _mapsEqual(line.selectedOptionIds, selection.selectedOptionIds)) {
        lines[i] = line.copyWith(
          quantity: line.quantity + selection.quantity,
          saleItemId: line.saleItemId ?? saleItemId,
          selectedOptions: line.selectedOptions.isNotEmpty
              ? line.selectedOptions
              : selection.selectedOptions,
        );
        state = state.copyWith(lines: lines);
        return;
      }
    }
    state = state.copyWith(
      lines: [
        ...lines,
        CartLine(
          item: selection.item,
          quantity: selection.quantity,
          selectedOptionIds: selection.selectedOptionIds,
          selectedOptions: selection.selectedOptions,
          saleItemId: saleItemId,
        ),
      ],
    );
  }

  void setTenderCurrency(String currency) {
    state = state.copyWith(tenderCurrency: currency);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  Future<void> setSaleType(String saleType) async {
    // If no draft or no lines yet, just update the sale type for future drafts.
    if (state.saleId == null || state.saleId!.isEmpty || state.lines.isEmpty) {
      state = state.copyWith(saleType: saleType);
      return;
    }

    // If changing sale type mid-cart, recreate the draft with the new type and re-sync items.
    if (state.saleType == saleType) return;
    final currentLines = state.lines;
    final newSaleId = await _repo.ensureDraft(
      saleType: saleType,
      fxRateUsed: _fxRate(),
    );
    final rebuiltLines = <CartLine>[];

    for (final line in currentLines) {
      final rebuilt = _replayLineToSale(newSaleId, line);
      rebuiltLines.add(await rebuilt);
    }

    state = state.copyWith(
      saleType: saleType,
      saleId: newSaleId,
      lines: rebuiltLines,
    );
  }

  void setCashReceived({double? usd, double? khr}) {
    state = state.copyWith(
      cashUsd: usd ?? state.cashUsd,
      cashKhr: khr ?? state.cashKhr,
    );
  }

  Future<void> updateQuantity(int index, int quantity) async {
    if (index < 0 || index >= state.lines.length) return;
    final lines = [...state.lines];
    final target = lines[index];
    if (quantity <= 0) {
      lines.removeAt(index);
      state = state.copyWith(lines: lines);
      await _removeRemote(target);
      return;
    }
    lines[index] = target.copyWith(quantity: quantity);
    state = state.copyWith(lines: lines);
    await _updateRemoteQuantity(target, quantity);
  }

  Future<void> _updateRemoteQuantity(CartLine line, int quantity) async {
    final saleId = state.saleId;
    if (saleId == null) return;
    // backend expects itemId, but we don't have sale item id mapping;
    // send menuItemId to update; if unsupported backend will ignore.
    try {
      await _repo.updateItemQuantity(
        saleId: saleId,
        itemId: line.saleItemId ?? line.item.id,
        quantity: quantity,
      );
    } catch (_) {}
  }

  Future<void> _removeRemote(CartLine line) async {
    final saleId = state.saleId;
    if (saleId == null) return;
    try {
      await _repo.removeItem(
        saleId: saleId,
        itemId: line.saleItemId ?? line.item.id,
      );
    } catch (_) {}
  }

  void clear() {
    state = const SaleCartState();
  }

  Future<Map<String, dynamic>> checkout() async {
    final saleId = state.saleId;
    if (saleId == null) throw Exception('No sale draft');
    final cashReceived = <String, num>{};
    if (state.tenderCurrency.toUpperCase() == 'USD' && state.cashUsd > 0) {
      cashReceived['usd'] = state.cashUsd;
    } else if (state.tenderCurrency.toUpperCase() == 'KHR' &&
        state.cashKhr > 0) {
      cashReceived['khr'] = state.cashKhr;
    }
    final pre = await _repo.preCheckout(
      saleId: saleId,
      tenderCurrency: state.tenderCurrency,
      paymentMethod: state.paymentMethod,
      cashReceived: cashReceived.isEmpty ? null : cashReceived,
    );
    final finalized = await _repo.finalize(saleId);
    final result = {'preCheckout': pre, 'finalize': finalized};
    // Reset state so subsequent carts start with a fresh draft.
    clear();
    return result;
  }

  bool _mapsEqual(Map<String, List<String>> a, Map<String, List<String>> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) return false;
      final listA = [...entry.value]..sort();
      final listB = [...other]..sort();
      if (listA.length != listB.length) return false;
      for (var i = 0; i < listA.length; i++) {
        if (listA[i] != listB[i]) return false;
      }
    }
    return true;
  }

  String? _extractSaleItemId(
    Map<String, dynamic> payload,
    String menuItemId,
    Map<String, List<String>> selectedOptionIds,
  ) {
    final items = _extractItems(payload);
    for (final raw in items.reversed) {
      if (raw is! Map<String, dynamic>) continue;
      final rawMenuItemId = raw['menuItemId']?.toString();
      if (rawMenuItemId != menuItemId) continue;
      final modifiers = raw['modifiers'];
      if (!_modifiersMatch(modifiers, selectedOptionIds)) continue;
      final id = raw['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  List<dynamic> _extractItems(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (payload['items'] is List)
      return List<dynamic>.from(payload['items'] as List);
    if (data is Map<String, dynamic> && data['items'] is List) {
      return List<dynamic>.from(data['items'] as List);
    }
    return const [];
  }

  bool _modifiersMatch(
    dynamic rawModifiers,
    Map<String, List<String>> selectedOptionIds,
  ) {
    if (rawModifiers is! List) return true;
    final normalizedSelected = {
      for (final entry in selectedOptionIds.entries)
        entry.key: [...entry.value]..sort(),
    };
    for (final mod in rawModifiers) {
      if (mod is! Map<String, dynamic>) continue;
      final groupId = mod['groupId']?.toString();
      if (groupId == null) continue;
      final optionIdsRaw = mod['optionIds'];
      if (optionIdsRaw is! List) continue;
      final optIds = optionIdsRaw.map((e) => e.toString()).toList()..sort();
      final selected = normalizedSelected[groupId];
      if (selected == null) continue;
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

  _AddItemPayload _buildAddPayloadFromSelection(
    SaleItemSelectionResult selection,
  ) {
    final unitPriceUsd = selection.unitPriceUsd;
    final lineTotalUsdExact = selection.lineTotalUsd;
    final addonTotalUsd = selection.addonTotalUsd;
    final pricingSnapshot = {
      'baseUnitPriceUsd': selection.item.price,
      'addonTotalUsd': addonTotalUsd,
      'unitPriceUsd': unitPriceUsd,
      'lineTotalUsdExact': lineTotalUsdExact,
    };
    final modifiers = <Map<String, dynamic>>[];
    final entries = selection.selectedOptionIds.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final options =
          selection.selectedOptions[entry.key] ?? const <ModifierOption>[];
      final optionSummaries = options
          .map(
            (opt) => {
              'id': opt.id,
              'label': opt.name,
              'priceAdjustmentUsd': opt.price,
              'isDefault': opt.isDefault,
            },
          )
          .toList();
      final addonTotal = options.fold<double>(0, (sum, opt) => sum + opt.price);
      final modifierPayload = <String, dynamic>{
        'groupId': entry.key,
        'optionIds': entry.value,
        if (optionSummaries.isNotEmpty) 'options': optionSummaries,
        // Backend saleEntity expects priceAdjustmentUsd at the modifier level.
        'priceAdjustmentUsd': addonTotal,
        if (addonTotal != 0) 'priceAdjustmentUsdTotal': addonTotal,
      };
      if (i == 0) {
        modifierPayload['pricingSnapshot'] = pricingSnapshot;
      }
      modifiers.add(modifierPayload);
    }
    if (modifiers.isEmpty) {
      modifiers.add({'pricingSnapshot': pricingSnapshot});
    }

    return _AddItemPayload(
      modifiers: modifiers,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
      addonTotalUsd: addonTotalUsd,
      pricingSnapshot: pricingSnapshot,
    );
  }

  Future<CartLine> _replayLineToSale(String saleId, CartLine line) async {
    final payload = _buildAddPayloadFromLine(line);
    final added = await _repo.addItem(
      saleId: saleId,
      menuItemId: line.item.id,
      quantity: line.quantity,
      modifiers: payload.modifiers,
      unitPriceUsd: payload.unitPriceUsd,
      lineTotalUsdExact: payload.lineTotalUsdExact,
      addonTotalUsd: payload.addonTotalUsd,
      pricingSnapshot: payload.pricingSnapshot,
    );
    final saleItemId = _extractSaleItemId(
      added,
      line.item.id,
      line.selectedOptionIds,
    );
    return line.copyWith(saleItemId: saleItemId);
  }

  _AddItemPayload _buildAddPayloadFromLine(CartLine line) {
    double addonTotalUsd = 0;
    final entries = line.selectedOptionIds.entries.toList();
    final modifiers = <Map<String, dynamic>>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final options =
          line.selectedOptions[entry.key] ?? const <ModifierOption>[];
      final optionSummaries = options
          .map(
            (opt) => {
              'id': opt.id,
              'label': opt.name,
              'priceAdjustmentUsd': opt.price,
              'isDefault': opt.isDefault,
            },
          )
          .toList();
      final addonTotal = options.fold<double>(0, (sum, opt) => sum + opt.price);
      addonTotalUsd += addonTotal;
      final modifierPayload = <String, dynamic>{
        'groupId': entry.key,
        'optionIds': entry.value,
        if (optionSummaries.isNotEmpty) 'options': optionSummaries,
        'priceAdjustmentUsd': addonTotal,
        if (addonTotal != 0) 'priceAdjustmentUsdTotal': addonTotal,
      };
      modifiers.add(modifierPayload);
    }
    final unitPriceUsd = line.item.price + addonTotalUsd;
    final lineTotalUsdExact = unitPriceUsd * line.quantity;
    final pricingSnapshot = {
      'baseUnitPriceUsd': line.item.price,
      'addonTotalUsd': addonTotalUsd,
      'unitPriceUsd': unitPriceUsd,
      'lineTotalUsdExact': lineTotalUsdExact,
    };
    if (modifiers.isNotEmpty) {
      modifiers.first['pricingSnapshot'] = pricingSnapshot;
    } else {
      modifiers.add({'pricingSnapshot': pricingSnapshot});
    }
    return _AddItemPayload(
      modifiers: modifiers,
      unitPriceUsd: unitPriceUsd,
      lineTotalUsdExact: lineTotalUsdExact,
      addonTotalUsd: addonTotalUsd,
      pricingSnapshot: pricingSnapshot,
    );
  }
}

class _AddItemPayload {
  _AddItemPayload({
    required this.modifiers,
    required this.unitPriceUsd,
    required this.lineTotalUsdExact,
    required this.addonTotalUsd,
    required this.pricingSnapshot,
  });

  final List<Map<String, dynamic>> modifiers;
  final double unitPriceUsd;
  final double lineTotalUsdExact;
  final double addonTotalUsd;
  final Map<String, dynamic> pricingSnapshot;
}
