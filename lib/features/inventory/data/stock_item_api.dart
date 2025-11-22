import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';

final stockItemApiProvider = Provider<StockItemApi>((ref) {
  return StockItemApi();
});

class StockItemApi {
  StockItemApi();

  final List<StockItem> _items = [
    StockItem(
      id: 'main_milk',
      name: 'Whole Milk 1000ml',
      category: 'Dairy',
      baseUnit: 'ml',
      pieceSize: 1000,
      branchId: 'main',
      branchName: 'Main Branch',
      onHand: 3600,
      minThreshold: 2500,
      isActive: true,
      barcode: 'MAIN-MILK-1L',
      imageUrl:
          'https://www.foremostthailand.com/wp-content/uploads/2022/03/plain-fat-0.png',
      lastRestockDate: 'May 15, 2024',
      expiryDate: 'May 30, 2024',
      usageTags: const ['Ingredient'],
    ),
    StockItem(
      id: 'main_beans',
      name: 'Espresso Beans 1kg',
      category: 'Coffee',
      baseUnit: 'g',
      pieceSize: 1000,
      branchId: 'main',
      branchName: 'Main Branch',
      onHand: 2600,
      minThreshold: 2000,
      isActive: true,
      barcode: 'MAIN-BEANS-1KG',
      lastRestockDate: 'May 11, 2024',
      expiryDate: '-',
      usageTags: const ['Ingredient'],
    ),
    StockItem(
      id: 'main_sugar',
      name: 'Sugar Syrup 750ml',
      category: 'Sweetener',
      baseUnit: 'ml',
      pieceSize: 750,
      branchId: 'main',
      branchName: 'Main Branch',
      onHand: 5400,
      minThreshold: 3000,
      isActive: true,
      barcode: 'MAIN-SYRUP-750',
      lastRestockDate: 'May 14, 2024',
      expiryDate: 'Aug 10, 2024',
      usageTags: const ['Ingredient'],
    ),
    StockItem(
      id: 'main_cups',
      name: 'Paper Cups 16oz',
      category: 'Packaging',
      baseUnit: 'pcs',
      pieceSize: 1,
      branchId: 'main',
      branchName: 'Main Branch',
      onHand: 320,
      minThreshold: 200,
      isActive: true,
      barcode: 'MAIN-CUP-16',
      lastRestockDate: 'May 10, 2024',
      expiryDate: '-',
      usageTags: const ['Sellable'],
    ),
    StockItem(
      id: 'main_straws',
      name: 'Compostable Straws',
      category: 'Packaging',
      baseUnit: 'pcs',
      pieceSize: 1,
      branchId: 'main',
      branchName: 'Main Branch',
      onHand: 480,
      minThreshold: 300,
      isActive: true,
      barcode: 'MAIN-STRAWS',
      lastRestockDate: 'May 18, 2024',
      expiryDate: '-',
      usageTags: const ['Sellable'],
    ),
    // Downtown branch
    StockItem(
      id: 'dt_milk',
      name: 'Whole Milk 1000ml',
      category: 'Dairy',
      baseUnit: 'ml',
      pieceSize: 1000,
      branchId: 'downtown',
      branchName: 'Downtown',
      onHand: 2400,
      minThreshold: 2000,
      isActive: true,
      barcode: 'DT-MILK-1L',
      lastRestockDate: 'May 16, 2024',
      expiryDate: 'May 28, 2024',
      usageTags: const ['Ingredient'],
    ),
    StockItem(
      id: 'dt_beans',
      name: 'Espresso Beans 1kg',
      category: 'Coffee',
      baseUnit: 'g',
      pieceSize: 1000,
      branchId: 'downtown',
      branchName: 'Downtown',
      onHand: 1800,
      minThreshold: 1500,
      isActive: true,
      barcode: 'DT-BEANS-1KG',
      lastRestockDate: 'May 13, 2024',
      expiryDate: '-',
      usageTags: const ['Ingredient'],
    ),
    StockItem(
      id: 'dt_sugar',
      name: 'Sugar Syrup 750ml',
      category: 'Sweetener',
      baseUnit: 'ml',
      pieceSize: 750,
      branchId: 'downtown',
      branchName: 'Downtown',
      onHand: 3750,
      minThreshold: 3000,
      isActive: true,
      barcode: 'DT-SYRUP-750',
      lastRestockDate: 'May 09, 2024',
      expiryDate: 'Jul 30, 2024',
      usageTags: const ['Ingredient'],
    ),
    StockItem(
      id: 'dt_cups',
      name: 'Paper Cups 16oz',
      category: 'Packaging',
      baseUnit: 'pcs',
      pieceSize: 1,
      branchId: 'downtown',
      branchName: 'Downtown',
      onHand: 190,
      minThreshold: 160,
      isActive: true,
      barcode: 'DT-CUP-16',
      lastRestockDate: 'May 17, 2024',
      expiryDate: '-',
      usageTags: const ['Sellable'],
    ),
    StockItem(
      id: 'dt_straws',
      name: 'Compostable Straws',
      category: 'Packaging',
      baseUnit: 'pcs',
      pieceSize: 1,
      branchId: 'downtown',
      branchName: 'Downtown',
      onHand: 310,
      minThreshold: 250,
      isActive: true,
      barcode: 'DT-STRAWS',
      lastRestockDate: 'May 11, 2024',
      expiryDate: '-',
      usageTags: const ['Sellable'],
    ),
    // Airport branch
    StockItem(
      id: 'ap_milk',
      name: 'Whole Milk 1000ml',
      category: 'Dairy',
      baseUnit: 'ml',
      pieceSize: 1000,
      branchId: 'airport',
      branchName: 'Airport',
      onHand: 1700,
      minThreshold: 1500,
      isActive: true,
      barcode: 'AP-MILK-1L',
      lastRestockDate: 'May 18, 2024',
      expiryDate: 'May 29, 2024',
      usageTags: const ['Ingredient'],
    ),
    StockItem(
      id: 'ap_beans',
      name: 'Espresso Beans 1kg',
      category: 'Coffee',
      baseUnit: 'g',
      pieceSize: 1000,
      branchId: 'airport',
      branchName: 'Airport',
      onHand: 1300,
      minThreshold: 1000,
      isActive: true,
      barcode: 'AP-BEANS-1KG',
      lastRestockDate: 'May 12, 2024',
      expiryDate: '-',
      usageTags: const ['Ingredient'],
    ),
    StockItem(
      id: 'ap_sugar',
      name: 'Sugar Syrup 750ml',
      category: 'Sweetener',
      baseUnit: 'ml',
      pieceSize: 750,
      branchId: 'airport',
      branchName: 'Airport',
      onHand: 2250,
      minThreshold: 1500,
      isActive: true,
      barcode: 'AP-SYRUP-750',
      lastRestockDate: 'May 13, 2024',
      expiryDate: 'Aug 05, 2024',
      usageTags: const ['Ingredient'],
    ),
    StockItem(
      id: 'ap_cups',
      name: 'Paper Cups 16oz',
      category: 'Packaging',
      baseUnit: 'pcs',
      pieceSize: 1,
      branchId: 'airport',
      branchName: 'Airport',
      onHand: 260,
      minThreshold: 180,
      isActive: true,
      barcode: 'AP-CUP-16',
      lastRestockDate: 'May 16, 2024',
      expiryDate: '-',
      usageTags: const ['Sellable'],
    ),
    StockItem(
      id: 'ap_straws',
      name: 'Compostable Straws',
      category: 'Packaging',
      baseUnit: 'pcs',
      pieceSize: 1,
      branchId: 'airport',
      branchName: 'Airport',
      onHand: 290,
      minThreshold: 220,
      isActive: true,
      barcode: 'AP-STRAWS',
      lastRestockDate: 'May 14, 2024',
      expiryDate: '-',
      usageTags: const ['Sellable'],
    ),
  ];

  Future<List<StockItem>> fetchItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }

  Future<StockItem> createItem(StockItem item) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final newItem = item.copyWith(id: _generateId());
    _items.add(newItem);
    return newItem;
  }

  Future<StockItem> updateItem(StockItem item) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index == -1) {
      throw StateError('Stock item ${item.id} not found');
    }
    _items[index] = item;
    return item;
  }

  Future<void> deleteItem(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _items.removeWhere((element) => element.id == id);
  }

  String _generateId() =>
      'stock_${DateTime.now().microsecondsSinceEpoch.toString()}';
}
