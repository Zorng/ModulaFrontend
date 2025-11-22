import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';
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

  final List<StockBatch> _batches = [
    StockBatch(
      id: 'main_milk_b1',
      stockItemId: 'main_milk',
      branchId: 'main',
      onHand: 1800,
      receivedDate: '2024-05-01',
      expiryDate: '2024-05-15',
    ),
    StockBatch(
      id: 'main_milk_b2',
      stockItemId: 'main_milk',
      branchId: 'main',
      onHand: 1800,
      receivedDate: '2024-05-10',
      expiryDate: '2024-05-30',
    ),
    StockBatch(
      id: 'main_beans_b1',
      stockItemId: 'main_beans',
      branchId: 'main',
      onHand: 1300,
      receivedDate: '2024-05-05',
      expiryDate: null,
    ),
    StockBatch(
      id: 'main_beans_b2',
      stockItemId: 'main_beans',
      branchId: 'main',
      onHand: 1300,
      receivedDate: '2024-05-12',
      expiryDate: null,
    ),
    StockBatch(
      id: 'main_sugar_b1',
      stockItemId: 'main_sugar',
      branchId: 'main',
      onHand: 2700,
      receivedDate: '2024-05-14',
      expiryDate: '2024-08-10',
    ),
    StockBatch(
      id: 'main_sugar_b2',
      stockItemId: 'main_sugar',
      branchId: 'main',
      onHand: 2700,
      receivedDate: '2024-05-20',
      expiryDate: '2024-09-01',
    ),
    StockBatch(
      id: 'dt_milk_b1',
      stockItemId: 'dt_milk',
      branchId: 'downtown',
      onHand: 1200,
      receivedDate: '2024-05-08',
      expiryDate: '2024-05-20',
    ),
    StockBatch(
      id: 'dt_milk_b2',
      stockItemId: 'dt_milk',
      branchId: 'downtown',
      onHand: 1200,
      receivedDate: '2024-05-16',
      expiryDate: '2024-05-28',
    ),
    StockBatch(
      id: 'ap_milk_b1',
      stockItemId: 'ap_milk',
      branchId: 'airport',
      onHand: 900,
      receivedDate: '2024-05-10',
      expiryDate: '2024-05-22',
    ),
    StockBatch(
      id: 'ap_milk_b2',
      stockItemId: 'ap_milk',
      branchId: 'airport',
      onHand: 800,
      receivedDate: '2024-05-18',
      expiryDate: '2024-05-29',
    ),
  ];

  final List<InventoryCategory> _categories = [
    const InventoryCategory(id: 'cat_dairy', name: 'Dairy', isActive: true),
    const InventoryCategory(id: 'cat_packaging', name: 'Packaging', isActive: true),
    const InventoryCategory(id: 'cat_produce', name: 'Produce', isActive: true),
    const InventoryCategory(id: 'cat_sweet', name: 'Sweetener', isActive: true),
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
    _batches.removeWhere((batch) => batch.stockItemId == id);
  }

  String _generateId() =>
      'stock_${DateTime.now().microsecondsSinceEpoch.toString()}';

  Future<List<StockBatch>> fetchBatches() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_batches);
  }

  Future<StockBatch> createBatch(StockBatch batch) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final newBatch = batch.copyWith(id: _generateBatchId());
    _batches.add(newBatch);
    return newBatch;
  }

  Future<StockBatch> updateBatch(StockBatch batch) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final index = _batches.indexWhere((element) => element.id == batch.id);
    if (index == -1) {
      throw StateError('Batch ${batch.id} not found');
    }
    _batches[index] = batch;
    if (batch.onHand <= 0) {
      _batches.removeAt(index);
    }
    return batch;
  }

  Future<void> deleteBatch(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _batches.removeWhere((element) => element.id == id);
  }

  String _generateBatchId() => 'batch_${DateTime.now().microsecondsSinceEpoch}';

  Future<List<InventoryCategory>> fetchCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_categories);
  }

  Future<InventoryCategory> createCategory(InventoryCategory category) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final newCategory = category.copyWith(id: _generateCategoryId());
    _categories.add(newCategory);
    return newCategory;
  }

  Future<InventoryCategory> updateCategory(InventoryCategory category) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final index = _categories.indexWhere((element) => element.id == category.id);
    if (index == -1) throw StateError('Category ${category.id} not found');
    _categories[index] = category;
    return category;
  }

  Future<void> deleteCategory(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _categories.removeWhere((element) => element.id == id);
  }

  String _generateCategoryId() =>
      'cat_${DateTime.now().microsecondsSinceEpoch.toString()}';
}
