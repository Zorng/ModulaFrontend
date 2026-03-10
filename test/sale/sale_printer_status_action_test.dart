import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/printing/thermal_printer_controller.dart';
import 'package:modular_pos/core/printing/thermal_printer_state.dart';
import 'package:modular_pos/features/sale/ui/view/sale_shell/widgets/sale_printer_status_action.dart';

import '../test_utils/pump_app.dart';

class _StaticThermalPrinterController extends ThermalPrinterController {
  _StaticThermalPrinterController(this._state);

  final ThermalPrinterState _state;

  @override
  ThermalPrinterState build() => _state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows printer dialog from sale app bar action', (tester) async {
    await pumpApp(
      tester,
      Scaffold(appBar: AppBar(actions: const [SalePrinterStatusAction()])),
      overrides: [
        thermalPrinterControllerProvider.overrideWith(
          () => _StaticThermalPrinterController(
            const ThermalPrinterState(status: ThermalPrinterStatus.unsupported),
          ),
        ),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('sale_printer_status_action')));
    await tester.pumpAndSettle();

    expect(find.text('Receipt printer'), findsOneWidget);
    expect(find.text('Model: BT-583 58mm'), findsOneWidget);
    expect(find.text('Status: Unsupported browser'), findsOneWidget);
    expect(find.textContaining('Chrome'), findsOneWidget);
  });
}
