import 'campaign.dart';
import 'json_utils.dart';

// Nhan tieng Viet cho trang thai (vong doi SRS muc 6)
const orderStatusLabels = {
  'PENDING': 'Chờ thanh toán',
  'PAID': 'Đã thanh toán',
  'FULFILLED': 'Đã phát hành voucher',
  'CANCELLED': 'Đã hủy',
  'REFUNDED_OVERSOLD': 'Đã hoàn tiền (hết hàng)',
  'PAYMENT_MISMATCH': 'Sai số tiền, chờ hoàn lại',
};

const voucherStatusLabels = {
  'ACTIVE': 'Đang hiệu lực',
  'REFUND_PENDING': 'Đang hoàn tiền',
  'USED': 'Đã dùng',
  'EXPIRED': 'Hết hạn',
  'REFUNDED': 'Đã hoàn',
};

const refundStatusLabels = {
  'REQUESTED': 'Đã gửi yêu cầu',
  'PROCESSING': 'Đang xử lý',
  'MANUAL_PENDING': 'Chờ quản trị viên hoàn tiền',
  'COMPLETED': 'Hoàn tiền thành công',
  'REJECTED': 'Không đủ điều kiện',
  'FAILED': 'Hoàn tiền không thành công',
};

// Don hang (FR-ORDER-01..13). Trang thai chi lay tu may chu, app khong tu ket luan (FR-ORDER-05).
class Order {
  const Order({
    required this.id,
    required this.campaignId,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.reservedUntil,
    this.paidAt,
    this.paymentUrl,
    this.campaignTitle,
  });

  final String id;
  final String campaignId;
  final int quantity;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime? reservedUntil;
  final DateTime? paidAt;
  final String? paymentUrl;
  final String? campaignTitle;

  // Trang thai ket thuc: dung hoi may chu
  static const finalStatuses = {'FULFILLED', 'CANCELLED', 'REFUNDED_OVERSOLD', 'PAYMENT_MISMATCH'};

  bool get isFinal => finalStatuses.contains(status);

  // FR-ORDER-12: duoc thanh toan lai khi don con PENDING va chua het thoi gian giu cho
  bool canRetry(DateTime now) => status == 'PENDING' && reservedUntil != null && now.isBefore(reservedUntil!);

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        campaignId: json['campaignId'] as String? ?? '',
        quantity: asInt(json['quantity']),
        totalAmount: asDouble(json['totalAmount']),
        status: json['status'] as String? ?? 'PENDING',
        createdAt: asDate(json['createdAt']),
        reservedUntil: asDateOrNull(json['reservedUntil']),
        paidAt: asDateOrNull(json['paidAt']),
        paymentUrl: json['paymentUrl'] as String?,
        campaignTitle: json['campaign'] is Map ? (json['campaign'] as Map)['title'] as String? : null,
      );
}

// Phan hoi khi tao don / thanh toan lai. paymentUrl = null khi may chu chua cau hinh payOS (dung thanh toan thu)
class CreateOrderResult {
  const CreateOrderResult({required this.order, this.paymentUrl});

  final Order order;
  final String? paymentUrl;

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) => CreateOrderResult(
        order: Order.fromJson(json['order'] as Map<String, dynamic>),
        paymentUrl: (json['paymentUrl'] as String?)?.isEmpty ?? true ? null : json['paymentUrl'] as String,
      );
}

// Dieu kien hoan tien do may chu tinh theo BR-05 (FR-REFUND-04/07): app khoa nut va hien ly do
class RefundEligibility {
  const RefundEligibility({required this.canRefund, this.reasonCode, this.reason, this.refundableUntil});

  final bool canRefund;
  final String? reasonCode;
  final String? reason;
  final DateTime? refundableUntil;

  factory RefundEligibility.fromJson(Map<String, dynamic> json) => RefundEligibility(
        canRefund: json['canRefund'] == true,
        reasonCode: json['reasonCode'] as String?,
        reason: json['reason'] as String?,
        refundableUntil: asDateOrNull(json['refundableUntil']),
      );
}

// Voucher cu the cua khach trong vi (GET /wallet). JSON goc duoc luu cache SQLite de xem khi mat mang (NFR-MOB-12).
class VoucherItem {
  const VoucherItem({
    required this.id,
    required this.orderId,
    required this.campaignId,
    required this.code,
    required this.status,
    required this.issuedAt,
    required this.expireAt,
    this.usedAt,
    this.refundableUntil,
    this.campaign,
    this.refund,
    this.canReview = false,
    this.hasReviewed = false,
  });

  final String id;
  final String orderId;
  final String campaignId;
  final String code;
  final String status;
  final DateTime issuedAt;
  final DateTime? usedAt;
  final DateTime expireAt;
  final DateTime? refundableUntil;
  final VoucherCampaign? campaign;
  final RefundEligibility? refund;
  final bool canReview;
  final bool hasReviewed;

  // Het han xet theo expireAt so voi hien tai, khong cho tac vu nen cap nhat trang thai.
  // REFUND_PENDING giu nguyen (dang cho hoan). Cung quy tac voi may chu nen du lieu cache van chia tab dung.
  String effectiveStatusAt(DateTime now) => status == 'ACTIVE' && !expireAt.isAfter(now) ? 'EXPIRED' : status;

  String get effectiveStatus => effectiveStatusAt(DateTime.now());

  // 4 tab cua vi: REFUND_PENDING nam o tab "Đang hiệu lực" voi nhan "Đang hoàn tiền"
  String get tab => switch (effectiveStatus) {
        'ACTIVE' || 'REFUND_PENDING' => 'ACTIVE',
        'USED' => 'USED',
        'REFUNDED' => 'REFUNDED',
        _ => 'EXPIRED',
      };

  String get statusLabel => voucherStatusLabels[effectiveStatus] ?? effectiveStatus;

  // Chi voucher dang hieu luc (khong dang cho hoan) moi sinh ma su dung duoc
  bool get canRedeem => effectiveStatus == 'ACTIVE';

  factory VoucherItem.fromJson(Map<String, dynamic> json) {
    final review = json['review'] is Map ? json['review'] as Map : const {};
    return VoucherItem(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? '',
      campaignId: json['campaignId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      issuedAt: asDate(json['issuedAt']),
      usedAt: asDateOrNull(json['usedAt']),
      expireAt: asDate(json['expireAt']),
      refundableUntil: asDateOrNull(json['refundableUntil']),
      campaign: json['campaign'] is Map<String, dynamic>
          ? VoucherCampaign.fromJson(json['campaign'] as Map<String, dynamic>)
          : null,
      refund: json['refund'] is Map<String, dynamic>
          ? RefundEligibility.fromJson(json['refund'] as Map<String, dynamic>)
          : null,
      canReview: review['canReview'] == true,
      hasReviewed: review['hasReviewed'] == true,
    );
  }
}

// Chi nhanh ap dung cua voucher da mua
class WalletStore {
  const WalletStore({required this.id, required this.name, required this.address, this.phone, this.openingHours});

  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? openingHours;

  factory WalletStore.fromJson(Map<String, dynamic> json) => WalletStore(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String?,
        openingHours: json['openingHours'] as String?,
      );
}

// Lan su dung voucher (FR-REDEEM-07): luc nao, o chi nhanh nao
class Redemption {
  const Redemption({required this.redeemedAt, this.storeName, this.storeAddress, this.method});

  final DateTime redeemedAt;
  final String? storeName;
  final String? storeAddress;
  final String? method;

  factory Redemption.fromJson(Map<String, dynamic> json) => Redemption(
        redeemedAt: asDate(json['redeemedAt']),
        storeName: json['storeName'] as String?,
        storeAddress: json['storeAddress'] as String?,
        method: json['method'] as String?,
      );
}

// Chi tiet voucher da mua (GET /wallet/:id): chi nhanh ap dung, lan su dung, cac yeu cau hoan
class WalletVoucherDetail {
  const WalletVoucherDetail({
    required this.voucher,
    this.stores = const [],
    this.redemption,
    this.refundRequests = const [],
  });

  final VoucherItem voucher;
  final List<WalletStore> stores;
  final Redemption? redemption;
  final List<RefundRequest> refundRequests;

  factory WalletVoucherDetail.fromJson(Map<String, dynamic> json) => WalletVoucherDetail(
        voucher: VoucherItem.fromJson(json),
        stores: asList(json['stores'], WalletStore.fromJson),
        redemption: json['redemption'] is Map<String, dynamic>
            ? Redemption.fromJson(json['redemption'] as Map<String, dynamic>)
            : null,
        refundRequests: asList(json['refundRequests'], RefundRequest.fromJson),
      );
}

// Token redeem: QR dong + OTP 6 so, het han sau 60 giay (FR-REDEEM-02/03)
class RedeemToken {
  const RedeemToken({required this.qrPayload, required this.otpCode, required this.expiresAt, required this.ttlSeconds});

  final String qrPayload;
  final String otpCode;
  final DateTime expiresAt;
  final int ttlSeconds;

  factory RedeemToken.fromJson(Map<String, dynamic> json) => RedeemToken(
        qrPayload: json['qrPayload'] as String,
        otpCode: json['otpCode'] as String,
        expiresAt: asDate(json['expiresAt']),
        ttlSeconds: asInt(json['ttlSeconds'], 60),
      );
}

// Yeu cau hoan tien (FR-REFUND-07): trang thai + ly do, so tien, ma giao dich hoan
class RefundRequest {
  const RefundRequest({
    required this.id,
    required this.voucherItemId,
    required this.status,
    required this.createdAt,
    this.reason,
    this.rejectReason,
    this.decidedAt,
    this.amount,
    this.campaignTitle,
    this.voucherCode,
    this.gatewayRefundId,
  });

  final String id;
  final String voucherItemId;
  final String status;
  final String? reason;
  final String? rejectReason;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final double? amount;
  final String? campaignTitle;
  final String? voucherCode;
  final String? gatewayRefundId;

  String get statusLabel => refundStatusLabels[status] ?? status;

  // Chua co ket qua cuoi cung
  bool get isOpen => const {'REQUESTED', 'PROCESSING', 'MANUAL_PENDING'}.contains(status);

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    final paymentRefund = json['paymentRefund'] is Map ? json['paymentRefund'] as Map : null;
    return RefundRequest(
      id: json['id'] as String,
      voucherItemId: json['voucherItemId'] as String? ?? '',
      status: json['status'] as String? ?? 'REQUESTED',
      reason: json['reason'] as String?,
      rejectReason: json['rejectReason'] as String?,
      createdAt: asDate(json['createdAt']),
      decidedAt: asDateOrNull(json['decidedAt']),
      amount: asDoubleOrNull(json['amount']),
      campaignTitle: json['campaignTitle'] as String?,
      voucherCode: json['voucherCode'] as String?,
      gatewayRefundId: (paymentRefund?['gatewayRefundId'] ?? json['gatewayRefundId']) as String?,
    );
  }
}
