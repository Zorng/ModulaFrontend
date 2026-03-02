import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
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
    final filename = _resolveFilename(imagePath);
    final subtype = _resolveImageSubtype(imagePath: imagePath, imageBytes: imageBytes);
    final contentType = subtype == null ? null : MediaType('image', subtype);

    if (imageBytes != null && imageBytes.isNotEmpty) {
      return MultipartFile.fromBytes(
        imageBytes,
        filename: filename ?? _filenameForSubtype(subtype),
        contentType: contentType,
      );
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      return MultipartFile.fromFile(
        imagePath,
        filename: filename,
        contentType: contentType,
      );
    }
    return null;
  }
}

String? _resolveImageSubtype({
  String? imagePath,
  List<int>? imageBytes,
}) {
  final bytes = imageBytes ?? const <int>[];
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }

  final lower = (imagePath ?? '').trim().toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpeg';
  if (lower.endsWith('.png')) return 'png';
  if (lower.endsWith('.webp')) return 'webp';
  return null;
}

String _filenameForSubtype(String? subtype) {
  switch (subtype) {
    case 'png':
      return 'upload.png';
    case 'webp':
      return 'upload.webp';
    case 'jpeg':
    default:
      return 'upload.jpg';
  }
}

String? _resolveFilename(String? imagePath) {
  final rawPath = (imagePath ?? '').trim();
  if (rawPath.isEmpty) return null;
  final normalized = rawPath.replaceAll('\\', '/');
  final idx = normalized.lastIndexOf('/');
  if (idx < 0 || idx == normalized.length - 1) return normalized;
  return normalized.substring(idx + 1);
}
