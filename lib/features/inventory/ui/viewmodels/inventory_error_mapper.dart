import 'package:dio/dio.dart';
import 'package:modular_pos/core/network/api_contract.dart';

enum InventoryErrorCode {
  stockItemDuplicateName,
  stockCategoryDuplicateName,
  baseUnitImmutable,
  stockItemInactive,
  adjustmentInvalid,
  quantityInvalid,
  entitlementBlocked,
  entitlementReadOnly,
  branchFrozen,
  branchContextRequired,
  tenantContextRequired,
  forbidden,
  unknown,
}

class InventoryMappedError {
  const InventoryMappedError({
    required this.message,
    required this.code,
    this.rawCode,
  });

  final String message;
  final InventoryErrorCode code;
  final String? rawCode;
}

InventoryMappedError mapInventoryError(
  Object error, {
  required String fallbackMessage,
}) {
  final rawCode = _errorCodeOf(error);
  final code = _inventoryErrorCodeFromRaw(rawCode);
  final serverMessage = _errorMessageOf(error).trim();
  final mappedMessage = switch (code) {
    InventoryErrorCode.stockItemDuplicateName =>
      'Stock item name already exists. Please choose a different name.',
    InventoryErrorCode.stockCategoryDuplicateName =>
      'Category name already exists. Please choose a different name.',
    InventoryErrorCode.baseUnitImmutable =>
      'Base unit cannot be changed for this stock item.',
    InventoryErrorCode.stockItemInactive =>
      'This stock item is inactive. Restore or reactivate it before continuing.',
    InventoryErrorCode.adjustmentInvalid =>
      'Inventory adjustment is invalid. Please review quantity and reason.',
    InventoryErrorCode.quantityInvalid =>
      'Quantity is invalid. Enter a valid positive quantity.',
    InventoryErrorCode.entitlementBlocked =>
      'Inventory changes are blocked by your current entitlement.',
    InventoryErrorCode.entitlementReadOnly =>
      'Inventory is read-only for your current entitlement.',
    InventoryErrorCode.branchFrozen =>
      'This branch is currently frozen and cannot be modified.',
    InventoryErrorCode.branchContextRequired =>
      'Branch context is missing. Please reselect a branch and try again.',
    InventoryErrorCode.tenantContextRequired =>
      'Tenant context is missing. Please reselect workspace and try again.',
    InventoryErrorCode.forbidden =>
      'You do not have permission to perform this inventory action.',
    InventoryErrorCode.unknown => null,
  };

  final message =
      mappedMessage ??
      (serverMessage.isNotEmpty ? serverMessage : fallbackMessage);
  return InventoryMappedError(
    message: message,
    code: code,
    rawCode: rawCode.isEmpty ? null : rawCode,
  );
}

InventoryErrorCode _inventoryErrorCodeFromRaw(String rawCode) {
  switch (rawCode) {
    case 'INVENTORY_STOCK_ITEM_DUPLICATE_NAME':
      return InventoryErrorCode.stockItemDuplicateName;
    case 'INVENTORY_STOCK_CATEGORY_DUPLICATE_NAME':
      return InventoryErrorCode.stockCategoryDuplicateName;
    case 'INVENTORY_BASE_UNIT_IMMUTABLE':
      return InventoryErrorCode.baseUnitImmutable;
    case 'INVENTORY_STOCK_ITEM_INACTIVE':
      return InventoryErrorCode.stockItemInactive;
    case 'INVENTORY_ADJUSTMENT_INVALID':
      return InventoryErrorCode.adjustmentInvalid;
    case 'INVENTORY_QUANTITY_INVALID':
      return InventoryErrorCode.quantityInvalid;
    case 'ENTITLEMENT_BLOCKED':
      return InventoryErrorCode.entitlementBlocked;
    case 'ENTITLEMENT_READ_ONLY':
      return InventoryErrorCode.entitlementReadOnly;
    case 'BRANCH_FROZEN':
      return InventoryErrorCode.branchFrozen;
    case 'BRANCH_CONTEXT_REQUIRED':
      return InventoryErrorCode.branchContextRequired;
    case 'TENANT_CONTEXT_REQUIRED':
      return InventoryErrorCode.tenantContextRequired;
    case 'FORBIDDEN':
    case 'ACCESS_DENIED':
    case 'AUTH_FORBIDDEN':
      return InventoryErrorCode.forbidden;
    default:
      return InventoryErrorCode.unknown;
  }
}

String _errorCodeOf(Object error) {
  if (error is ApiClientException) {
    return (error.code ?? '').trim().toUpperCase();
  }
  if (error is DioError) {
    final code = ApiContract.errorCode(error.response?.data);
    return (code ?? '').trim().toUpperCase();
  }
  return '';
}

String _errorMessageOf(Object error) {
  if (error is ApiClientException) return error.message;
  if (error is DioError) {
    final message = ApiContract.errorMessage(error.response?.data);
    if (message != null && message.trim().isNotEmpty) return message;
    return error.message ?? '';
  }
  final text = error.toString().trim();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length).trim();
  }
  if (text.startsWith('StateError: ')) {
    return text.substring('StateError: '.length).trim();
  }
  return text;
}
