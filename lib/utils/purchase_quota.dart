import '../models/campaign.dart';
import '../models/order.dart';

// BR-01: so voucher khach con duoc mua cua mot chien dich. Voucher da hoan tien khong tinh, don con giu cho van tinh.
// Cung quy tac voi may chu de gio hang va man mua hang hien dung so luong thuc te; may chu van kiem tra lai khi tao don.
int remainingPurchaseQuota(
  VoucherCampaign campaign,
  Iterable<VoucherItem> wallet,
  Iterable<Order> orders,
  DateTime now,
) {
  final limit = campaign.limitPerUser ?? 5;
  final owned = wallet.where((v) => v.campaignId == campaign.id && v.status != 'REFUNDED').length;
  final pending = orders
      .where((o) => o.campaignId == campaign.id && o.canRetry(now))
      .fold<int>(0, (sum, o) => sum + o.quantity);
  final remaining = limit - owned - pending;
  return remaining < 0 ? 0 : remaining;
}

// So luong thuc te mua duoc ngay luc nay: khong qua gioi han con lai va ton kho
int buyableQuantity(VoucherCampaign campaign, int remainingQuota) =>
    campaign.availableQuantity < remainingQuota ? campaign.availableQuantity : remainingQuota;
