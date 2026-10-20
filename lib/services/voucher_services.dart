import '../models/campaign.dart';
import '../models/engage.dart';
import '../models/json_utils.dart';
import '../models/order.dart';
import 'api_client.dart';

// FR-SEARCH-*: danh muc, tim kiem / loc / gan toi, chi tiet voucher (Guest dung duoc)
class SearchService {
  SearchService(this._api);

  final ApiClient _api;

  Future<List<Category>> categories() async => asList(await _api.get('/categories'), Category.fromJson);

  Future<SearchResult> search({
    String? keyword,
    String? categoryId,
    String? sort,
    double? lat,
    double? lng,
    int? radiusKm,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _api.get('/vouchers', query: {
      'keyword': keyword,
      'categoryId': categoryId,
      'sort': sort,
      'lat': lat,
      'lng': lng,
      'radiusKm': radiusKm,
      'page': page,
      'pageSize': pageSize,
    });
    return SearchResult.fromJson(json as Map<String, dynamic>);
  }

  Future<VoucherCampaign> detail(String id) async =>
      VoucherCampaign.fromJson(await _api.get('/vouchers/$id') as Map<String, dynamic>);
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

  Future<List<VoucherItem>> myWallet() async => asList(await _api.get('/wallet'), VoucherItem.fromJson);
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

  Future<void> toggleFavorite(String targetType, String targetId) =>
      _api.post('/favorites', body: {'targetType': targetType, 'targetId': targetId});

  Future<List<Favorite>> myFavorites() async => asList(await _api.get('/favorites/me'), Favorite.fromJson);

  Future<void> createReview(String voucherItemId, int rating, {String? comment}) =>
      _api.post('/reviews', body: {'voucherItemId': voucherItemId, 'rating': rating, 'comment': comment});

  Future<List<AppNotification>> myNotifications() async =>
      asList(await _api.get('/notifications/me'), AppNotification.fromJson);

  Future<void> registerDeviceToken(String token, String platform) =>
      _api.post('/notifications/device-token', body: {'token': token, 'platform': platform});
}
