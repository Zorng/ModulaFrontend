class OperationalNotificationTypes {
  const OperationalNotificationTypes._();

  static const voidApprovalNeeded = 'VOID_APPROVAL_NEEDED';
  static const voidApproved = 'VOID_APPROVED';
  static const voidRejected = 'VOID_REJECTED';
  static const cashSessionClosed = 'CASH_SESSION_CLOSED';

  static const values = <String>{
    voidApprovalNeeded,
    voidApproved,
    voidRejected,
    cashSessionClosed,
  };

  static String normalize(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (values.contains(normalized)) return normalized;
    return cashSessionClosed;
  }
}

class OperationalNotificationSubjectTypes {
  const OperationalNotificationSubjectTypes._();

  static const sale = 'SALE';
  static const cashSession = 'CASH_SESSION';

  static const values = <String>{sale, cashSession};

  static String normalize(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (values.contains(normalized)) return normalized;
    return sale;
  }
}

class OperationalNotificationItem {
  const OperationalNotificationItem({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.type,
    required this.subjectType,
    required this.subjectId,
    required this.title,
    required this.body,
    required this.dedupeKey,
    required this.createdAt,
    this.payload,
    this.isRead = false,
    this.readAt,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String type;
  final String subjectType;
  final String subjectId;
  final String title;
  final String body;
  final String dedupeKey;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  bool get isUnread => !isRead;

  OperationalNotificationItem copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? type,
    String? subjectType,
    String? subjectId,
    String? title,
    String? body,
    String? dedupeKey,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
  }) {
    return OperationalNotificationItem(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      type: type == null
          ? this.type
          : OperationalNotificationTypes.normalize(type),
      subjectType: subjectType == null
          ? this.subjectType
          : OperationalNotificationSubjectTypes.normalize(subjectType),
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      body: body ?? this.body,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}

class OperationalNotificationInboxPage {
  const OperationalNotificationInboxPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final List<OperationalNotificationItem> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
}

class OperationalNotificationReadResult {
  const OperationalNotificationReadResult({
    required this.notificationId,
    required this.isRead,
    this.readAt,
  });

  final String notificationId;
  final bool isRead;
  final DateTime? readAt;
}

class OperationalNotificationMarkAllReadResult {
  const OperationalNotificationMarkAllReadResult({required this.updatedCount});

  final int updatedCount;
}
