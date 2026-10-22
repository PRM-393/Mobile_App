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
            // The tong quan: so voucher dang hieu luc + tong gia tri
            Selector<WalletProvider, List<VoucherItem>>(
              selector: (_, w) => w.items,
              builder: (context, items, _) {
                final active = items.where((e) => e.canRedeem).toList();
                final value = active.fold<double>(
                  0,
                  (sum, e) => sum + (e.campaign?.faceValue ?? 0),
                );
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: GradientHeaderCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${active.length} voucher khả dụng',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tổng giá trị ${formatVnd(value)}',
                                style: const TextStyle(
                                  color: Color(0xFFD9FFF3),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(
              height: 60,
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
                          showCheckmark: false,
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
                      return ListView(
                        children: const [
                          EmptyState(
                            'Không có voucher nào trong mục này.',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ],
                      );
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
        child: InfoBanner(
          [
            'Mất kết nối – đang xem ví đã lưu${cachedAt == null ? '' : ' lúc ${formatDateTime(cachedAt!)}'}.',
            'Cần có mạng để tạo mã sử dụng voucher.',
          ].join('\n'),
          icon: Icons.cloud_off_outlined,
          tone: StatusTone.warning,
        ),
      );
}

// Nhan trang thai nho tren the voucher (vd. "Đang hoàn tiền" o tab dang hieu luc)
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      'ACTIVE' => StatusTone.success,
      'REFUND_PENDING' => StatusTone.warning,
      'USED' => StatusTone.primary,
      _ => StatusTone.neutral,
    };
    return StatusPill(voucherStatusLabels[status] ?? status, tone: tone);
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
                  BrandAvatar(imageUrl: item.campaign?.image, size: 52),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.campaign?.title ?? 'Voucher',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusChip(status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              // Ma dinh danh chi de tra cuu / khieu nai, khong dung de redeem (BR-16)
              Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Mã tra cứu ${item.code}', style: muted),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.event_available_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text('HSD ${formatDateTime(item.expireAt)}', style: muted),
                ],
              ),
              if (item.usedAt != null) Text('Đã dùng lúc: ${formatDateTime(item.usedAt!)}', style: muted),
              if (status == 'REFUND_PENDING') ...[
                const SizedBox(height: AppSpacing.sm),
                const InfoBanner(
                  'Đang chờ hoàn tiền, tạm thời không sử dụng được.',
                  tone: StatusTone.warning,
                ),
              ],
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
