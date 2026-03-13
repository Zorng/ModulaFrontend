import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/inventory_error_mapper.dart';

enum StockItemFormErrorField { image, name, baseUnit, general }

class StockItemFormMappedError {
  const StockItemFormMappedError({required this.message, required this.field});

  final String message;
  final StockItemFormErrorField field;
}

StockItemFormMappedError mapStockItemFormSaveError(
  Object error, {
  required String fallbackMessage,
}) {
  final code = _errorCodeOf(error).trim().toUpperCase();
  switch (code) {
    case 'UPLOAD_FILE_TOO_LARGE':
      return const StockItemFormMappedError(
        message: 'Image is too large. Maximum size is 5MB.',
        field: StockItemFormErrorField.image,
      );
    case 'UPLOAD_INVALID_TYPE':
      return const StockItemFormMappedError(
        message: 'Unsupported image type. Use JPG, PNG, or WEBP.',
        field: StockItemFormErrorField.image,
      );
    case 'UPLOAD_FILE_REQUIRED':
      return const StockItemFormMappedError(
        message: 'Please select an image and try again.',
        field: StockItemFormErrorField.image,
      );
    case 'UPLOAD_INVALID_FIELD':
    case 'UPLOAD_BAD_REQUEST':
      return const StockItemFormMappedError(
        message: 'Invalid image upload request. Please try again.',
        field: StockItemFormErrorField.image,
      );
    case 'IMAGE_STORAGE_NOT_CONFIGURED':
      return const StockItemFormMappedError(
        message: 'Image service is not configured. Please contact support.',
        field: StockItemFormErrorField.image,
      );
    case 'IMAGE_UPLOAD_FAILED':
      return const StockItemFormMappedError(
        message: 'Image upload failed. Please try again.',
        field: StockItemFormErrorField.image,
      );
  }

  final mapped = mapInventoryError(error, fallbackMessage: fallbackMessage);
  switch (mapped.code) {
    case InventoryErrorCode.stockItemDuplicateName:
      return StockItemFormMappedError(
        message: mapped.message,
        field: StockItemFormErrorField.name,
      );
    case InventoryErrorCode.baseUnitImmutable:
      return StockItemFormMappedError(
        message: mapped.message,
        field: StockItemFormErrorField.baseUnit,
      );
    default:
      return StockItemFormMappedError(
        message: mapped.message,
        field: StockItemFormErrorField.general,
      );
  }
}

String _errorCodeOf(Object error) {
  if (error is ApiClientException) return error.code ?? '';
  return '';
}
