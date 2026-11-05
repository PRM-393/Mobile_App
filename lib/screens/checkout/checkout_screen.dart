import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../routes.dart';
import 'payment_result_screen.dart';
import '../../services/notification_service.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/payment_link.dart';
import '../../widgets/common.dart';

// Mo man mua hang tu gio: mang theo so luong da chon
class CheckoutArgs {
  const CheckoutArgs({required this.campaign, required this.quantity});

  final VoucherCampaign campaign;
  final int quantity;
}

// UC-01: chon so luong, tao don (giu ton kho 15 phut), chuyen sang cong thanh toan sandbox - FR-ORDER-01..05.
// Ket qua thanh toan chi duoc cong nhan qua webhook phia may chu, app khong tu ket luan (FR-ORDER-05).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.campaign, this.initialQuantity = 1});

  final VoucherCampaign campaign;
  final int initialQuantity;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late int _quantity = widget.initialQuantity;
  bool _loading = false;
  String? _error;
  // Don con giu cho cua chinh voucher nay: nhac thanh toan tiep thay vi tao them don
  List<Order> _pendingOrders = const [];

  int get _limit => widget.campaign.limitPerUser ?? 5; // BR-01: mac dinh 5

  // BR-01: voucher da mua va don dang giu cho deu tinh vao gioi han moi tai khoan
  int get _owned {
    final wallet = context.read<WalletProvider?>();
    return wallet?.items.where((v) => v.campaignId == widget.campaign.id).length ?? 0;
  }

  int get _remainingQuota {
    final pending = _pendingOrders.fold<int>(0, (sum, o) => sum + o.quantity);
    return (_limit - _owned - pending).clamp(0, _limit);
  }

  int get _maxQuantity {
    final available = widget.campaign.availableQuantity;
    return available < _remainingQuota ? available : _remainingQuota;
  }

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final now = DateTime.now();
      final orders = await context.read<OrderService>().myOrders();
      if (!mounted) return;
      setState(() {
        _pendingOrders = orders.where((o) => o.campaignId == widget.campaign.id && o.canRetry(now)).toList();
        if (_maxQuantity > 0 && _quantity > _maxQuantity) _quantity = _maxQuantity;
      });
    } catch (_) {
      // khong tai duoc thi may chu van kiem tra gioi han khi tao don
    }
  }

  void _toResult(CreateOrderResult result) => Navigator.pushReplacementNamed(
    context,
    AppRoutes.paymentResult,
    arguments: PaymentResultArgs(order: result.order, paymentUrl: result.paymentUrl),
  );

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = context.read<NotificationService>();
      final cart = context.read<CartProvider?>();
      final result = await context.read<OrderService>().create(
        widget.campaign.id,
        _quantity,
      );
      // Tu day don da ton tai: loi thong bao / mo trinh duyet khong duoc lam khach bam mua lan nua
      cart?.remove(widget.campaign.id);
      // LO7: thong bao cuc bo sau thao tac quan trong (tao don, nhac thanh toan trong 15 phut)
      try {
        await notifications.orderCreated();
      } catch (_) {}
      await openPaymentLink(result.paymentUrl);
      if (!mounted) return;
      // Man ket qua tu hoi trang thai don tu may chu (FR-ORDER-05)
      _toResult(result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continuePending(Order order) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<OrderService>().retryPayment(order.id);
      await openPaymentLink(result.paymentUrl);
      if (mounted) _toResult(result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // The tom tat don: logo thuong hieu, ten voucher, bo chon so luong
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrandAvatar(imageUrl: c.image, size: 56),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Đơn giá ${formatVnd(c.salePrice)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Số lượng',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: _quantity < _maxQuantity
                            ? () => setState(() => _quantity++)
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                  Text(
                    _maxQuantity > 0
                        ? 'Mỗi tài khoản mua tối đa $_limit voucher. Bạn còn được mua $_maxQuantity.'
                        : _remainingQuota == 0
                        ? 'Bạn đã đạt giới hạn $_limit voucher của chiến dịch này.'
                        : 'Voucher đã hết hàng.',
                    key: const Key('quota-hint'),
                    style: TextStyle(
                      color: _maxQuantity > 0 ? AppColors.textSecondary : AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Chi tiết thanh toán',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                DetailRow('Đơn giá', formatVnd(c.salePrice)),
                DetailRow('Số lượng', 'x$_quantity'),
                const Divider(height: AppSpacing.lg),
                DetailRow(
                  'Tổng cộng',
                  formatVnd(c.salePrice * _quantity),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final o in _pendingOrders) ...[
            Card(
              key: const Key('pending-order'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bạn đang có đơn ${o.quantity} voucher chờ thanh toán, giữ chỗ đến ${formatDateTime(o.reservedUntil!)}.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: _loading ? null : () => _continuePending(o),
                      child: const Text('Tiếp tục thanh toán đơn này'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const InfoBanner(
            'Đơn hàng được giữ chỗ trong 15 phút. Nếu không hoàn tất thanh toán, đơn sẽ tự hủy '
            'và trả lại tồn kho.',
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          const InfoBanner(
            'Thanh toán xong, voucher tự vào tab Ví voucher. Khi dùng tại cửa hàng, mở ví để lấy mã QR.',
            icon: Icons.account_balance_wallet_outlined,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(
              _error!,
              icon: Icons.error_outline,
              tone: StatusTone.danger,
            ),
          ],
        ],
      ),
      // Thanh hanh dong co dinh: tong tien + nut thanh toan
      bottomNavigationBar: StickyActionBar(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formatVnd(c.salePrice * _quantity),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: 'Xác nhận thanh toán',
                loading: _loading,
                onPressed: _maxQuantity > 0 ? _pay : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
