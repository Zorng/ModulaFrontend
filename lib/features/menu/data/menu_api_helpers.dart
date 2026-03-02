import 'package:dio/dio.dart';
import 'package:modular_pos/core/network/api_contract.dart';

class MenuApiHelpers {
  const MenuApiHelpers._();

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const <String, dynamic>{};
  }

  static Map<String, dynamic> unwrap(dynamic body) {
    final map = asMap(body);
    if (map['success'] == false) {
      final message = ApiContract.errorMessage(map);
      throw ApiClientException(
        message: (message ?? '').trim().isNotEmpty
            ? message!.trim()
            : 'Menu request failed.',
        code: ApiContract.errorCode(map),
        details: ApiContract.errorDetails(map),
      );
    }
    final inner = map['data'];
    if (map['success'] == true && inner is Map) {
      return asMap(inner);
    }
    return map;
  }

  static List<T> parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => fromJson(asMap(e)))
          .toList(growable: false);
    }
    if (data is Map<String, dynamic>) {
      return [fromJson(data)];
    }
    return <T>[];
  }

  static Future<MultipartFile?> buildImagePart({
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      return MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      );
    }
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return MultipartFile.fromBytes(imageBytes, filename: 'upload.jpg');
    }
    return null;
  }
}
