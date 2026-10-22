import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand_page.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/voucher_card.dart';

// F06 / FR-BRAND-07, FR-ENGAGE-01: trang thuong hieu - thong tin, diem danh gia, chi nhanh, chien dich dang ban.
// Theo doi thuong hieu de nhan thong bao khi thuong hieu co chien dich moi.
class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key, required this.brandId});

  final String brandId;

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  late Future<BrandPage> _future;
  bool _following = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<SearchService>().brandPage(widget.brandId);
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    if (!context.read<AuthProvider>().isLoggedIn) return;
    try {
      final following = await context.read<EngageService>().isFavorite('BRAND', widget.brandId);
      if (mounted) setState(() => _following = following);
    } catch (_) {
      // khong lay duoc trang thai thi coi nhu chua theo doi
    }
  }

  Future<void> _reload() async {
    setState(() => _future = context.read<SearchService>().brandPage(widget.brandId));
    await _future;
  }

  Future<void> _toggleFollow(BrandPage brand) async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    setState(() => _busy = true);
    try {
      final following = await context.read<EngageService>().toggleFavorite('BRAND', brand.id);
      if (!mounted) return;
      setState(() {
        _following = following;
        _future = Future.value(brand.withFollowers((brand.followerCount + (following ? 1 : -1)).clamp(0, 1 << 30)));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(following
            ? 'Đã theo dõi ${brand.name}. Bạn sẽ nhận thông báo khi có chiến dịch mới.'
            : 'Đã bỏ theo dõi ${brand.name}.'),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thương hiệu')),
        body: FutureBuilder<BrandPage>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LoadingState();
            if (snap.hasError) return ErrorState(snap.error.toString(), onRetry: _reload);
            final b = snap.data!;
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                key: const Key('brand-logo'),
                                radius: 28,
                                backgroundColor: AppColors.primarySoft,
                                foregroundImage: b.logo == null || b.logo!.isEmpty ? null : NetworkImage(b.logo!),
                                child: Text(
                                  b.name.isEmpty ? '?' : b.name.characters.first.toUpperCase(),
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        b.averageRating == null ? 'Chưa có đánh giá' : '★ ${b.averageRating!.toStringAsFixed(1)} (${b.reviewCount} đánh giá)',
                                        '${b.followerCount} người theo dõi',
                                      ].join(' · '),
                                      style: const TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (b.description != null && b.description!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(b.description!),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: _following
                                ? OutlinedButton.icon(
                                    key: const Key('follow-button'),
                                    onPressed: _busy ? null : () => _toggleFollow(b),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Đang theo dõi'),
                                  )
                                : FilledButton.icon(
                                    key: const Key('follow-button'),
                                    onPressed: _busy ? null : () => _toggleFollow(b),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Theo dõi'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Chiến dịch đang bán (${b.campaigns.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  if (b.campaigns.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text('Thương hiệu chưa có chiến dịch nào đang bán.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    for (final c in b.campaigns)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: VoucherCard(
                          key: ValueKey(c.id),
                          campaign: c,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.voucherDetail, arguments: c.id),
                        ),
                      ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Chi nhánh (${b.stores.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Card(
                    child: Column(
                      children: [
                        for (final s in b.stores)
                          ListTile(
                            leading: const Icon(Icons.storefront_outlined),
                            title: Text(s.name),
                            subtitle: Text(s.address),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
