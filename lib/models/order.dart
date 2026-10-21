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
  'MANUAL_PENDING': 'Chờ quản trị viên hoàn tay',
  'COMPLETED': 'Hoàn tiền thành công',
  'REJECTED': 'Bị từ chối',
  'FAILED': 'Hoàn tiền thất bại',
};

class Order {
  const Order({
    required this.id,
    required this.campaignId,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String campaignId;
  final int quantity;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    campaignId: json['campaignId'] as String? ?? '',
    quantity: asInt(json['quantity']),
    totalAmount: asDouble(json['totalAmount']),
    status: json['status'] as String? ?? 'PENDING',
    createdAt: asDate(json['createdAt']),
  );
}

// Phan hoi POST /orders: don PENDING + duong dan cong thanh toan sandbox (FR-ORDER-04)
class CreateOrderResult {
  const CreateOrderResult({required this.order, required this.paymentUrl});

  final Order order;
  final String paymentUrl;

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) =>
      CreateOrderResult(
        order: Order.fromJson(json['order'] as Map<String, dynamic>),
        paymentUrl: json['paymentUrl'] as String? ?? '',
      );
}

// Voucher cu the cua khach trong vi (GET /wallet)
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
    this.campaign,
  });

  final String id;
  final String orderId;
  final String campaignId;
  final String code;
  final String status;
  final DateTime issuedAt;
  final DateTime? usedAt;
  final DateTime expireAt;
  final VoucherCampaign? campaign;

  // Het han xet theo expireAt so voi hien tai, khong cho tac vu nen cap nhat trang thai
  String get effectiveStatus =>
      status == 'ACTIVE' && expireAt.isBefore(DateTime.now())
      ? 'EXPIRED'
      : status;

  factory VoucherItem.fromJson(Map<String, dynamic> json) => VoucherItem(
    id: json['id'] as String,
    orderId: json['orderId'] as String? ?? '',
    campaignId: json['campaignId'] as String? ?? '',
    code: json['code'] as String? ?? '',
    status: json['status'] as String? ?? 'ACTIVE',
    issuedAt: asDate(json['issuedAt']),
    usedAt: asDateOrNull(json['usedAt']),
    expireAt: asDate(json['expireAt']),
    campaign: json['campaign'] is Map<String, dynamic>
        ? VoucherCampaign.fromJson(json['campaign'] as Map<String, dynamic>)
        : null,
  );
}

// Token redeem: QR dong + OTP 6 so, het han sau 60 giay (FR-REDEEM-02/03)
class RedeemToken {
  const RedeemToken({
    required this.qrPayload,
    required this.otpCode,
    required this.expiresAt,
    required this.ttlSeconds,
  });

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

class RefundRequest {
  const RefundRequest({
    required this.id,
    required this.voucherItemId,
    required this.status,
    required this.createdAt,
    this.reason,
    this.rejectReason,
  });

  final String id;
  final String voucherItemId;
  final String status;
  final String? reason;
  final String? rejectReason;
  final DateTime createdAt;

  factory RefundRequest.fromJson(Map<String, dynamic> json) => RefundRequest(
    id: json['id'] as String,
    voucherItemId: json['voucherItemId'] as String? ?? '',
    status: json['status'] as String? ?? 'REQUESTED',
    reason: json['reason'] as String?,
    rejectReason: json['rejectReason'] as String?,
    createdAt: asDate(json['createdAt']),
  );
}
