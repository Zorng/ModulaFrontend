import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the Start Session form
class StartSessionFormState {
  const StartSessionFormState({
    this.usdAmount = '',
    this.khrAmount = '',
    this.note = '',
  });

  final String usdAmount;
  final String khrAmount;
  final String note;

  bool get hasAnyData =>
      usdAmount.isNotEmpty || khrAmount.isNotEmpty || note.isNotEmpty;

  StartSessionFormState copyWith({
    String? usdAmount,
    String? khrAmount,
    String? note,
  }) {
    return StartSessionFormState(
      usdAmount: usdAmount ?? this.usdAmount,
      khrAmount: khrAmount ?? this.khrAmount,
      note: note ?? this.note,
    );
  }
}

/// State for the Cash Movement form
class CashMovementFormState {
  const CashMovementFormState({
    this.type = 'Paid In',
    this.usdAmount = '',
    this.khrAmount = '',
    this.reason = '',
  });

  final String type;
  final String usdAmount;
  final String khrAmount;
  final String reason;

  bool get hasAnyData =>
      usdAmount.isNotEmpty || khrAmount.isNotEmpty || reason.isNotEmpty;

  CashMovementFormState copyWith({
    String? type,
    String? usdAmount,
    String? khrAmount,
    String? reason,
  }) {
    return CashMovementFormState(
      type: type ?? this.type,
      usdAmount: usdAmount ?? this.usdAmount,
      khrAmount: khrAmount ?? this.khrAmount,
      reason: reason ?? this.reason,
    );
  }
}

/// State for the Close Session form
class CloseSessionFormState {
  const CloseSessionFormState({
    this.usdAmount = '',
    this.khrAmount = '',
    this.note = '',
  });

  final String usdAmount;
  final String khrAmount;
  final String note;

  bool get hasAnyData =>
      usdAmount.isNotEmpty || khrAmount.isNotEmpty || note.isNotEmpty;

  CloseSessionFormState copyWith({
    String? usdAmount,
    String? khrAmount,
    String? note,
  }) {
    return CloseSessionFormState(
      usdAmount: usdAmount ?? this.usdAmount,
      khrAmount: khrAmount ?? this.khrAmount,
      note: note ?? this.note,
    );
  }
}

/// Notifiers for each form
class StartSessionFormNotifier extends Notifier<StartSessionFormState> {
  @override
  StartSessionFormState build() => const StartSessionFormState();

  void updateUsdAmount(String value) {
    state = state.copyWith(usdAmount: value);
  }

  void updateKhrAmount(String value) {
    state = state.copyWith(khrAmount: value);
  }

  void updateNote(String value) {
    state = state.copyWith(note: value);
  }

  void clear() {
    state = const StartSessionFormState();
  }
}

class CashMovementFormNotifier extends Notifier<CashMovementFormState> {
  @override
  CashMovementFormState build() => const CashMovementFormState();

  void updateType(String value) {
    state = state.copyWith(type: value);
  }

  void updateUsdAmount(String value) {
    state = state.copyWith(usdAmount: value);
  }

  void updateKhrAmount(String value) {
    state = state.copyWith(khrAmount: value);
  }

  void updateReason(String value) {
    state = state.copyWith(reason: value);
  }

  void clear() {
    state = const CashMovementFormState();
  }
}

class CloseSessionFormNotifier extends Notifier<CloseSessionFormState> {
  @override
  CloseSessionFormState build() => const CloseSessionFormState();

  void updateUsdAmount(String value) {
    state = state.copyWith(usdAmount: value);
  }

  void updateKhrAmount(String value) {
    state = state.copyWith(khrAmount: value);
  }

  void updateNote(String value) {
    state = state.copyWith(note: value);
  }

  void clear() {
    state = const CloseSessionFormState();
  }
}

/// Providers for form state
final startSessionFormProvider =
    NotifierProvider<StartSessionFormNotifier, StartSessionFormState>(
  StartSessionFormNotifier.new,
);

final cashMovementFormProvider =
    NotifierProvider<CashMovementFormNotifier, CashMovementFormState>(
  CashMovementFormNotifier.new,
);

final closeSessionFormProvider =
    NotifierProvider<CloseSessionFormNotifier, CloseSessionFormState>(
  CloseSessionFormNotifier.new,
);
