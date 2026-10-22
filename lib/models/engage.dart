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
    this.title,
    this.image,
    this.salePrice,
    this.faceValue,
    this.brandName,
    this.status,
  });

  final String id;
  final String targetType;
  final String targetId;
  // May chu tra kem thong tin muc tieu (ten chien dich / thuong hieu, anh, gia)
  final String? title;
  final String? image;
  final double? salePrice;
  final double? faceValue;
  final String? brandName;
  final String? status;

  bool get isBrand => targetType == 'BRAND';

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    id: json['id'] as String,
    targetType: json['targetType'] as String? ?? 'CAMPAIGN',
    targetId: json['targetId'] as String? ?? '',
    title: json['title'] as String?,
    image: json['image'] as String?,
    salePrice: asDoubleOrNull(json['salePrice']),
    faceValue: asDoubleOrNull(json['faceValue']),
    brandName: json['brandName'] as String?,
    status: json['status'] as String?,
  );
}

// Danh gia cong khai cua chien dich (FR-ENGAGE-02..04): ten nguoi danh gia da duoc may chu che bot
class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.rating,
    required this.createdAt,
    required this.reviewerName,
    this.comment,
    this.brandReply,
    this.brandRepliedAt,
  });

  final String id;
  final int rating;
  final DateTime createdAt;
  final String reviewerName;
  final String? comment;
  final String? brandReply;
  final DateTime? brandRepliedAt;

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        id: json['id'] as String,
        rating: asInt(json['rating']),
        createdAt: asDate(json['createdAt']),
        reviewerName: json['reviewerName'] as String? ?? 'Khách hàng',
        comment: json['comment'] as String?,
        brandReply: json['brandReply'] as String?,
        brandRepliedAt: asDateOrNull(json['brandRepliedAt']),
      );
}

// GET /campaigns/:id/reviews: mot trang danh gia + diem trung binh (chi tinh danh gia khong bi an)
class ReviewPage {
  const ReviewPage({required this.items, required this.total, required this.page, this.avgRating, this.reviewCount = 0});

  final List<ReviewItem> items;
  final int total;
  final int page;
  final double? avgRating;
  final int reviewCount;

  bool get hasMore => page * 20 < total && items.isNotEmpty;

  factory ReviewPage.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return ReviewPage(
      items: asList(map['items'], ReviewItem.fromJson),
      total: asInt(map['total']),
      page: asInt(map['page'], 1),
      avgRating: asDoubleOrNull(map['avgRating']),
      reviewCount: asInt(map['reviewCount']),
    );
  }
}

// BR-10: chi khach da dung it nhat 1 voucher cua chien dich va chua danh gia moi thay nut "Đánh giá"
class ReviewEligibility {
  const ReviewEligibility({required this.canReview, this.reason});

  final bool canReview;
  final String? reason;

  factory ReviewEligibility.fromJson(Map<String, dynamic> json) =>
      ReviewEligibility(canReview: json['canReview'] == true, reason: json['reason'] as String?);
}
