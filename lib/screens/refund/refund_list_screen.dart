import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// FR-REFUND-07: khach theo doi trang thai cac yeu cau hoan tien
class RefundListScreen extends StatefulWidget {
  const RefundListScreen({super.key});

  @override
  State<RefundListScreen> createState() => _RefundListScreenState();
}

class _RefundListScreenState extends State<RefundListScreen> {
  late Future<List<RefundRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<RefundService>().myRequests();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Yêu cầu hoàn tiền')),
        body: FutureBuilder<List<RefundRequest>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LoadingState();
            if (snap.hasError) return ErrorState(snap.error.toString());
            final items = snap.data!;
            if (items.isEmpty) return const EmptyState('Bạn chưa gửi yêu cầu hoàn tiền nào.');
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final r = items[i];
                return Card(
                  child: ListTile(
                    title: Text(refundStatusLabels[r.status] ?? r.status),
                    subtitle: Text([
                      formatDateTime(r.createdAt),
                      if (r.rejectReason != null) 'Lý do từ chối: ${r.rejectReason}',
                    ].join('\n')),
                  ),
                );
              },
            );
          },
        ),
      );
}
