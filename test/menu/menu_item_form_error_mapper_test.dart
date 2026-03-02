import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_error_mapper.dart';

void main() {
  group('mapMenuItemSaveErrorMessage', () {
    test('maps upload size error code', () {
      const error = ApiClientException(
        message: 'too large',
        code: 'UPLOAD_FILE_TOO_LARGE',
        statusCode: 400,
      );

      final message = mapMenuItemSaveErrorMessage(error);

      expect(message, 'Image is too large. Maximum size is 5MB.');
    });

    test('maps upload type error code', () {
      const error = MenuApiException(
        'invalid type',
        422,
        'UPLOAD_INVALID_TYPE',
      );

      final message = mapMenuItemSaveErrorMessage(error);

      expect(message, 'Unsupported image type. Use JPG, PNG, or WEBP.');
    });

    test('maps tenant context missing code', () {
      const error = ApiClientException(
        message: 'tenant required',
        code: 'TENANT_CONTEXT_REQUIRED',
        statusCode: 403,
      );

      final message = mapMenuItemSaveErrorMessage(error);

      expect(
        message,
        'Tenant context is missing. Please reselect tenant and try again.',
      );
    });

    test('falls back to backend message for unknown code', () {
      const error = ApiClientException(
        message: 'Backend validation failed.',
        code: 'SOME_OTHER_CODE',
        statusCode: 422,
      );

      final message = mapMenuItemSaveErrorMessage(error);

      expect(message, 'Backend validation failed.');
    });
  });
}
