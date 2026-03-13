import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';

void main() {
  group('ApiContract', () {
    test('unwrapData returns envelope data when success is true', () {
      final payload = {
        'success': true,
        'data': {'id': '1'},
      };

      expect(ApiContract.unwrapData(payload), {'id': '1'});
    });

    test('extracts error fields from envelope', () {
      final payload = {
        'success': false,
        'error': 'Validation failed',
        'code': 'INVALID_INPUT',
        'details': {'field': 'phone'},
      };

      expect(ApiContract.errorMessage(payload), 'Validation failed');
      expect(ApiContract.errorCode(payload), 'INVALID_INPUT');
      expect(ApiContract.errorDetails(payload), {'field': 'phone'});
    });

    test('errorCode falls back to reasonCode fields', () {
      final payload = {
        'success': false,
        'error': 'Item inactive',
        'details': {'reasonCode': 'INVENTORY_STOCK_ITEM_INACTIVE'},
      };

      expect(ApiContract.errorCode(payload), 'INVENTORY_STOCK_ITEM_INACTIVE');
    });
  });

  group('ApiClientException', () {
    test('maps dio response envelope to structured exception', () {
      final requestOptions = RequestOptions(path: '/v0/test');
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 409,
        data: {
          'success': false,
          'error': 'Conflict',
          'code': 'IDEMPOTENCY_CONFLICT',
        },
      );

      final exception = DioError(
        requestOptions: requestOptions,
        response: response,
        type: DioErrorType.badResponse,
      );

      final mapped = ApiClientException.fromDio(exception);
      expect(mapped.message, 'Conflict');
      expect(mapped.code, 'IDEMPOTENCY_CONFLICT');
      expect(mapped.statusCode, 409);
    });

    test('maps reasonCode fallback when code is absent', () {
      final requestOptions = RequestOptions(path: '/v0/test');
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 400,
        data: {
          'success': false,
          'error': 'Invalid adjustment.',
          'reasonCode': 'INVENTORY_ADJUSTMENT_INVALID',
        },
      );

      final exception = DioError(
        requestOptions: requestOptions,
        response: response,
        type: DioErrorType.badResponse,
      );

      final mapped = ApiClientException.fromDio(exception);
      expect(mapped.code, 'INVENTORY_ADJUSTMENT_INVALID');
      expect(mapped.statusCode, 400);
    });
  });
}
