import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/inventory/data/dto/inventory_category_dto.dart';
import 'package:modular_pos/features/inventory/data/inventory_api.dart';
import 'package:modular_pos/features/inventory/data/remote_inventory_category_repository.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_category.dart';
import 'package:modular_pos/features/inventory/domain/models/inventory_status.dart';

class _MockInventoryApi extends Mock implements InventoryApi {}

void main() {
  test('updateCategory forwards name-only payload', () async {
    final api = _MockInventoryApi();
    final repository = RemoteInventoryCategoryRepository(api);

    when(() => api.updateCategory(any(), any())).thenAnswer(
      (_) async => const InventoryCategoryDto(
        id: 'cat-1',
        tenantId: 'tenant-1',
        name: 'Updated Name',
        status: InventoryStatus.active,
        createdAt: '2026-02-20T00:00:00.000Z',
        updatedAt: '2026-02-21T00:00:00.000Z',
      ),
    );

    await repository.updateCategory(
      const InventoryCategory(
        id: 'cat-1',
        name: 'Updated Name',
        isActive: false,
        description: 'Legacy description',
      ),
    );

    verify(
      () => api.updateCategory('cat-1', {'name': 'Updated Name'}),
    ).called(1);
  });
}
