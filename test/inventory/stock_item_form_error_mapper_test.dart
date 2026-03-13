import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/ui/components/stock_item_form_error_mapper.dart';

void main() {
  group('mapStockItemFormSaveError', () {
    test('maps upload validation errors to image field', () {
      const error = ApiClientException(
        message: 'bad type',
        code: 'UPLOAD_INVALID_TYPE',
        statusCode: 422,
      );

      final mapped = mapStockItemFormSaveError(
        error,
        fallbackMessage: 'Failed to save stock item.',
      );

      expect(mapped.field, StockItemFormErrorField.image);
      expect(mapped.message, 'Unsupported image type. Use JPG, PNG, or WEBP.');
    });

    test('maps duplicate item name to name field', () {
      const error = ApiClientException(
        message: 'duplicate',
        code: 'INVENTORY_STOCK_ITEM_DUPLICATE_NAME',
        statusCode: 409,
      );

      final mapped = mapStockItemFormSaveError(
        error,
        fallbackMessage: 'Failed to save stock item.',
      );

      expect(mapped.field, StockItemFormErrorField.name);
    });

    test('maps immutable base unit to base-unit field', () {
      const error = ApiClientException(
        message: 'immutable',
        code: 'INVENTORY_BASE_UNIT_IMMUTABLE',
        statusCode: 409,
      );

      final mapped = mapStockItemFormSaveError(
        error,
        fallbackMessage: 'Failed to save stock item.',
      );

      expect(mapped.field, StockItemFormErrorField.baseUnit);
    });

    test('falls back to general field for other errors', () {
      const error = ApiClientException(
        message: 'blocked',
        code: 'ENTITLEMENT_BLOCKED',
        statusCode: 403,
      );

      final mapped = mapStockItemFormSaveError(
        error,
        fallbackMessage: 'Failed to save stock item.',
      );

      expect(mapped.field, StockItemFormErrorField.general);
      expect(
        mapped.message,
        'Inventory changes are blocked by your current entitlement.',
      );
    });
  });
}
