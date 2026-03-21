import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/staff/data/api/staff_api_helpers.dart';
import 'package:modular_pos/features/staff/data/dto/staff_membership_dto.dart';

final staffMembershipApiProvider = Provider<StaffMembershipApi>((ref) {
  final dio = ref.read(dioProvider);
  return StaffMembershipApi(dio);
});

class StaffMembershipApi {
  StaffMembershipApi(this._dio);

  final Dio _dio;
  static const _prefix = '/v0/hr/staff';

  Future<List<StaffMembershipDto>> fetchMemberships({
    String status = 'ALL',
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        _prefix,
        queryParameters: {
          'status': status,
          if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
          'limit': limit,
          'offset': offset,
        },
      );
      final list = StaffApiHelpers.unwrapPagedItems(response.data);
      return list.map(StaffMembershipDto.fromJson).toList(growable: false);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load staff memberships.',
      );
    }
  }

  Future<StaffMembershipDto> fetchMembershipDetail(String membershipId) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_prefix/${membershipId.trim()}',
      );
      final data = StaffApiHelpers.unwrapMap(response.data);
      return StaffMembershipDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load staff membership details.',
      );
    }
  }
}
