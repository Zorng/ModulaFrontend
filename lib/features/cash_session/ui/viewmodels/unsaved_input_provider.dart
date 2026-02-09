import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which forms have unsaved input
class UnsavedInputState {
  const UnsavedInputState({
    this.hasUnsavedStartSession = false,
    this.hasUnsavedCashMovement = false,
    this.hasUnsavedCloseSession = false,
  });

  final bool hasUnsavedStartSession;
  final bool hasUnsavedCashMovement;
  final bool hasUnsavedCloseSession;

  /// Returns true if any form has unsaved data
  bool get hasAnyUnsavedData =>
      hasUnsavedStartSession || hasUnsavedCashMovement || hasUnsavedCloseSession;

  UnsavedInputState copyWith({
    bool? hasUnsavedStartSession,
    bool? hasUnsavedCashMovement,
    bool? hasUnsavedCloseSession,
  }) {
    return UnsavedInputState(
      hasUnsavedStartSession: hasUnsavedStartSession ?? this.hasUnsavedStartSession,
      hasUnsavedCashMovement: hasUnsavedCashMovement ?? this.hasUnsavedCashMovement,
      hasUnsavedCloseSession: hasUnsavedCloseSession ?? this.hasUnsavedCloseSession,
    );
  }
}

/// Notifier for tracking unsaved input across the cash session feature
class UnsavedInputNotifier extends Notifier<UnsavedInputState> {
  @override
  UnsavedInputState build() {
    return const UnsavedInputState();
  }

  void markStartSessionUnsaved(bool hasUnsaved) {
    state = state.copyWith(hasUnsavedStartSession: hasUnsaved);
  }

  void markCashMovementUnsaved(bool hasUnsaved) {
    state = state.copyWith(hasUnsavedCashMovement: hasUnsaved);
  }

  void markCloseSessionUnsaved(bool hasUnsaved) {
    state = state.copyWith(hasUnsavedCloseSession: hasUnsaved);
  }

  void clearAll() {
    state = const UnsavedInputState();
  }
}

/// Provider for unsaved input tracking
final unsavedInputProvider = NotifierProvider<UnsavedInputNotifier, UnsavedInputState>(
  UnsavedInputNotifier.new,
);
