import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart';

class SaleCartPage extends ConsumerStatefulWidget {
  const SaleCartPage({super.key});

  @override
  ConsumerState<SaleCartPage> createState() => _SaleCartPageState();
}

class _SaleCartPageState extends ConsumerState<SaleCartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SaleCartPanel(),
    );
  }
}
