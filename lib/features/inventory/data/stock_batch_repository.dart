import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/data/stock_item_api.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_batch.dart';

final stockBatchRepositoryProvider = Provider<StockBatchRepository>((ref) {
  final api = ref.watch(stockItemApiProvider);
  return StockBatchRepository(api);
});

class StockBatchRepository {
  const StockBatchRepository(this._api);

  final StockItemApi _api;

  Future<List<StockBatch>> fetchBatches() => _api.fetchBatches();

  Future<StockBatch> createBatch(StockBatch batch) => _api.createBatch(batch);

  Future<StockBatch> updateBatch(StockBatch batch) => _api.updateBatch(batch);

  Future<void> deleteBatch(String id) => _api.deleteBatch(id);
}
