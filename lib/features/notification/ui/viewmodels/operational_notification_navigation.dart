import 'package:intl/intl.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/notification/domain/models/operational_notification.dart';

String operationalNotificationActionLabel(OperationalNotificationItem item) {
  switch (OperationalNotificationTypes.normalize(item.type)) {
    case OperationalNotificationTypes.cashSessionClosed:
      return 'View session';
    case OperationalNotificationTypes.voidApprovalNeeded:
    case OperationalNotificationTypes.voidApproved:
    case OperationalNotificationTypes.voidRejected:
      return 'Open carts';
  }
  return 'Open';
}

String operationalNotificationLocation(OperationalNotificationItem item) {
  switch (OperationalNotificationTypes.normalize(item.type)) {
    case OperationalNotificationTypes.cashSessionClosed:
      final sessionId = _payloadValue(
        item,
        preferredKeys: const ['sessionId', 'cashSessionId'],
      );
      if (sessionId != null) {
        return AppRoute.cashHistoryDetail.path.replaceFirst(
          ':sessionId',
          Uri.encodeComponent(sessionId),
        );
      }
      return AppRoute.cashHistory.path;
    case OperationalNotificationTypes.voidApprovalNeeded:
      return _saleHistoryLocation(item, state: 'VOID_PENDING');
    case OperationalNotificationTypes.voidApproved:
      return _saleHistoryLocation(item, state: 'VOIDED');
    case OperationalNotificationTypes.voidRejected:
      return _saleHistoryLocation(item, state: 'FINALIZED');
  }
  return AppRoute.notifications.path;
}

String _saleHistoryLocation(
  OperationalNotificationItem item, {
  required String state,
}) {
  final saleId = _payloadValue(item, preferredKeys: const ['saleId']);
  final createdAtDate = DateFormat(
    'yyyy-MM-dd',
  ).format(item.createdAt.toLocal());
  final query = <String, String>{
    'state': state,
    'date': createdAtDate,
    if (saleId != null) 'saleId': saleId,
  };
  final queryString = Uri(queryParameters: query).query;
  return queryString.isEmpty
      ? AppRoute.saleViewCarts.path
      : '${AppRoute.saleViewCarts.path}?$queryString';
}

String? _payloadValue(
  OperationalNotificationItem item, {
  required List<String> preferredKeys,
}) {
  for (final key in preferredKeys) {
    final raw = item.payload?[key];
    final normalized = raw?.toString().trim() ?? '';
    if (normalized.isNotEmpty) return normalized;
  }
  final subjectId = item.subjectId.trim();
  return subjectId.isEmpty ? null : subjectId;
}
