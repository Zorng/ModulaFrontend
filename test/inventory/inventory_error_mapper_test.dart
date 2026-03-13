import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

void main() {
  group('mapInventoryError', () {
    test('maps stock-item duplicate name to deterministic code/message', () {
      const error = ApiClientException(
        message: 'duplicate',
        code: 'INVENTORY_STOCK_ITEM_DUPLICATE_NAME',
        statusCode: 409,
      );

      final mapped = mapInventoryError(
        error,
        fallbackMessage: 'Failed to save item.',
      );

      expect(mapped.code, InventoryErrorCode.stockItemDuplicateName);
      expect(
        mapped.message,
        'Stock item name already exists. Please choose a different name.',
      );
      expect(mapped.rawCode, 'INVENTORY_STOCK_ITEM_DUPLICATE_NAME');
    });

    test('maps immutable base unit code', () {
      const error = ApiClientException(
        message: 'immutable',
        code: 'INVENTORY_BASE_UNIT_IMMUTABLE',
        statusCode: 409,
      );

      final mapped = mapInventoryError(
        error,
        fallbackMessage: 'Failed to save item.',
      );

      expect(mapped.code, InventoryErrorCode.baseUnitImmutable);
      expect(
        mapped.message,
        'Base unit cannot be changed for this stock item.',
      );
    });

    test('maps quantity invalid code', () {
      const error = ApiClientException(
        message: 'invalid qty',
        code: 'INVENTORY_QUANTITY_INVALID',
        statusCode: 422,
      );

      final mapped = mapInventoryError(
        error,
        fallbackMessage: 'Failed to apply change.',
      );

      expect(mapped.code, InventoryErrorCode.quantityInvalid);
      expect(
        mapped.message,
        'Quantity is invalid for this action. Check the entered amount and try again.',
      );
    });

    test('maps archived stock-item code to archive-specific guidance', () {
      const error = ApiClientException(
        message: 'item inactive',
        code: 'INVENTORY_STOCK_ITEM_INACTIVE',
        statusCode: 409,
      );

      final mapped = mapInventoryError(
        error,
        fallbackMessage: 'Failed to update stock item.',
      );

      expect(mapped.code, InventoryErrorCode.stockItemInactive);
      expect(
        mapped.message,
        'This stock item is archived. Restore it before continuing.',
      );
    });

    test('maps duplicate external movement code to retry-safe guidance', () {
      const error = ApiClientException(
        message: 'duplicate movement',
        code: 'INVENTORY_DUPLICATE_EXTERNAL_MOVEMENT',
        statusCode: 409,
      );

      final mapped = mapInventoryError(
        error,
        fallbackMessage: 'Failed to sync movement.',
      );

      expect(mapped.code, InventoryErrorCode.duplicateExternalMovement);
      expect(
        mapped.message,
        'This inventory movement was already processed. Refresh before trying again.',
      );
    });

    test('maps access-control codes from contract', () {
      const error = ApiClientException(
        message: 'no branch access',
        code: 'NO_BRANCH_ACCESS',
        statusCode: 403,
      );

      final mapped = mapInventoryError(
        error,
        fallbackMessage: 'Failed to apply change.',
      );

      expect(mapped.code, InventoryErrorCode.noBranchAccess);
      expect(mapped.message, 'You do not have access to the selected branch.');
      expect(isInventoryAccessErrorCode(mapped.code), isTrue);
    });

    test('uses backend message for unknown reason code', () {
      const error = ApiClientException(
        message: 'backend exploded',
        code: 'SOMETHING_NEW',
        statusCode: 500,
      );

      final mapped = mapInventoryError(
        error,
        fallbackMessage: 'Fallback message',
      );

      expect(mapped.code, InventoryErrorCode.unknown);
      expect(mapped.message, 'backend exploded');
    });

    test(
      'falls back to fallback message when unknown and no backend message',
      () {
        const error = ApiClientException(
          message: '',
          code: null,
          statusCode: 500,
        );

        final mapped = mapInventoryError(
          error,
          fallbackMessage: 'Fallback message',
        );

        expect(mapped.code, InventoryErrorCode.unknown);
        expect(mapped.message, 'Fallback message');
      },
    );
  });
}
