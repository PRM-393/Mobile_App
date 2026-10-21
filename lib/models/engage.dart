import 'json_utils.dart';

// Thong bao nhan duoc (FR-ENGAGE-06)
// Thong bao trong app (FR-ENGAGE-06/07). data cho biet man hinh can mo khi bam: orderId / voucherItemId / campaignId
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.type = '',
    this.data = const {},
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  AppNotification markedRead(DateTime at) =>
      AppNotification(id: id, type: type, title: title, body: body, data: data, createdAt: createdAt, readAt: at);

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : const {},
        createdAt: asDate(json['createdAt']),
        readAt: asDateOrNull(json['readAt']),
      );
}

// Mot trang thong bao: GET /notifications/me tra { items, total, page, pageSize, unread }
class NotificationPage {
  const NotificationPage({required this.items, required this.unread, required this.total});

  final List<AppNotification> items;
  final int unread;
  final int total;

  // Van doc duoc phan hoi cu (mang thong bao) khi BE chua cap nhat F16
  factory NotificationPage.fromJson(Object? json) {
    if (json is List) {
      final items = asList(json, AppNotification.fromJson);
      return NotificationPage(items: items, unread: items.where((n) => !n.isRead).length, total: items.length);
    }
    final map = json as Map<String, dynamic>;
    final items = asList(map['items'], AppNotification.fromJson);
    return NotificationPage(items: items, unread: asInt(map['unread']), total: asInt(map['total'], items.length));
  }
}

// Bat / tat tung nhom thong bao (NotificationSetting)
class NotificationSetting {
  const NotificationSetting({required this.type, required this.label, required this.enabled});

  final String type;
  final String label;
  final bool enabled;

  factory NotificationSetting.fromJson(Map<String, dynamic> json) => NotificationSetting(
        type: json['type'] as String,
        label: json['label'] as String? ?? json['type'] as String,
        enabled: json['enabled'] as bool? ?? true,
      );
}

// Muc yeu thich: thuong hieu hoac chien dich (FR-ENGAGE-01)
class Favorite {
  const Favorite({
    required this.id,
    required this.targetType,
    required this.targetId,
  });

  final String id;
  final String targetType;
  final String targetId;

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    id: json['id'] as String,
    targetType: json['targetType'] as String? ?? 'CAMPAIGN',
    targetId: json['targetId'] as String? ?? '',
  );
}
