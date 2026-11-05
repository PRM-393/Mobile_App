import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/main_tab_controller.dart';
import '../../providers/wallet_provider.dart';
import '../../routes.dart';
import '../checkout/payment_result_screen.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/payment_link.dart';
import '../../widgets/common.dart';

// FR-ORDER-09: lich su don hang kem trang thai thanh toan; FR-ORDER-12: thanh toan lai trong 15 phut giu cho
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _future;
  MainTabController? _tabs;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderService>().myOrders();
    _tabs = context.read<MainTabController?>()?..addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTabChanged);
    super.dispose();
  }

  // Vua mua xong chuyen sang tab Don hang thi phai thay don moi
  void _onTabChanged() {
    if (_tabs?.index == MainTabController.orders && mounted) _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _future = context.read<OrderService>().myOrders(); });
    await _future;
  }

  // Lay link payOS tu may chu, mo trang thanh toan roi sang man ket qua de theo doi
  Future<void> _retry(Order order) async {
    try {
      final result = await context.read<OrderService>().retryPayment(order.id);
      await openPaymentLink(result.paymentUrl);
      if (!mounted) return;
      await AppRoutes.push(
        context,
        AppRoutes.paymentResult,
        arguments: PaymentResultArgs(order: result.order, paymentUrl: result.paymentUrl),
      );
      if (mounted) await _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _open(Order order) async {
    await AppRoutes.push(context, AppRoutes.paymentResult, arguments: PaymentResultArgs(order: order));
    if (mounted) await _refresh();
  }

  // Don da phat hanh: nhay thang toi voucher trong vi
  void _openWallet() {
    context.read<WalletProvider?>()?.selectTab('ACTIVE');
    context.read<MainTabController>().go(MainTabController.wallet);
  }

  Future<void> _buyAgain(Order order) async {
    await AppRoutes.push(context, AppRoutes.voucherDetail, arguments: order.campaignId);
    if (mounted) await _refresh();
  }

  StatusTone _statusTone(String status) => switch (status) {
    'FULFILLED' || 'PAID' => StatusTone.success,
    'PENDING' => StatusTone.warning,
    _ => StatusTone.danger,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đơn hàng')),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingState();
          if (snap.hasError) return ErrorState(snap.error.toString(), onRetry: _refresh);
          final orders = snap.data!;
          if (orders.isEmpty) {
            return ListView(
              children: [
                EmptyState(
                  'Chưa có đơn hàng nào.',
                  icon: Icons.receipt_long_outlined,
                  actionLabel: 'Khám phá ưu đãi',
                  onAction: () =>
                      context.read<MainTabController>().go(MainTabController.home),
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final o = orders[i];
              final canRetry = o.canRetry(DateTime.now());
              final expired = o.status == 'PENDING' && !canRetry;
              return Card(
                key: ValueKey(o.id),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(o),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dong dau: ma don + nhan trang thai
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${o.id.length > 8 ? o.id.substring(0, 8).toUpperCase() : o.id.toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            StatusPill(
                              expired ? 'Hết thời gian giữ chỗ' : orderStatusLabels[o.status] ?? o.status,
                              tone: expired ? StatusTone.danger : _statusTone(o.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          o.campaignTitle ?? 'Đơn hàng',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SL ${o.quantity} · ${formatDateTime(o.createdAt)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (canRetry)
                          Text(
                            'Giữ chỗ đến ${formatDateTime(o.reservedUntil!)}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatVnd(o.totalAmount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (canRetry)
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                ),
                                onPressed: () => _retry(o),
                                child: const Text('Thanh toán lại'),
                              )
                            else if (o.status == 'FULFILLED')
                              FilledButton(
                                key: Key('order-wallet-${o.id}'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                ),
                                onPressed: _openWallet,
                                child: const Text('Xem voucher'),
                              )
                            else if (expired || o.status == 'CANCELLED')
                              OutlinedButton(
                                key: Key('order-again-${o.id}'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                ),
                                onPressed: () => _buyAgain(o),
                                child: const Text('Mua lại'),
                              )
                            else
                              TextButton(
                                onPressed: () => _open(o),
                                child: const Text('Chi tiết'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
