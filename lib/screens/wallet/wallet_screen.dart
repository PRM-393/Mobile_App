import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/wallet_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../engage/review_screen.dart';

// FR-REDEEM-01: vi voucher chia theo tab (dang hieu luc / da dung / het han / da hoan).
// Mat mang: hien vi da luu (SQLite), an nut sinh ma va noi ro ly do (NFR-MOB-12, LIM-07).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<WalletProvider>().load());
  }

  // Module 12: khong watch ca provider; Selector chi rebuild thanh tab khi doi tab,
  // va chi rebuild danh sach khi (dang tai, loi, danh sach, offline) thay doi
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ví voucher')),
        body: Column(
          children: [
            Selector<WalletProvider, (bool, DateTime?)>(
              selector: (_, w) => (w.offline, w.cachedAt),
              builder: (context, state, _) {
                final (offline, cachedAt) = state;
                return offline ? OfflineBanner(cachedAt: cachedAt) : const SizedBox.shrink();
              },
            ),
            SizedBox(
              height: 52,
              child: Selector<WalletProvider, String>(
                selector: (_, w) => w.tab,
                builder: (context, tab, _) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  children: [
                    for (final t in WalletProvider.tabs)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(voucherStatusLabels[t]!),
                          selected: tab == t,
                          onSelected: (_) => context.read<WalletProvider>().selectTab(t),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<WalletProvider>().load(),
                child: Selector<WalletProvider, (bool, String?, List<VoucherItem>, bool)>(
                  selector: (_, w) => (w.loading, w.error, w.visibleItems, w.offline),
                  builder: (context, state, _) {
                    final (loading, error, items, offline) = state;
                    final wallet = context.read<WalletProvider>();
                    if (loading && items.isEmpty) return const LoadingState();
                    if (error != null) {
                      return ListView(children: [ErrorState(error, onRetry: wallet.load)]);
                    }
                    if (items.isEmpty) {
                      return ListView(children: const [EmptyState('Không có voucher nào trong mục này.')]);
                    }
                    // ListView.separated dung builder: chi dung widget cho cac dong dang hien tren man hinh
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) =>
                          _VoucherTile(key: ValueKey(items[i].id), item: items[i], offline: offline),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
}

// Banner khi dang xem du lieu da luu (dung chung o man vi va chi tiet voucher)
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.cachedAt});

  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('wallet-offline-banner'),
        width: double.infinity,
        color: AppColors.secondary.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                [
                  'Mất kết nối – đang xem ví đã lưu${cachedAt == null ? '' : ' lúc ${formatDateTime(cachedAt!)}'}.',
                  'Cần có mạng để tạo mã sử dụng voucher.',
                ].join('\n'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
}

// Nhan trang thai nho tren the voucher (vd. "Đang hoàn tiền" o tab dang hieu luc)
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVE' => AppColors.success,
      'REFUND_PENDING' => AppColors.secondary,
      'USED' => AppColors.primary,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(
        voucherStatusLabels[status] ?? status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({super.key, required this.item, required this.offline});

  final VoucherItem item;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final status = item.effectiveStatus;
    const muted = TextStyle(color: AppColors.textSecondary, fontSize: 12);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppRoutes.push(context, AppRoutes.walletVoucher, arguments: item),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.campaign?.title ?? 'Voucher', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusChip(status),
                ],
              ),
              // Ma dinh danh chi de tra cuu / khieu nai, khong dung de redeem (BR-16)
              Text('Mã tra cứu: ${item.code}', style: muted),
              Text('Hạn sử dụng: ${formatDateTime(item.expireAt)}', style: muted),
              if (item.usedAt != null) Text('Đã dùng lúc: ${formatDateTime(item.usedAt!)}', style: muted),
              if (status == 'REFUND_PENDING')
                const Text('Đang chờ hoàn tiền, tạm thời không sử dụng được.', style: muted),
              if (item.canRedeem) ...[
                const SizedBox(height: AppSpacing.sm),
                if (offline)
                  const Text(
                    'Cần kết nối mạng để tạo mã sử dụng.',
                    key: Key('redeem-offline-hint'),
                    style: TextStyle(color: AppColors.danger, fontSize: 12),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => AppRoutes.push(context, AppRoutes.redeemQr, arguments: item),
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Sử dụng ngay'),
                    ),
                  ),
              ],
              if (status == 'USED' && item.canReview)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => AppRoutes.push(context, AppRoutes.review, arguments: ReviewArgs.fromVoucher(item)),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Đánh giá'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
