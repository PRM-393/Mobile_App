import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/main_tab_controller.dart';
import '../../providers/wallet_provider.dart';
import '../../routes.dart';
import '../../services/api_client.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/purchase_quota.dart';
import '../../widgets/common.dart';
import '../checkout/checkout_screen.dart';

// Gio hang: voucher da chon kem so luong thuc te mua duoc (ton kho + gioi han moi tai khoan), mua tung voucher.
// Mo gio la lay lai gia, ton kho va so da mua tu may chu.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Map<String, VoucherCampaign> _live = {};
  final Set<String> _gone = {};
  // So luong thuc te mua duoc cua tung voucher
  final Map<String, int> _buyable = {};
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final search = context.read<SearchService>();
    final cart = context.read<CartProvider>();
    final wallet = context.read<WalletProvider?>();
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    final orderService = context.read<OrderService>();
    setState(() {
      _loading = true;
      _offline = false;
    });
    var orders = const <Order>[];
    if (loggedIn) {
      try {
        orders = await orderService.myOrders();
      } catch (_) {
        // khong tai duoc thi may chu van kiem tra gioi han khi tao don
      }
    }
    final now = DateTime.now();
    await Future.wait(cart.items.map((item) async {
      try {
        final campaign = await search.detail(item.campaignId);
        final quota = remainingPurchaseQuota(campaign, wallet?.items ?? const [], orders, now);
        final buyable = buyableQuantity(campaign, quota);
        _live[item.campaignId] = campaign;
        _buyable[item.campaignId] = buyable;
        _gone.remove(item.campaignId);
        cart.syncWith(campaign, buyable: buyable);
      } on ApiException catch (e) {
        if (e.isNetworkError) {
          _offline = true;
        } else {
          _live.remove(item.campaignId);
          _gone.add(item.campaignId);
        }
      }
    }));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _buy(VoucherCampaign campaign, int quantity) async {
    await AppRoutes.push(context, AppRoutes.checkout, arguments: CheckoutArgs(campaign: campaign, quantity: quantity));
    if (mounted) await _load();
  }

  void _explore() {
    context.read<MainTabController>().go(MainTabController.home);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(cart.items.isEmpty ? 'Giỏ hàng' : 'Giỏ hàng (${cart.totalQuantity})')),
      body: cart.items.isEmpty
          ? Center(
              child: EmptyState(
                'Giỏ hàng đang trống. Bấm biểu tượng giỏ ở trang chi tiết voucher để thêm.',
                icon: Icons.shopping_cart_outlined,
                actionLabel: 'Khám phá ưu đãi',
                onAction: _explore,
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (_offline) ...[
                    const InfoBanner(
                      'Mất kết nối: giá và số lượng còn lại có thể đã thay đổi.',
                      icon: Icons.cloud_off_outlined,
                      tone: StatusTone.warning,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  for (final item in cart.items)
                    Padding(
                      key: ValueKey(item.campaignId),
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CartLine(
                        item: item,
                        campaign: _live[item.campaignId],
                        buyable: _buyable[item.campaignId],
                        gone: _gone.contains(item.campaignId),
                        loading: _loading,
                        onBuy: _buy,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.campaign,
    required this.buyable,
    required this.gone,
    required this.loading,
    required this.onBuy,
  });

  final CartItem item;
  final VoucherCampaign? campaign;
  final int? buyable;
  final bool gone;
  final bool loading;
  final Future<void> Function(VoucherCampaign campaign, int quantity) onBuy;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final live = campaign;
    final now = DateTime.now();
    final onSale = live != null && live.isOnSaleAt(now);
    final String? blocked = gone
        ? 'Voucher này đã ngừng bán. Hãy xóa khỏi giỏ.'
        : live != null && !onSale
        ? '${live.unavailableLabelAt(now)}. Hãy xóa khỏi giỏ hoặc quay lại sau.'
        : buyable == 0
        ? 'Bạn đã đạt giới hạn mua của voucher này. Hãy xóa khỏi giỏ.'
        : null;
    final max = buyable;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: gone ? null : () => Navigator.pushNamed(context, AppRoutes.voucherDetail, arguments: item.campaignId),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandAvatar(imageUrl: item.image, size: 52),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.3),
                        ),
                        if (item.brandName != null)
                          Text(item.brandName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Đơn giá ${formatVnd(item.unitPrice)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('cart-remove-${item.campaignId}'),
                    tooltip: 'Xóa khỏi giỏ',
                    onPressed: () => cart.remove(item.campaignId),
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (blocked != null)
              InfoBanner(blocked, icon: Icons.block, tone: StatusTone.warning)
            else ...[
              Row(
                children: [
                  IconButton.outlined(
                    key: Key('cart-minus-${item.campaignId}'),
                    tooltip: 'Giảm số lượng',
                    onPressed: item.quantity > 1 ? () => cart.setQuantity(item.campaignId, item.quantity - 1) : null,
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  IconButton.outlined(
                    key: Key('cart-plus-${item.campaignId}'),
                    tooltip: 'Tăng số lượng',
                    onPressed: max != null && item.quantity < max ? () => cart.setQuantity(item.campaignId, item.quantity + 1) : null,
                    icon: const Icon(Icons.add, size: 18),
                  ),
                  const Spacer(),
                  Text(formatVnd(item.subtotal), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: Key('cart-buy-${item.campaignId}'),
                  onPressed: onSale ? () => onBuy(live, item.quantity) : null,
                  child: Text(loading && live == null ? 'Đang kiểm tra...' : 'Mua ${item.quantity} voucher'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
