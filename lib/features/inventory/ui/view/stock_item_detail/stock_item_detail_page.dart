import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/inventory/domain/models/stock_item.dart';
import 'package:modular_pos/features/inventory/ui/components/stock_item_form.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';

class StockItemDetailPage extends ConsumerStatefulWidget {
  const StockItemDetailPage({super.key, required this.item});

  final StockItem item;

  @override
  ConsumerState<StockItemDetailPage> createState() =>
      _StockItemDetailPageState();
}

class _StockItemDetailPageState extends ConsumerState<StockItemDetailPage> {
  late StockItem _item;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDetail();
    });
  }

  Future<void> _refreshDetail() async {
    if (_item.id.isEmpty || _item.id == 'unknown') return;
    setState(() => _isRefreshing = true);
    try {
      final fresh = await ref
          .read(stockInventoryControllerProvider.notifier)
          .loadStockItemDetail(_item.id);
      if (!mounted) return;
      setState(() => _item = fresh);
    } catch (_) {
      // Controller already stores mapped error state; keep current UI item fallback.
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StockItemFormPage(mode: StockItemFormMode.view, item: _item),
        if (_isRefreshing)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
