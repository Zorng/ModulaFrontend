import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/theme/app_buttons.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/modal_form_state_provider.dart';
import 'package:modular_pos/features/cash_session/ui/viewmodels/unsaved_input_provider.dart';

/// Card for starting a cash session with three states:
/// 1. No scheduled shift - needs request
/// 2. Request pending - waiting for approval
/// 3. Approved to start - can start session
class StartSessionCard extends ConsumerStatefulWidget {
  const StartSessionCard({
    super.key,
    required this.onSessionStarted,
    required this.onRequestSession,
    this.sessionRequestStatus = SessionRequestStatus.noShift,
  });

  final void Function(double usdAmount, double khrAmount, String note)
  onSessionStarted;
  final VoidCallback onRequestSession;
  final SessionRequestStatus sessionRequestStatus;

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
    ref.read(startSessionFormProvider.notifier).updateUsdAmount(_usdController.text);
    _updateUnsavedStatus();
  }

  void _onKhrChanged() {
    ref.read(startSessionFormProvider.notifier).updateKhrAmount(_khrController.text);
    _updateUnsavedStatus();
  }

  void _onNoteChanged() {
    ref.read(startSessionFormProvider.notifier).updateNote(_noteController.text);
    _updateUnsavedStatus();
  }

  void _updateUnsavedStatus() {
    final hasData = _usdController.text.isNotEmpty ||
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

    final isApproved =
        widget.sessionRequestStatus == SessionRequestStatus.approved;
    final isPending =
        widget.sessionRequestStatus == SessionRequestStatus.pending;
    final isNoShift =
        widget.sessionRequestStatus == SessionRequestStatus.noShift;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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

            // Status Banner
            _buildStatusBanner(textTheme, colorScheme),

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
              enabled: isApproved,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                filled: true,
                fillColor: isApproved ? Colors.white : const Color(0xFFF7F7F7),
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
                    color: colorScheme.outlineVariant.withOpacity(0.38),
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
              enabled: isApproved,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                filled: true,
                fillColor: isApproved ? Colors.white : const Color(0xFFF7F7F7),
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
                    color: colorScheme.outlineVariant.withOpacity(0.38),
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
              enabled: isApproved,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter note',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                filled: true,
                fillColor: isApproved ? Colors.white : const Color(0xFFF7F7F7),
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
                    color: colorScheme.outlineVariant.withOpacity(0.38),
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
                onPressed: isApproved
                    ? () {
                        final usdText = _usdController.text.trim();
                        final khrText = _khrController.text.trim();
                        
                        // Validate: at least one field must have a valid value
                        final usd = double.tryParse(usdText);
                        final khr = double.tryParse(khrText);
                        
                        if (usd == null && khr == null) {
                          // Both fields are empty or invalid
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid opening float for at least one currency (USD or KHR)'),
                              backgroundColor: Color(0xFFED533C),
                            ),
                          );
                          return;
                        }
                        
                        // Use 0.0 as default for empty fields
                        final finalUsd = usd ?? 0.0;
                        final finalKhr = khr ?? 0.0;
                        final note = _noteController.text;
                        
                        // Clear form state and unsaved status
                        ref.read(startSessionFormProvider.notifier).clear();
                        ref.read(unsavedInputProvider.notifier).markStartSessionUnsaved(false);
                        
                        widget.onSessionStarted(finalUsd, finalKhr, note);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: isApproved
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFFED533C).withOpacity(0.1),
                  foregroundColor: isApproved
                      ? Theme.of(context).colorScheme.onPrimary
                      : const Color(0xFFED533C).withOpacity(0.4),
                  disabledBackgroundColor: const Color(0xFFED533C).withOpacity(0.1),
                  disabledForegroundColor: const Color(0xFFED533C).withOpacity(0.4),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),

                child: const Text('Start Cash Session'),
              ),
            ),

            // Request Button (only show when not approved)
            if (!isApproved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isNoShift ? widget.onRequestSession : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isPending
                        ? colorScheme.onSurfaceVariant.withOpacity(0.6)
                        : colorScheme.primary,
                    side: BorderSide(
                      color: isPending
                          ? colorScheme.outlineVariant.withOpacity(0.6)
                          : colorScheme.primary,
                      width: 1,
                    ),
                    backgroundColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPending)
                        Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      if (isPending) const SizedBox(width: 8),
                      if (isNoShift)
                        Icon(
                          Icons.send_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      if (isNoShift) const SizedBox(width: 8),
                      Text(
                        isPending
                            ? 'Request Sent'
                            : 'Request to Open Cash Session',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(TextTheme textTheme, ColorScheme colorScheme) {
    final status = widget.sessionRequestStatus;

    final Map<SessionRequestStatus, Map<String, dynamic>> statusConfig = {
      SessionRequestStatus.noShift: {
        'icon': Icons.schedule_outlined,
        'title': 'No scheduled shift',
        'message': 'Send a request to open the cash session',
        'bgColor': const Color(0xFFFFF5F2),
        'iconColor': const Color(0xFFED533C),
        'titleColor': const Color(0xFFED533C),
      },
      SessionRequestStatus.pending: {
        'icon': Icons.pending_outlined,
        'title': 'Request Pending',
        'message': 'Waiting for admin approval to open cash session.',
        'bgColor': const Color(0xFFFFF7ED),
        'iconColor': const Color(0xFFF59E0B),
        'titleColor': const Color(0xFFF59E0B),
      },
      SessionRequestStatus.approved: {
        'icon': Icons.check_circle_outline,
        'title': 'Approved to Start',
        'message': 'You can now start the cash session.',
        'bgColor': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
        'titleColor': const Color(0xFF10B981),
      },
    };

    final config = statusConfig[status]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (config['iconColor'] as Color).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(config['icon'], size: 20, color: config['iconColor']),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config['title'],
                  style: textTheme.labelLarge?.copyWith(
                    color: config['titleColor'],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config['message'],
                  style: textTheme.bodySmall?.copyWith(
                    color: (config['iconColor'] as Color).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum SessionRequestStatus { noShift, pending, approved }
