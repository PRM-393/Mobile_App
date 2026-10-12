import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// FR-ORDER-09: lich su don hang kem trang thai thanh toan
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
                  return Card(
                    child: ListTile(
                      title: Text(formatVnd(o.totalAmount), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Số lượng: ${o.quantity} · ${formatDateTime(o.createdAt)}'),
                      trailing: Text(orderStatusLabels[o.status] ?? o.status,
                          style: TextStyle(color: _statusColor(o.status), fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}
