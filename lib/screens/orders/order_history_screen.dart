import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../models/order.dart';
import '../../routes.dart';
import '../checkout/payment_result_screen.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// FR-ORDER-09: lich su don hang kem trang thai thanh toan; FR-ORDER-12: thanh toan lai trong 15 phut giu cho
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderService>().myOrders();
  }

  Future<void> _refresh() async {
    setState(() => _future = context.read<OrderService>().myOrders());
    await _future;
  }

  // Lay link payOS cu tu may chu roi mo man ket qua (man nay tu mo payOS / thanh toan thu)
  Future<void> _retry(Order order) async {
    try {
      final result = await context.read<OrderService>().retryPayment(order.id);
      final uri = Uri.tryParse(result.paymentUrl ?? '');
      if (uri != null && uri.hasScheme) await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  Color _statusColor(String status) => switch (status) {
    'FULFILLED' || 'PAID' => AppColors.success,
    'PENDING' => AppColors.secondary,
    _ => AppColors.danger,
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
          if (orders.isEmpty) return ListView(children: const [EmptyState('Chưa có đơn hàng nào.')]);
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final o = orders[i];
              final canRetry = o.canRetry(DateTime.now());
              return Card(
                key: ValueKey(o.id),
                child: ListTile(
                  onTap: () => _open(o),
                  title: Text(
                    o.campaignTitle ?? formatVnd(o.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${formatVnd(o.totalAmount)} · SL ${o.quantity} · ${formatDateTime(o.createdAt)}'
                    '${canRetry ? '\nGiữ chỗ đến ${formatDateTime(o.reservedUntil!)}' : ''}',
                  ),
                  isThreeLine: canRetry,
                  trailing: canRetry
                      ? FilledButton(
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                          onPressed: () => _retry(o),
                          child: const Text('Thanh toán lại'),
                        )
                      : Text(
                          orderStatusLabels[o.status] ?? o.status,
                          style: TextStyle(color: _statusColor(o.status), fontWeight: FontWeight.w600),
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
