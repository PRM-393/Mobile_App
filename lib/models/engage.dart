import 'json_utils.dart';

// Thong bao nhan duoc (FR-ENGAGE-06)
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: asDate(json['createdAt']),
        readAt: asDateOrNull(json['readAt']),
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
