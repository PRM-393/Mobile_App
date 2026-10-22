import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance.dart';
import '../../providers/search_provider.dart';
import '../search/store_map_screen.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../engage/campaign_reviews_section.dart';

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
    _future = context.read<SearchService>().detail(
      widget.campaignId,
      lat: context.read<SearchProvider>().latitude,
      lng: context.read<SearchProvider>().longitude,
    );
  }

  Future<void> _toggleFavorite() async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<EngageService>().toggleFavorite(
        'CAMPAIGN',
        widget.campaignId,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã cập nhật danh sách yêu thích')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chi tiết voucher'),
      actions: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: const Icon(Icons.favorite_border),
        ),
      ],
    ),
    body: FutureBuilder<VoucherCampaign>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingState();
        }
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
    final canBuy =
        c.availableQuantity > 0 &&
        c.status == 'PUBLISHED' &&
        !DateTime.now().isBefore(c.saleStartAt) &&
        DateTime.now().isBefore(c.saleEndAt);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Anh bia tran vien
              AspectRatio(
                aspectRatio: 16 / 9,
                child: c.image == null || c.image!.isEmpty
                    ? Container(
                        color: AppColors.primarySoft,
                        child: const Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      )
                    // Module 12: giai ma anh theo be rong man hinh
                    : Image.network(
                        c.image!,
                        fit: BoxFit.cover,
                        cacheWidth:
                            (MediaQuery.sizeOf(context).width *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        errorBuilder: (_, _, _) =>
                            Container(color: AppColors.primarySoft),
                      ),
              ),
              // The trang bo goc lon chong len anh: ten, gia, ton kho
              Transform.translate(
                offset: const Offset(0, -AppSpacing.lg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusPill(
                                voucherTypeLabels[c.voucherType] ?? c.voucherType,
                                tone: StatusTone.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              if (c.savingPercent != null && c.savingPercent! > 0)
                                StatusPill(
                                  '-${c.savingPercent}%',
                                  tone: StatusTone.warning,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            c.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                formatVnd(c.salePrice),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (c.faceValue > c.salePrice)
                                Text(
                                  formatVnd(c.faceValue),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Divider(),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Còn ${c.availableQuantity} voucher',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.event_available_outlined,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'HSD ${formatDate(c.voucherExpireAt)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              SectionCard(
                title: 'Mô tả ưu đãi',
                icon: Icons.description_outlined,
                child: Text(c.description ?? 'Đang cập nhật.'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SectionCard(
                title: 'Điều kiện áp dụng',
                icon: Icons.rule_outlined,
                child: Text(c.terms ?? c.description ?? 'Đang cập nhật.'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SectionCard(
                title: 'Hạn sử dụng',
                icon: Icons.schedule_outlined,
                child: Text(formatDateTime(c.voucherExpireAt)),
              ),
              const SizedBox(height: AppSpacing.sm),
              SectionCard(
                title: 'Chính sách hoàn tiền',
                icon: Icons.currency_exchange,
                child: Text(
                  c.refundDescription ?? 'Chưa tải được chính sách hoàn tiền. Vui lòng thử lại sau.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SectionCard(
                title: 'Đánh giá (${c.reviewCount})',
                icon: Icons.star_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.reviewCount == 0
                          ? 'Chưa có đánh giá.'
                          : '${c.averageRating.toStringAsFixed(1)}/5 sao',
                    ),
                    for (final review in c.reviews)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${review['rating']}/5 · ${review['comment'] ?? ''}',
                        ),
                        subtitle: review['brandReply'] == null
                            ? null
                            : Text('Phản hồi: ${review['brandReply']}'),
                      ),
                  ],
                ),
              ),
              if (c.stores.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreMapScreen(stores: c.stores),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Xem bản đồ và chỉ đường'),
                ),
                const SizedBox(height: AppSpacing.sm),
                SectionCard(
                  title: 'Cửa hàng áp dụng',
                  icon: Icons.storefront_outlined,
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
                          trailing: s.distanceKm == null
                              ? null
                              : Text(formatDistance(s.distanceKm!)),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              CampaignReviewsSection(campaignId: c.id, campaignTitle: c.title),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Thanh hanh dong co dinh: gia + nut mua
        StickyActionBar(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Giá bán',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      formatVnd(c.salePrice),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: canBuy ? 'Mua ngay' : 'Hết hàng / ngừng bán',
                  onPressed: canBuy
                      ? () => AppRoutes.push(
                          context,
                          AppRoutes.checkout,
                          arguments: c,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
