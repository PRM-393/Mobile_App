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
import '../../services/notification_service.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/payment_link.dart';
import '../../utils/purchase_quota.dart';
import '../../widgets/common.dart';
import '../checkout/payment_result_screen.dart';

// Gio hang: voucher kem so luong thuc te mua duoc (ton kho + gioi han moi tai khoan). Khach chon cac voucher
// muon mua roi bam mot nut thanh toan o cuoi; may chu tao mot ma QR tong cho tat ca.
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
  // Mac dinh chon moi voucher mua duoc; chi nho nhung voucher khach bo chon
  final Set<String> _unselected = {};
  bool _paying = false;
  String? _error;

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

  bool _canBuy(CartItem item) {
    final live = _live[item.campaignId];
    return !_gone.contains(item.campaignId) &&
        live != null &&
        live.isOnSaleAt(DateTime.now()) &&
        (_buyable[item.campaignId] ?? 0) > 0;
  }

  Future<void> _pay(List<CartItem> selected) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      if (!mounted || !auth.isLoggedIn) return;
      // Dang nhap xong: tinh lai gioi han mua theo tai khoan roi de khach bam thanh toan
      await _load();
      return;
    }
    final cart = context.read<CartProvider>();
    final orderService = context.read<OrderService>();
    final notifications = context.read<NotificationService>();
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final result = await orderService.checkout([
        for (final item in selected) (campaignId: item.campaignId, quantity: item.quantity),
      ]);
      // Tu day don da ton tai: bo khoi gio de khach khong mua lan nua
      for (final item in selected) {
        cart.remove(item.campaignId);
      }
      try {
        await notifications.orderCreated();
      } catch (_) {}
      final first = result.orders.first;
      if (first.paymentQr == null) await openPaymentLink(result.paymentUrl);
      if (!mounted) return;
      await AppRoutes.push(
        context,
        AppRoutes.paymentResult,
        arguments: PaymentResultArgs(order: first, paymentUrl: result.paymentUrl, groupOrders: result.orders),
      );
      if (mounted) await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      await _load();
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _explore() {
    context.read<MainTabController>().go(MainTabController.home);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final buyable = cart.items.where(_canBuy).toList();
    final selected = buyable.where((e) => !_unselected.contains(e.campaignId)).toList();
    final total = selected.fold<double>(0, (sum, e) => sum + e.subtotal);
    final quantity = selected.fold<int>(0, (sum, e) => sum + e.quantity);
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
                  if (_error != null) ...[
                    InfoBanner(_error!, icon: Icons.error_outline, tone: StatusTone.danger),
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
                        selected: _canBuy(item) && !_unselected.contains(item.campaignId),
                        onSelected: (value) => setState(() {
                          value ? _unselected.remove(item.campaignId) : _unselected.add(item.campaignId);
                        }),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : StickyActionBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        key: const Key('cart-select-all'),
                        value: buyable.isNotEmpty && selected.length == buyable.length,
                        onChanged: buyable.isEmpty
                            ? null
                            : (value) => setState(() {
                                  _unselected.clear();
                                  if (value != true) _unselected.addAll(buyable.map((e) => e.campaignId));
                                }),
                      ),
                      const Text('Chọn tất cả'),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Tổng tiền', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(
                            formatVnd(total),
                            key: const Key('cart-total'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    key: const Key('cart-pay'),
                    label: quantity == 0 ? 'Chọn voucher để thanh toán' : 'Thanh toán $quantity voucher',
                    loading: _paying,
                    onPressed: selected.isEmpty || _loading ? null : () => _pay(selected),
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
    required this.selected,
    required this.onSelected,
  });

  final CartItem item;
  final VoucherCampaign? campaign;
  final int? buyable;
  final bool gone;
  final bool selected;
  final ValueChanged<bool> onSelected;

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
                  Checkbox(
                    key: Key('cart-select-${item.campaignId}'),
                    value: selected,
                    onChanged: blocked != null || live == null ? null : (value) => onSelected(value ?? false),
                  ),
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
            ],
          ],
        ),
      ),
    );
  }
}
