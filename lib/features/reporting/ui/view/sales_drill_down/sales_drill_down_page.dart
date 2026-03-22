import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/reporting/ui/models/sales_drill_down_route_args.dart';

class SalesDrillDownPage extends StatelessWidget {
  const SalesDrillDownPage({super.key, required this.args});

  final SalesDrillDownRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const AppBackButton(),
        title: const Text('Sales Details'),
      ),
      body: const Center(child: Text('Empty')),
    );
  }
}
