import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// FR-SEARCH-07: chi tiet voucher - gia, gia tri, dieu kien, han dung, chi nhanh ap dung, so luong con lai
class VoucherDetailScreen extends StatefulWidget {
  const VoucherDetailScreen({super.key, required this.campaignId});

  final String campaignId;

  @override
  State<VoucherDetailScreen> createState() => _VoucherDetailScreenState();
}

class _VoucherDetailScreenState extends State<VoucherDetailScreen> {
  late Future<VoucherCampaign> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<SearchService>().detail(widget.campaignId);
  }

  Future<void> _toggleFavorite() async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<EngageService>().toggleFavorite('CAMPAIGN', widget.campaignId);
      messenger.showSnackBar(const SnackBar(content: Text('Đã cập nhật danh sách yêu thích')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết voucher'),
          actions: [IconButton(onPressed: _toggleFavorite, icon: const Icon(Icons.favorite_border))],
        ),
        body: FutureBuilder<VoucherCampaign>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LoadingState();
            if (snap.hasError) return ErrorState(snap.error.toString());
            return _Detail(campaign: snap.data!);
          },
        ),
      );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.campaign});

  final VoucherCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final canBuy = c.availableQuantity > 0 && c.status == 'PUBLISHED' && DateTime.now().isBefore(c.saleEndAt);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: c.image == null || c.image!.isEmpty
                      ? Container(color: AppColors.border, child: const Icon(Icons.local_offer_outlined, size: 48))
                      // Module 12: giai ma anh theo be rong man hinh
                      : Image.network(c.image!,
                          fit: BoxFit.cover,
                          cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
                          errorBuilder: (_, _, _) => Container(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(c.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(voucherTypeLabels[c.voucherType] ?? c.voucherType, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              Text(formatVnd(c.salePrice),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text('Giá trị: ${formatVnd(c.faceValue)}', style: const TextStyle(color: AppColors.textSecondary)),
              Text('Còn lại: ${c.availableQuantity} voucher', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              SectionCard(title: 'Điều kiện áp dụng', child: Text(c.terms ?? c.description ?? 'Đang cập nhật.')),
              const SizedBox(height: AppSpacing.sm),
              SectionCard(title: 'Hạn sử dụng', child: Text(formatDateTime(c.voucherExpireAt))),
              const SizedBox(height: AppSpacing.sm),
              const SectionCard(
                title: 'Chính sách hoàn tiền',
                child: Text('Được hoàn tiền trong 7 ngày kể từ khi mua nếu chưa sử dụng '
                    'và còn ít nhất 3 ngày trước hạn sử dụng (BR-05).'),
              ),
              if (c.stores.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                SectionCard(
                  title: 'Chi nhánh áp dụng',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in c.stores)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.store_outlined),
                          title: Text(s.name),
                          subtitle: Text(s.address),
                          trailing: s.distanceKm == null ? null : Text(formatDistance(s.distanceKm!)),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: PrimaryButton(
              label: canBuy ? 'Mua ngay' : 'Hết hàng / ngừng bán',
              onPressed: canBuy ? () => AppRoutes.push(context, AppRoutes.checkout, arguments: c) : null,
            ),
          ),
        ),
      ],
    );
  }
}
