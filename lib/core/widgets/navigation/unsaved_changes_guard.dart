import 'package:flutter/material.dart';

class UnsavedChangesGuard extends StatefulWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.isDirty,
    required this.child,
    this.title = 'Discard changes?',
    this.message = 'You have unsaved changes. Are you sure you want to leave?',
    this.discardLabel = 'Discard',
    this.stayLabel = 'Cancel',
    this.onDiscard,
  });

  final bool isDirty;
  final Widget child;
  final String title;
  final String message;
  final String discardLabel;
  final String stayLabel;
  final VoidCallback? onDiscard;

  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  bool _handlingPop = false;

  Future<void> _confirmDiscard() async {
    if (_handlingPop) return;
    _handlingPop = true;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(widget.title),
            content: Text(widget.message),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFED533C),
                      ),
                      child: Text(widget.stayLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(widget.discardLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
    _handlingPop = false;
    if (shouldDiscard == true && mounted) {
      widget.onDiscard?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !widget.isDirty) return;
        _confirmDiscard();
      },
      child: widget.child,
    );
  }
}
