import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/sync/sync_models.dart';

void main() {
  test('buildModuleScopeSetKey is deterministic regardless of input order', () {
    final a = buildModuleScopeSetKey({
      SyncModuleScope.menu,
      SyncModuleScope.policy,
      SyncModuleScope.shift,
    });
    final b = buildModuleScopeSetKey({
      SyncModuleScope.shift,
      SyncModuleScope.menu,
      SyncModuleScope.policy,
    });

    expect(a, 'menu|policy|shift');
    expect(b, a);
  });
}
