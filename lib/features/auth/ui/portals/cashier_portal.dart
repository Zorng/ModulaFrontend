import 'package:flutter/material.dart';

class CashierPortal extends StatelessWidget {
  const CashierPortal({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Cashier Portal',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
