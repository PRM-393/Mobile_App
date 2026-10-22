import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// FR-REFUND-07: khach theo doi trang thai cac yeu cau hoan tien (keo xuong de tai lai)
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

  Future<void> _reload() async {
    final future = context.read<RefundService>().myRequests();
    setState(() => _future = future);
    await future.catchError((_) => <RefundRequest>[]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Yêu cầu hoàn tiền')),
        body: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<RefundRequest>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const LoadingState();
              if (snap.hasError) return ListView(children: [ErrorState(snap.error.toString(), onRetry: _reload)]);
              final items = snap.data!;
              if (items.isEmpty) {
                return ListView(
                  children: const [
                    EmptyState(
                      'Bạn chưa gửi yêu cầu hoàn tiền nào.',
                      icon: Icons.currency_exchange,
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _RefundCard(key: ValueKey(items[i].id), request: items[i]),
              );
            },
          ),
        ),
      );
}

class _RefundCard extends StatelessWidget {
  const _RefundCard({super.key, required this.request});

  final RefundRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    const muted = TextStyle(color: AppColors.textSecondary, fontSize: 12);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    r.campaignTitle ?? 'Voucher',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (r.voucherCode != null) Text('Mã tra cứu ${r.voucherCode}', style: muted),
            if (r.amount != null)
              Text(
                formatVnd(r.amount!),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _Timeline(request: r),
            if (r.rejectReason != null) ...[
              const SizedBox(height: AppSpacing.sm),
              InfoBanner(
                'Lý do: ${r.rejectReason}',
                icon: Icons.info_outline,
                tone: StatusTone.danger,
              ),
            ],
            if (r.gatewayRefundId != null) Text('Mã giao dịch hoàn: ${r.gatewayRefundId}', style: muted),
          ],
        ),
      ),
    );
  }
}

// Cac buoc: Da gui -> Dang xu ly (hoac Cho quan tri vien) -> Ket qua (thanh cong / that bai / khong du dieu kien)
class _Timeline extends StatelessWidget {
  const _Timeline({required this.request});

  final RefundRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final finalStep = switch (r.status) {
      'COMPLETED' => ('Hoàn tiền thành công', AppColors.success, Icons.check_circle),
      'FAILED' => ('Hoàn tiền không thành công', AppColors.danger, Icons.cancel),
      'REJECTED' => ('Không đủ điều kiện', AppColors.danger, Icons.cancel),
      _ => ('Chờ kết quả', AppColors.textSecondary, Icons.radio_button_unchecked),
    };
    final steps = <(String, String?, Color, IconData)>[
      ('Đã gửi yêu cầu', formatDateTime(r.createdAt), AppColors.success, Icons.check_circle),
      if (r.status != 'REJECTED')
        (
          r.status == 'MANUAL_PENDING' ? 'Chờ quản trị viên hoàn tiền' : 'Đang xử lý qua cổng thanh toán',
          null,
          r.isOpen ? AppColors.secondary : AppColors.success,
          r.isOpen ? Icons.timelapse : Icons.check_circle,
        ),
      (finalStep.$1, r.decidedAt == null ? null : formatDateTime(r.decidedAt!), finalStep.$2, finalStep.$3),
    ];
    return Column(
      key: Key('refund-timeline-${r.status}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, time, color, icon) in steps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(label, style: TextStyle(color: color == AppColors.textSecondary ? color : null))),
                if (time != null) Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }
}
