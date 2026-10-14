import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/wallet_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// FR-REDEEM-01: vi voucher chia theo tab (dang hieu luc / da dung / het han / da hoan)
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
  // va chi rebuild danh sach khi (dang tai, loi, danh sach) thay doi
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ví voucher')),
        body: Column(
          children: [
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
                child: Selector<WalletProvider, (bool, String?, List<VoucherItem>)>(
                  selector: (_, w) => (w.loading, w.error, w.visibleItems),
                  builder: (context, state, _) {
                    final (loading, error, items) = state;
                    final wallet = context.read<WalletProvider>();
                    if (loading && items.isEmpty) return const LoadingState();
                    if (error != null) return ErrorState(error, onRetry: wallet.load);
                    if (items.isEmpty) {
                      return ListView(children: const [EmptyState('Không có voucher nào trong mục này.')]);
                    }
                    // ListView.separated dung builder: chi dung widget cho cac dong dang hien tren man hinh
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) => _VoucherTile(key: ValueKey(items[i].id), item: items[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
}

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({super.key, required this.item});

  final VoucherItem item;

  @override
  Widget build(BuildContext context) {
    final status = item.effectiveStatus;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.campaign?.title ?? 'Voucher', style: const TextStyle(fontWeight: FontWeight.w700)),
            // Ma dinh danh chi de tra cuu / khieu nai, khong dung de redeem (BR-16)
            Text('Mã tra cứu: ${item.code}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text('Hạn sử dụng: ${formatDateTime(item.expireAt)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (item.usedAt != null)
              Text('Đã dùng lúc: ${formatDateTime(item.usedAt!)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (status == 'ACTIVE') ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => AppRoutes.push(context, AppRoutes.redeemQr, arguments: item),
                      child: const Text('Sử dụng ngay'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => AppRoutes.push(context, AppRoutes.refundRequest, arguments: item),
                    child: const Text('Hoàn tiền'),
                  ),
                ],
              ),
            ],
            if (status == 'USED')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => AppRoutes.push(context, AppRoutes.review, arguments: item),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Đánh giá'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
