import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';

String mapMenuItemSaveErrorMessage(Object error) {
  final code = _errorCodeOf(error).trim().toUpperCase();
  switch (code) {
    case 'UPLOAD_FILE_TOO_LARGE':
      return 'Image is too large. Maximum size is 5MB.';
    case 'UPLOAD_INVALID_TYPE':
      return 'Unsupported image type. Use JPG, PNG, or WEBP.';
    case 'UPLOAD_FILE_REQUIRED':
      return 'Please select an image and try again.';
    case 'UPLOAD_INVALID_FIELD':
    case 'UPLOAD_BAD_REQUEST':
      return 'Invalid image upload request. Please try again.';
    case 'TENANT_CONTEXT_REQUIRED':
      return 'Tenant context is missing. Please reselect tenant and try again.';
    case 'IMAGE_STORAGE_NOT_CONFIGURED':
      return 'Image service is not configured. Please contact support.';
    case 'IMAGE_UPLOAD_FAILED':
      return 'Image upload failed. Please try again.';
  }

  final message = _errorMessageOf(error).trim();
  if (message.isNotEmpty) return message;
  return 'Failed to save menu item. Please try again.';
}

String _errorCodeOf(Object error) {
  if (error is ApiClientException) return error.code ?? '';
  if (error is MenuApiException) return error.code ?? '';
  return '';
}

String _errorMessageOf(Object error) {
  if (error is ApiClientException) return error.message;
  if (error is MenuApiException) return error.message;
  return error.toString();
}
