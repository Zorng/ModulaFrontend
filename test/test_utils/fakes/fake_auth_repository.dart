import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';

/// Minimal fake used for tests that don't exercise auth flows.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login(String username, String password) {
    throw UnimplementedError('FakeAuthRepository.login is not implemented');
  }

  @override
  Future<AuthSession> selectTenant({
    required String selectionToken,
    required String tenantId,
    String? branchId,
  }) {
    throw UnimplementedError('FakeAuthRepository.selectTenant is not implemented');
  }
}

