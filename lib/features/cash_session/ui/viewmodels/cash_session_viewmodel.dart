import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';

/// Enum to represent the distinct states of a cash session.
enum SessionStatus { notStarted, open, closed }

/// An immutable class that holds the state for a cash session.
class CashSessionState {
  const CashSessionState({
    this.sessionStatus = SessionStatus.notStarted,
    this.startTime,
    this.endTime,
    this.openFloatUsd = '0.00',
    this.openFloatKhr = '0.00',
    this.totalPaidIn = 0.0,
    this.totalPaidOut = 0.0,
    this.hasCashMovement = false,
  });

  final SessionStatus sessionStatus;
  final DateTime? startTime;
  final DateTime? endTime;
  final String openFloatUsd;
  final String openFloatKhr;
  final double totalPaidIn;
  final double totalPaidOut;
  final bool hasCashMovement;

  /// Creates a copy of the state with the given fields replaced with the new values.
  CashSessionState copyWith({
    SessionStatus? sessionStatus,
    DateTime? startTime,
    DateTime? endTime,
    String? openFloatUsd,
    String? openFloatKhr,
    double? totalPaidIn,
    double? totalPaidOut,
    bool? hasCashMovement,
  }) {
    return CashSessionState(
      sessionStatus: sessionStatus ?? this.sessionStatus,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      openFloatUsd: openFloatUsd ?? this.openFloatUsd,
      openFloatKhr: openFloatKhr ?? this.openFloatKhr,
      totalPaidIn: totalPaidIn ?? this.totalPaidIn,
      totalPaidOut: totalPaidOut ?? this.totalPaidOut,
      hasCashMovement: hasCashMovement ?? this.hasCashMovement,
    );
  }
}

/// The ViewModel that holds the business logic for managing the cash session state.
class CashSessionViewModel extends Notifier<CashSessionState> {
  @override
  CashSessionState build() {
    // This method is required by Notifier and is used to create the initial state.
    return const CashSessionState();
  }

  /// Starts a new session and resets all relevant state values.
  void startSession(String usdAmount, String khrAmount) {
    state = state.copyWith(
      sessionStatus: SessionStatus.open,
      startTime: DateTime.now(),
      openFloatUsd: usdAmount,
      openFloatKhr: khrAmount,
      // Reset values for the new session
      endTime: null,
      hasCashMovement: false,
      totalPaidIn: 0.0,
      totalPaidOut: 0.0,
    );
  }

  /// Adds a cash movement, converting KHR to USD and updating totals.
  void addCashMovement(String type, double usdAmount, double khrAmount) {
    // Define a conversion rate. This should ideally come from a config or remote source.
    const khrToUsdRate = 4000;
    final khrInUsd = khrAmount / khrToUsdRate;
    final totalMovementInUsd = usdAmount + khrInUsd;

    if (type == 'Paid In') {
      state = state.copyWith(
        totalPaidIn: state.totalPaidIn + totalMovementInUsd,
        hasCashMovement: true,
      );
    } else {
      state = state.copyWith(
        totalPaidOut: state.totalPaidOut + totalMovementInUsd,
        hasCashMovement: true,
      );
    }
  }

  /// Closes the current session, setting the status and end time.
  void closeSession() {
    state = state.copyWith(
      sessionStatus: SessionStatus.closed,
      endTime: DateTime.now(),
    );
  }
}

/// The global provider for accessing the CashSessionViewModel.
final cashSessionViewModelProvider =
    NotifierProvider<CashSessionViewModel, CashSessionState>(
  CashSessionViewModel.new,
);