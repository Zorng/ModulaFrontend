import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/modal_form_state_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/unsaved_input_provider.dart';

/// Card for starting a branch-scoped cash session with the contract fields only.
class StartSessionCard extends ConsumerStatefulWidget {
  const StartSessionCard({super.key, required this.onSessionStarted});

  final void Function(double usdAmount, double khrAmount, String note)
  onSessionStarted;

  @override
  ConsumerState<StartSessionCard> createState() => _StartSessionCardState();
}

class _StartSessionCardState extends ConsumerState<StartSessionCard> {
  final _usdController = TextEditingController();
  final _khrController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Restore saved form state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref.read(startSessionFormProvider);
      _usdController.text = formState.usdAmount;
      _khrController.text = formState.khrAmount;
      _noteController.text = formState.note;
    });

    // Listen to changes and update state
    _usdController.addListener(_onUsdChanged);
    _khrController.addListener(_onKhrChanged);
    _noteController.addListener(_onNoteChanged);
  }

  void _onUsdChanged() {
    ref
        .read(startSessionFormProvider.notifier)
        .updateUsdAmount(_usdController.text);
    _updateUnsavedStatus();
  }

  void _onKhrChanged() {
    ref
        .read(startSessionFormProvider.notifier)
        .updateKhrAmount(_khrController.text);
    _updateUnsavedStatus();
  }

  void _onNoteChanged() {
    ref
        .read(startSessionFormProvider.notifier)
        .updateNote(_noteController.text);
    _updateUnsavedStatus();
  }

  void _updateUnsavedStatus() {
    final hasData =
        _usdController.text.isNotEmpty ||
        _khrController.text.isNotEmpty ||
        _noteController.text.isNotEmpty;
    ref.read(unsavedInputProvider.notifier).markStartSessionUnsaved(hasData);
  }

  @override
  void dispose() {
    _usdController.removeListener(_onUsdChanged);
    _khrController.removeListener(_onKhrChanged);
    _noteController.removeListener(_onNoteChanged);
    _usdController.dispose();
    _khrController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start Session',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Opening Float (USD)
            Text(
              'Opening Float (USD)',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usdController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Opening Float (KHR)
            Text(
              'Opening Float (KHR)',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _khrController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note (Optional)
            Text(
              'Note (Optional)',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter note',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start Cash Session Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final usdText = _usdController.text.trim();
                  final khrText = _khrController.text.trim();

                  final usd = double.tryParse(usdText);
                  final khr = double.tryParse(khrText);

                  if (usd == null && khr == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid opening float for at least one currency (USD or KHR)',
                        ),
                        backgroundColor: Color(0xFFED533C),
                      ),
                    );
                    return;
                  }

                  final finalUsd = usd ?? 0.0;
                  final finalKhr = khr ?? 0.0;
                  final note = _noteController.text;

                  ref.read(startSessionFormProvider.notifier).clear();
                  ref
                      .read(unsavedInputProvider.notifier)
                      .markStartSessionUnsaved(false);

                  widget.onSessionStarted(finalUsd, finalKhr, note);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                  ),
                ),

                child: const Text('Start Cash Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
