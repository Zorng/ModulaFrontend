import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/sale/data/mock_sale_repository.dart';
import 'package:modular_pos/features/sale/data/sale_api.dart';
import 'package:modular_pos/features/sale/data/sale_repository.dart';

void main() {
  test('saleRepositoryProvider defaults to the remote implementation', () {
    final container = ProviderContainer(
      overrides: [saleApiProvider.overrideWithValue(SaleApi(Dio()))],
    );
    addTearDown(container.dispose);

    final repository = container.read(saleRepositoryProvider);
    final remoteRepository = container.read(remoteSaleRepositoryProvider);

    expect(repository, same(remoteRepository));
    expect(repository, isA<SaleRepository>());
  });

  test('mockSaleRepositoryProvider remains explicitly available for tests', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repository = container.read(mockSaleRepositoryProvider);

    expect(repository, isA<MockSaleRepository>());
  });
}
