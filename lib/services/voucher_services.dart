import '../models/brand_page.dart';
import '../models/campaign.dart';
import '../models/engage.dart';
import '../models/json_utils.dart';
import '../models/order.dart';
import 'api_client.dart';

// FR-SEARCH-*: danh muc, tim kiem / loc / gan toi, chi tiet voucher (Guest dung duoc)
class SearchService {
  // F06 / FR-BRAND-07: trang thuong hieu cong khai (Guest xem duoc)
  Future<BrandPage> brandPage(String brandId) async =>
      BrandPage.fromJson(await _api.get('/brands/$brandId/public') as Map<String, dynamic>);

  SearchService(this._api);

  final ApiClient _api;

  Future<List<Category>> categories() async =>
      asList(await _api.get('/categories'), Category.fromJson);

  Future<SearchResult> search({
    String? keyword,
    String? categoryId,
    String? sort,
    int? minPrice,
    maxPrice,
    double? minDiscount,
    maxDiscount,
    bool locationDenied = false,
    double? lat,
    double? lng,
    int? radiusKm,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _api.get(
      '/vouchers',
      query: {
        'keyword': keyword,
        'categoryId': categoryId,
        'sort': sort,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'minDiscount': minDiscount,
        'maxDiscount': maxDiscount,
        'locationDenied': locationDenied,
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return SearchResult.fromJson(json as Map<String, dynamic>);
  }

  Future<VoucherCampaign> detail(String id, {double? lat, double? lng}) async =>
      VoucherCampaign.fromJson(
        await _api.get('/vouchers/$id', query: {'lat': lat, 'lng': lng})
            as Map<String, dynamic>,
      );
}

// FR-ORDER-*: tao don (giu ton kho 15 phut) va lich su don hang; FR-REDEEM-01: vi voucher
class OrderService {
  OrderService(this._api);

  final ApiClient _api;

  Future<CreateOrderResult> create(String campaignId, int quantity) async => CreateOrderResult.fromJson(
      await _api.post('/orders', body: {'campaignId': campaignId, 'quantity': quantity}) as Map<String, dynamic>);

  Future<List<Order>> myOrders() async => asList(await _api.get('/orders/me'), Order.fromJson);

  // FR-ORDER-05: hoi trang thai don tu may chu
  Future<Order> getOrder(String id) async => Order.fromJson(await _api.get('/orders/$id') as Map<String, dynamic>);

  // FR-ORDER-12: thanh toan lai trong thoi gian giu cho (may chu tra lai dung link cu)
  Future<CreateOrderResult> retryPayment(String id) async =>
      CreateOrderResult.fromJson(await _api.post('/orders/$id/pay') as Map<String, dynamic>);

  // Thanh toan thu khi may chu bat PAYMENT_SIMULATOR (demo do an, chua co khoa payOS)
  Future<Order> simulatePayment(String id, {bool success = true}) async {
    final json = await _api.post('/orders/$id/simulate-payment', body: {'success': success}) as Map<String, dynamic>;
    return Order.fromJson(json['order'] as Map<String, dynamic>);
  }

  // FR-REDEEM-01: JSON goc cua vi (WalletProvider luu nguyen vao SQLite de xem khi mat mang)
  Future<List<Map<String, dynamic>>> myWalletJson() async {
    final json = await _api.get('/wallet');
    return json is List ? json.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];
  }

  Future<List<VoucherItem>> myWallet() async => (await myWalletJson()).map(VoucherItem.fromJson).toList();

  // Chi tiet voucher da mua: chi nhanh ap dung, lan su dung, yeu cau hoan (chi chu so huu)
  Future<WalletVoucherDetail> walletDetail(String voucherItemId) async =>
      WalletVoucherDetail.fromJson(await _api.get('/wallet/$voucherItemId') as Map<String, dynamic>);
}

// FR-REDEEM-02/03: xin token QR dong + OTP cho mot voucher
class RedeemService {
  RedeemService(this._api);

  final ApiClient _api;

  Future<RedeemToken> requestToken(String voucherItemId) async => RedeemToken.fromJson(
      await _api.post('/redeem/token', body: {'voucherItemId': voucherItemId}) as Map<String, dynamic>);
}

// FR-REFUND-*: gui yeu cau hoan tien, theo doi trang thai
class RefundService {
  RefundService(this._api);

  final ApiClient _api;

  Future<RefundRequest> request(String voucherItemId, {String? reason}) async => RefundRequest.fromJson(
      await _api.post('/refunds', body: {'voucherItemId': voucherItemId, 'reason': reason}) as Map<String, dynamic>);

  Future<List<RefundRequest>> myRequests() async => asList(await _api.get('/refunds/me'), RefundRequest.fromJson);
}

// FR-ENGAGE-*: yeu thich, danh gia, thong bao
class EngageService {
  EngageService(this._api);

  final ApiClient _api;

  // Tra ve true neu sau khi bam dang o trang thai yeu thich / theo doi
  Future<bool> toggleFavorite(String targetType, String targetId) async {
    final json = await _api.post('/favorites', body: {'targetType': targetType, 'targetId': targetId});
    return json is Map && json['favorited'] == true;
  }

  // F06: dang theo doi thuong hieu / yeu thich voucher nay chua
  Future<bool> isFavorite(String targetType, String targetId) async =>
      (await myFavorites()).any((f) => f.targetType == targetType && f.targetId == targetId);

  Future<List<Favorite>> myFavorites() async => asList(await _api.get('/favorites/me'), Favorite.fromJson);

  // F15: danh gia theo chien dich (may chu kiem tra da dung voucher - BR-10, moi chien dich 1 lan - DC-09)
  Future<void> createReview(String campaignId, int rating, {String? comment}) => _api.post('/reviews', body: {
        'campaignId': campaignId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });

  // Danh gia cong khai + diem trung binh (Guest cung xem duoc)
  Future<ReviewPage> campaignReviews(String campaignId, {int page = 1}) async =>
      ReviewPage.fromJson(await _api.get('/campaigns/$campaignId/reviews', query: {'page': page}));

  Future<ReviewEligibility> reviewEligibility(String campaignId) async => ReviewEligibility.fromJson(
      await _api.get('/campaigns/$campaignId/reviews/eligibility') as Map<String, dynamic>);

  // F16: thong bao theo trang (20 / trang), kem so chua doc
  Future<NotificationPage> myNotifications({int page = 1}) async =>
      NotificationPage.fromJson(await _api.get('/notifications/me', query: {'page': page}));

  Future<void> markNotificationRead(String id) => _api.patch('/notifications/$id/read');

  Future<void> markAllNotificationsRead() => _api.patch('/notifications/read-all');

  Future<List<NotificationSetting>> notificationSettings() async =>
      asList(await _api.get('/notifications/settings'), NotificationSetting.fromJson);

  Future<List<NotificationSetting>> updateNotificationSetting(String type, bool enabled) async => asList(
      await _api.put('/notifications/settings', body: {'type': type, 'enabled': enabled}), NotificationSetting.fromJson);

  Future<void> registerDeviceToken(String token, String platform) =>
      _api.post('/notifications/device-token', body: {'token': token, 'platform': platform});
}
