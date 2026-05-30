class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.entityType,
    this.entityId,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      entityType: entityType,
      entityId: entityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      entityType: json['entityType']?.toString(),
      entityId: json['entityId']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    final text = value?.toString().trim() ?? '';
    return DateTime.tryParse(text) ?? DateTime.now();
  }
}

class NotificationListResult {
  const NotificationListResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int unreadCount;

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => AppNotification.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <AppNotification>[];

    return NotificationListResult(
      items: items,
      page: _asInt(json['page'], 1),
      pageSize: _asInt(json['pageSize'], 20),
      totalCount: _asInt(json['totalCount'], items.length),
      unreadCount: _asInt(json['unreadCount'], 0),
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
