import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/printing/thermal_printer_controller.dart';
import 'package:modular_pos/core/printing/thermal_printer_profiles.dart';
import 'package:modular_pos/core/printing/thermal_printer_state.dart';

class SalePrinterStatusAction extends ConsumerWidget {
  const SalePrinterStatusAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printerState = ref.watch(thermalPrinterControllerProvider);
    return IconButton(
      key: const ValueKey('sale_printer_status_action'),
      tooltip: _tooltipFor(printerState),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => const _SalePrinterStatusDialog(),
      ),
      icon: _iconFor(printerState),
    );
  }

  String _tooltipFor(ThermalPrinterState state) {
    switch (state.status) {
      case ThermalPrinterStatus.connected:
        return state.printerLabel?.trim().isNotEmpty == true
            ? 'Printer connected: ${state.printerLabel}'
            : 'Printer connected';
      case ThermalPrinterStatus.printing:
        return 'Printing receipt';
      case ThermalPrinterStatus.unsupported:
        return 'Printer setup is unavailable in this browser';
      case ThermalPrinterStatus.error:
        return state.lastErrorMessage ?? 'Printer error';
      case ThermalPrinterStatus.requestingPermission:
        return 'Waiting for printer permission';
      case ThermalPrinterStatus.connecting:
        return 'Connecting to printer';
      case ThermalPrinterStatus.disconnected:
        return 'Connect printer';
    }
  }

  Widget _iconFor(ThermalPrinterState state) {
    switch (state.status) {
      case ThermalPrinterStatus.connected:
        return const Icon(Icons.print, color: Colors.green);
      case ThermalPrinterStatus.printing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ThermalPrinterStatus.unsupported:
        return const Icon(Icons.print_disabled_outlined, color: Colors.orange);
      case ThermalPrinterStatus.error:
        return const Icon(Icons.print_outlined, color: Colors.red);
      case ThermalPrinterStatus.requestingPermission:
      case ThermalPrinterStatus.connecting:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ThermalPrinterStatus.disconnected:
        return const Icon(Icons.print_outlined);
    }
  }
}

class _SalePrinterStatusDialog extends ConsumerWidget {
  const _SalePrinterStatusDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printerState = ref.watch(thermalPrinterControllerProvider);
    final controller = ref.read(thermalPrinterControllerProvider.notifier);
    final showEventMessage =
        printerState.lastEventMessage?.trim().isNotEmpty == true &&
        (!printerState.lastEventIsError ||
            printerState.lastEventMessage != printerState.lastErrorMessage);

    return AlertDialog(
      title: const Text('Receipt printer'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: ${ThermalPrinterProfiles.bt58358mm.label}'),
            const SizedBox(height: 4),
            const Text('Paper: 58mm'),
            const SizedBox(height: 12),
            Text('Status: ${printerState.statusLabel}'),
            if (printerState.printerLabel?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text('Device: ${printerState.printerLabel}'),
            ],
            if (printerState.lastPrintedReceiptNumber?.trim().isNotEmpty ==
                true) ...[
              const SizedBox(height: 4),
              Text('Last receipt: ${printerState.lastPrintedReceiptNumber}'),
            ],
            if (showEventMessage) ...[
              const SizedBox(height: 12),
              Text(
                printerState.lastEventMessage!,
                style: TextStyle(
                  color: printerState.lastEventIsError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            if (printerState.lastErrorMessage?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                printerState.lastErrorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (printerState.status == ThermalPrinterStatus.unsupported) ...[
              const SizedBox(height: 12),
              const Text(
                'Open the sale app in Chrome or another supported Chromium browser to use Web Serial.',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        OutlinedButton(
          onPressed: printerState.isConnected && !printerState.isBusy
              ? () {
                  controller.printTestPage();
                }
              : null,
          child: const Text('Test print'),
        ),
        FilledButton(
          onPressed: printerState.status == ThermalPrinterStatus.unsupported
              ? null
              : printerState.isConnected
              ? () {
                  controller.disconnect();
                }
              : (printerState.isBusy
                    ? null
                    : () {
                        controller.connect();
                      }),
          child: Text(
            printerState.isConnected ? 'Disconnect' : 'Connect printer',
          ),
        ),
      ],
    );
  }
}
