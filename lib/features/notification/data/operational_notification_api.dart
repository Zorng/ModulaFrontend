import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/core/network/dio_client.dart';
import 'package:modular_pos/features/notification/data/dto/operational_notification_dto.dart';

final operationalNotificationApiPrefixProvider = Provider<String>(
  (_) => AppEnv.notificationApiPrefix,
);

final operationalNotificationApiProvider = Provider<OperationalNotificationApi>(
  (ref) {
    final dio = ref.read(dioProvider);
    final prefix = ref.read(operationalNotificationApiPrefixProvider);
    return OperationalNotificationApi(dio, prefix: prefix);
  },
);

class OperationalNotificationApi {
  OperationalNotificationApi(this._dio, {String prefix = '/v0/notifications'})
    : _prefix = prefix;

  final Dio _dio;
  final String _prefix;

  Future<OperationalNotificationInboxPageDto> listInbox({
    bool unreadOnly = false,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_prefix/inbox',
        queryParameters: {
          'unreadOnly': unreadOnly,
          if ((type ?? '').trim().isNotEmpty) 'type': type!.trim(),
          'limit': limit,
          'offset': offset,
        },
      );
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return OperationalNotificationInboxPageDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load notifications.',
      );
    }
  }

  Future<OperationalNotificationUnreadCountDto> getUnreadCount() async {
    try {
      final response = await _dio.get<dynamic>('$_prefix/unread-count');
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return OperationalNotificationUnreadCountDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load unread notification count.',
      );
    }
  }

  Future<OperationalNotificationItemDto> getNotificationById(
    String notificationId,
  ) async {
    final normalizedNotificationId = notificationId.trim();
    try {
      final response = await _dio.get<dynamic>(
        '$_prefix/$normalizedNotificationId',
      );
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return OperationalNotificationItemDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to load notification details.',
      );
    }
  }

  Future<OperationalNotificationReadResultDto> markNotificationAsRead(
    String notificationId,
  ) async {
    final normalizedNotificationId = notificationId.trim();
    try {
      final response = await _dio.post<dynamic>(
        '$_prefix/$normalizedNotificationId/read',
      );
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return OperationalNotificationReadResultDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to mark notification as read.',
      );
    }
  }

  Future<OperationalNotificationMarkAllReadResultDto> markAllAsRead() async {
    try {
      final response = await _dio.post<dynamic>('$_prefix/read-all');
      final data = ApiContract.asJsonMap(ApiContract.unwrapData(response.data));
      return OperationalNotificationMarkAllReadResultDto.fromJson(data);
    } on DioError catch (error) {
      throw ApiClientException.fromDio(
        error,
        fallbackMessage: 'Failed to mark all notifications as read.',
      );
    }
  }
}
