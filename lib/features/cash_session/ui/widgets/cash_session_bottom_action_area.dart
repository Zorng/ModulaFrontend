import 'package:flutter/material.dart';

/// A persistent bottom area for displaying the primary cash session action
/// (e.g., "Start Session" or "Close Session").
class CashSessionBottomActionArea extends StatelessWidget {
  const CashSessionBottomActionArea({
    super.key,
    required this.isSessionOpen,
    required this.onPressed,
    this.message,
  });

  /// Determines the text of the button ('Start Session' or 'Close Session').
  final bool isSessionOpen;

  /// The callback that is executed when the button is pressed.
  final VoidCallback? onPressed;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        // Simulates the top border of a modal bottom sheet
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(
                onPressed == null
                    ? 'Session Closed'
                    : (isSessionOpen ? 'Close Session' : 'Start Session'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'Manage your cash session for the selected register.',
            style: const TextStyle(fontSize: 12, color: Color(0xB2393838)),
          ),
        ],
      ),
    );
  }
}
