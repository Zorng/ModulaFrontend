import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/features/discount/data/discount_api.dart';
import 'package:modular_pos/features/discount/data/discount_repository.dart';
import 'package:modular_pos/features/discount/data/mock_discount_repository.dart';
import 'package:modular_pos/features/discount/data/remote_discount_repository.dart';

void main() {
  test('discountRepositoryProvider defaults to remote implementation', () {
    final container = ProviderContainer(
      overrides: [discountApiProvider.overrideWithValue(DiscountApi(Dio()))],
    );
    addTearDown(container.dispose);

    final repository = container.read(discountRepositoryProvider);
    final remoteRepository = container.read(remoteDiscountRepositoryProvider);

    expect(repository, same(remoteRepository));
    expect(repository, isA<RemoteDiscountRepository>());
  });

  test('mock discount repository remains explicitly overrideable', () {
    final container = ProviderContainer(
      overrides: [
        useMockDiscountRepositoryProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(discountRepositoryProvider);

    expect(repository, isA<MockDiscountRepository>());
  });
}
