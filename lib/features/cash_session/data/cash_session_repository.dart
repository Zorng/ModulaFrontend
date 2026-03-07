import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_api.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_movement_repository.dart';
import 'package:modular_pos/features/cash_session/data/mock_cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/remote_cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session.dart';

abstract class CashSessionRepository {
  Future<CashSession> openSession({
    required double openingFloatUsd,
    required double openingFloatKhr,
    String? note,
  });

  Future<CashSession?> getActiveSession();

  Future<CashSession> closeSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    String? note,
  });

  Future<CashSession> forceCloseSession({
    required String sessionId,
    required double countedCashUsd,
    required double countedCashKhr,
    required String reason,
    String? note,
  });
}

class UseMockCashSessionNotifier extends Notifier<bool> {
  @override
  bool build() => AppEnv.useMockCashSessionRepository;

  void toggle() => state = !state;
  void setMock(bool useMock) => state = useMock;
}

final useMockCashSessionProvider =
    NotifierProvider<UseMockCashSessionNotifier, bool>(
      UseMockCashSessionNotifier.new,
    );

final remoteCashSessionRepositoryProvider = Provider<CashSessionRepository>((
  ref,
) {
  return RemoteCashSessionRepository(ref.watch(cashSessionApiProvider));
});

final remoteCashSessionMovementRepositoryProvider =
    Provider<CashSessionMovementRepository>((ref) {
      return RemoteCashSessionRepository(ref.watch(cashSessionApiProvider));
    });

final cashSessionRepositoryProvider = Provider<CashSessionRepository>((ref) {
  final useMock = ref.watch(useMockCashSessionProvider);
  if (useMock) {
    return ref.watch(mockCashSessionRepositoryProvider);
  }
  return ref.watch(remoteCashSessionRepositoryProvider);
});

final cashSessionMovementRepositoryProvider =
    Provider<CashSessionMovementRepository>((ref) {
      final useMock = ref.watch(useMockCashSessionProvider);
      if (useMock) {
        return ref.watch(mockCashSessionRepositoryProvider);
      }
      return ref.watch(remoteCashSessionMovementRepositoryProvider);
    });
