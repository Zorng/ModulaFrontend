import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/cash_session_viewmodel.dart';
import 'package:modular_pos/features/cash_session/ui/widgets/force_close_session_modal.dart';
import 'package:modular_pos/features/sale/ui/viewmodels/sale_cart_viewmodel.dart';

class SessionActionCard extends ConsumerStatefulWidget {
  const SessionActionCard({
    super.key,
    required this.sessionState,
    required this.notifier,
  });

  final CashSessionState sessionState;
  final CashSessionViewModel notifier;

  @override
  ConsumerState<SessionActionCard> createState() => _SessionActionCardState();
}

class _SessionActionCardState extends ConsumerState<SessionActionCard> {
  final _usdController = TextEditingController();
  final _khrController = TextEditingController();
  final _noteController = TextEditingController();

  _SessionActionMode get _mode {
    final state = widget.sessionState;
    if (state.hasOpenSession && state.isOwnedByCurrentUser) {
      return _SessionActionMode.close;
    }
    if (state.hasOpenSession && state.isOccupiedByAnotherUser) {
      return _SessionActionMode.occupied;
    }
    return _SessionActionMode.start;
  }

  @override
  void didUpdateWidget(covariant SessionActionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mode != _modeForState(oldWidget.sessionState)) {
      _clearInputs();
    }
  }

  @override
  void dispose() {
    _usdController.dispose();
    _khrController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = _mode;
    final theme = Theme.of(context);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Action',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitle(mode),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            switch (mode) {
              _SessionActionMode.start => _buildStartForm(context),
              _SessionActionMode.close => _buildCloseForm(context),
              _SessionActionMode.occupied => _buildOccupiedState(context),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildStartForm(BuildContext context) {
    return Column(
      children: [
        _currencyField(
          label: 'Opening Float (USD)',
          controller: _usdController,
        ),
        const SizedBox(height: 12),
        _currencyField(
          label: 'Opening Float (KHR)',
          controller: _khrController,
        ),
        const SizedBox(height: 12),
        _noteField(
          label: 'Note (Optional)',
          hintText: 'Add any opening context',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.sessionState.isLoading ? null : _submitStart,
            child: const Text('Start Session'),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseForm(BuildContext context) {
    return Column(
      children: [
        _currencyField(
          label: 'Counted Cash (USD)',
          controller: _usdController,
        ),
        const SizedBox(height: 12),
        _currencyField(
          label: 'Counted Cash (KHR)',
          controller: _khrController,
        ),
        const SizedBox(height: 12),
        _noteField(
          label: 'Note (Optional)',
          hintText: 'Add any closing context',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.sessionState.isLoading ? null : _submitClose,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFED533C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Session'),
          ),
        ),
        if (widget.sessionState.canForceClose) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.sessionState.isLoading
                  ? null
                  : () => _openForceCloseModal(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB45309),
                side: const BorderSide(color: Color(0xFFB45309)),
              ),
              child: const Text('Force Close Session'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOccupiedState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Text(
            widget.sessionState.canForceClose
                ? 'This session is occupied by another account. You can still force close it if needed.'
                : 'This session is occupied by another account. No action is available for you right now.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9A3412),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (widget.sessionState.canForceClose) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.sessionState.isLoading
                  ? null
                  : () => _openForceCloseModal(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB45309),
                side: const BorderSide(color: Color(0xFFB45309)),
              ),
              child: const Text('Force Close Session'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _currencyField({
    required String label,
    required TextEditingController controller,
  }) {
    return _fieldShell(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _decoration(),
      ),
    );
  }

  Widget _noteField({required String label, required String hintText}) {
    return _fieldShell(
      label: label,
      child: TextField(
        controller: _noteController,
        maxLines: 3,
        decoration: _decoration(hintText: hintText),
      ),
    );
  }

  Widget _fieldShell({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _decoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFFED533C), width: 1.5),
      ),
    );
  }

  String _subtitle(_SessionActionMode mode) {
    return switch (mode) {
      _SessionActionMode.start =>
        'Open a new branch cash session with opening float.',
      _SessionActionMode.close =>
        'Provide counted cash to close your active session.',
      _SessionActionMode.occupied =>
        'This card stays available even when the session belongs to another user.',
    };
  }

  void _submitStart() {
    final usd = double.tryParse(_usdController.text.trim());
    final khr = double.tryParse(_khrController.text.trim());
    if (usd == null && khr == null) {
      _showSnack(
        'Please enter a valid opening float for at least one currency (USD or KHR).',
      );
      return;
    }

    widget.notifier.startSession(
      usdAmount: usd ?? 0,
      khrAmount: khr ?? 0,
      note: _noteController.text.trim(),
    );
    _clearInputs();
  }

  Future<void> _submitClose() async {
    final usd = double.tryParse(_usdController.text.trim());
    final khr = double.tryParse(_khrController.text.trim());
    if (usd == null && khr == null) {
      _showSnack(
        'Please enter a valid closing float for at least one currency (USD or KHR).',
      );
      return;
    }

    final cartState = ref.read(saleCartProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Session Closure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('USD counted: ${(usd ?? 0).toStringAsFixed(2)}'),
              Text('KHR counted: ${(khr ?? 0).toStringAsFixed(0)}'),
              if (_noteController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note: ${_noteController.text.trim()}'),
              ],
              if (cartState.lines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'You still have ${cartState.lines.length} cart item(s). They will be cleared if you continue.',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFED533C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (cartState.lines.isNotEmpty) {
      ref.read(saleCartProvider.notifier).clear();
    }

    widget.notifier.closeSession(
      countedUsd: usd ?? 0,
      countedKhr: khr ?? 0,
      note: _noteController.text.trim(),
    );
    _clearInputs();
  }

  void _openForceCloseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) {
        return ForceCloseSessionModal(
          onForceClosed: (usd, khr, reason, note) {
            Navigator.of(modalContext).pop();
            widget.notifier.forceCloseSession(
              countedUsd: usd,
              countedKhr: khr,
              reason: reason,
              note: note,
            );
          },
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFED533C),
      ),
    );
  }

  void _clearInputs() {
    _usdController.clear();
    _khrController.clear();
    _noteController.clear();
  }

  _SessionActionMode _modeForState(CashSessionState state) {
    if (state.hasOpenSession && state.isOwnedByCurrentUser) {
      return _SessionActionMode.close;
    }
    if (state.hasOpenSession && state.isOccupiedByAnotherUser) {
      return _SessionActionMode.occupied;
    }
    return _SessionActionMode.start;
  }
}

enum _SessionActionMode { start, close, occupied }
