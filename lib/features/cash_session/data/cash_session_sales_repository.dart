import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/cash_session/data/mock_cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_repository.dart';
import 'package:modular_pos/features/cash_session/domain/models/cash_session_sale.dart';

abstract class CashSessionSalesRepository {
  Future<List<CashSessionSale>> listSales({
    required String sessionId,
    int limit,
    int offset,
  });
}

final remoteCashSessionSalesRepositoryProvider =
    Provider<CashSessionSalesRepository>((ref) {
      return ref.watch(remoteCashSessionRepositoryProvider)
          as CashSessionSalesRepository;
    });

final cashSessionSalesRepositoryProvider = Provider<CashSessionSalesRepository>(
  (ref) {
    final useMock = ref.watch(useMockCashSessionProvider);
    if (useMock) {
      return ref.watch(mockCashSessionRepositoryProvider);
    }
    return ref.watch(remoteCashSessionSalesRepositoryProvider);
  },
);
