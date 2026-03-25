import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/auth/domain/auth_branch_provider.dart';
import 'package:modular_pos/features/auth/domain/models/auth_session.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
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

bool operationalNotificationUsesExplicitContextHandoff(
  OperationalNotificationItem item,
) {
  switch (OperationalNotificationTypes.normalize(item.type)) {
    case OperationalNotificationTypes.cashSessionClosed:
    case OperationalNotificationTypes.voidApprovalNeeded:
    case OperationalNotificationTypes.voidApproved:
    case OperationalNotificationTypes.voidRejected:
      return true;
  }
  return false;
}

bool operationalNotificationContextMatches({
  required LoginState loginState,
  required String? activeBranchId,
  required OperationalNotificationItem item,
}) {
  final session = loginState.session;
  if (session == null) return false;
  final currentTenantId = session.establishedTenantId.trim();
  final currentBranch = (activeBranchId ?? '').trim();
  return currentTenantId == item.tenantId.trim() &&
      currentBranch == item.branchId.trim();
}

String operationalNotificationHandoffMessage(OperationalNotificationItem item) {
  final tenantName = item.tenantName.trim().isEmpty
      ? 'this tenant'
      : item.tenantName.trim();
  final branchName = (item.branchName ?? '').trim().isEmpty
      ? 'this branch'
      : item.branchName!.trim();
  return 'Switch to $tenantName / $branchName to '
      '${_handoffActionDescription(item)}?';
}

String operationalNotificationHandoffConfirmLabel(
  OperationalNotificationItem item,
) {
  switch (OperationalNotificationTypes.normalize(item.type)) {
    case OperationalNotificationTypes.cashSessionClosed:
      return 'Switch and view';
    case OperationalNotificationTypes.voidApprovalNeeded:
    case OperationalNotificationTypes.voidApproved:
    case OperationalNotificationTypes.voidRejected:
      return 'Switch and open';
  }
  return 'Switch and open';
}

String operationalNotificationAccessFailureMessage(
  OperationalNotificationItem item,
) {
  switch (OperationalNotificationTypes.normalize(item.type)) {
    case OperationalNotificationTypes.cashSessionClosed:
      return 'You can no longer view this closed session.';
    case OperationalNotificationTypes.voidApprovalNeeded:
    case OperationalNotificationTypes.voidApproved:
    case OperationalNotificationTypes.voidRejected:
      return 'You can no longer open these carts.';
  }
  return 'You can no longer open this notification.';
}

Future<OperationalNotificationContextHandoffResult>
operationalNotificationPrepareContext(
  WidgetRef ref,
  OperationalNotificationItem item,
) async {
  final session = ref.read(loginControllerProvider).session;
  if (session == null) {
    return OperationalNotificationContextHandoffResult.failure(
      operationalNotificationAccessFailureMessage(item),
    );
  }

  final targetTenantId = item.tenantId.trim();
  final targetBranchId = item.branchId.trim();
  if (targetTenantId.isEmpty || targetBranchId.isEmpty) {
    return OperationalNotificationContextHandoffResult.failure(
      operationalNotificationAccessFailureMessage(item),
    );
  }

  if (!_hasTenantMembership(session, targetTenantId)) {
    return OperationalNotificationContextHandoffResult.failure(
      operationalNotificationAccessFailureMessage(item),
    );
  }

  final loginController = ref.read(loginControllerProvider.notifier);
  final currentTenantId = session.establishedTenantId.trim();
  if (currentTenantId != targetTenantId) {
    final success = await loginController.selectTenant(targetTenantId);
    final tenantState = ref.read(loginControllerProvider);
    if (!success ||
        tenantState.session == null ||
        tenantState.session!.establishedTenantId.trim() != targetTenantId) {
      return OperationalNotificationContextHandoffResult.failure(
        operationalNotificationAccessFailureMessage(item),
      );
    }
  }

  final activeBranchId = (ref.read(activeBranchContextIdProvider) ?? '').trim();
  if (activeBranchId != targetBranchId) {
    await loginController.selectBranch(targetBranchId);
    final branchState = ref.read(loginControllerProvider);
    if ((branchState.error ?? '').trim().isNotEmpty) {
      return OperationalNotificationContextHandoffResult.failure(
        operationalNotificationAccessFailureMessage(item),
      );
    }
    ref
        .read(authActiveBranchOverrideProvider.notifier)
        .setOverride(targetBranchId);
    ref
        .read(authActiveBranchNameOverrideProvider.notifier)
        .setName(item.branchName);
  }

  return const OperationalNotificationContextHandoffResult.success();
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

class OperationalNotificationContextHandoffResult {
  const OperationalNotificationContextHandoffResult.success()
    : isSuccess = true,
      message = null;

  const OperationalNotificationContextHandoffResult.failure(this.message)
    : isSuccess = false;

  final bool isSuccess;
  final String? message;
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

bool _hasTenantMembership(AuthSession session, String tenantId) {
  final normalizedTenantId = tenantId.trim();
  if (normalizedTenantId.isEmpty) return false;
  for (final membership in session.memberships) {
    if (membership.tenantId.trim() == normalizedTenantId) return true;
  }
  return false;
}

String _handoffActionDescription(OperationalNotificationItem item) {
  switch (OperationalNotificationTypes.normalize(item.type)) {
    case OperationalNotificationTypes.cashSessionClosed:
      return 'view this closed session';
    case OperationalNotificationTypes.voidApprovalNeeded:
      return 'review this void request';
    case OperationalNotificationTypes.voidApproved:
    case OperationalNotificationTypes.voidRejected:
      return 'open the related carts';
  }
  return 'open this notification';
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
