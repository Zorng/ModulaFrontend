import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/mock_cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_history_entry.dart';

abstract class CashSessionHistoryRepository {
  Future<List<CashSessionHistoryEntry>> listClosedSessions({
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  });
}

final remoteCashSessionHistoryRepositoryProvider =
    Provider<CashSessionHistoryRepository>((ref) {
      return ref.watch(remoteCashSessionRepositoryProvider)
          as CashSessionHistoryRepository;
    });

final cashSessionHistoryRepositoryProvider =
    Provider<CashSessionHistoryRepository>((ref) {
      final useMock = ref.watch(useMockCashSessionProvider);
      if (useMock) {
        return ref.watch(mockCashSessionRepositoryProvider);
      }
      return ref.watch(remoteCashSessionHistoryRepositoryProvider);
    });
