import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/engage.dart';
import '../../providers/favorite_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// FR-ENGAGE-01 (F06): thuong hieu dang theo doi va voucher da danh dau yeu thich.
//
// Hai nhom tach lam hai tab: theo doi thuong hieu de nhan thong bao chien dich moi, con yeu thich
// voucher la de danh mua sau - hai viec khac nhau, gop mot danh sach thi khong loc duoc.
// Bo yeu thich ngay tai day (bam lai de bo - idempotent), kem hoan tac vi thao tac nay rat de bam nham.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Tai lai moi lan mo man: bat / tat o man chi tiet voucher hoac trang thuong hieu phai hien ra o day
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoriteProvider>().load();
    });
  }

  Future<void> _remove(Favorite f) async {
    final favorites = context.read<FavoriteProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ten = f.title ?? (f.isBrand ? 'thương hiệu' : 'voucher');
    try {
      await favorites.remove(f);
      messenger.showSnackBar(SnackBar(
        content: Text(f.isBrand ? 'Đã bỏ theo dõi $ten.' : 'Đã bỏ yêu thích $ten.'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => favorites.undoRemove(f),
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yêu thích'),
          bottom: TabBar(
            tabs: [
              Tab(key: const Key('tab-brands'), text: 'Thương hiệu (${favorites.brands.length})'),
              Tab(key: const Key('tab-campaigns'), text: 'Voucher (${favorites.campaigns.length})'),
            ],
          ),
        ),
        body: Builder(builder: (context) {
          if (favorites.loading && !favorites.loaded) return const LoadingState();
          if (favorites.error != null && !favorites.loaded) {
            return ErrorState(favorites.error!, onRetry: () => context.read<FavoriteProvider>().load());
          }
          return TabBarView(
            children: [
              _list(
                favorites.brands,
                emptyText: 'Chưa theo dõi thương hiệu nào',
                emptyHint: 'Theo dõi một thương hiệu để nhận thông báo khi có ưu đãi mới.',
              ),
              _list(
                favorites.campaigns,
                emptyText: 'Chưa có voucher yêu thích nào',
                emptyHint: 'Bấm hình trái tim ở trang voucher để lưu lại mua sau.',
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _list(List<Favorite> items, {required String emptyText, required String emptyHint}) => RefreshIndicator(
        onRefresh: () => context.read<FavoriteProvider>().load(silent: true),
        child: items.isEmpty
            // ListView bao ngoai de keo xuong lam moi duoc ca khi danh sach rong
            ? ListView(
                children: [
                  const SizedBox(height: 64),
                  EmptyState(
                    emptyText,
                    icon: Icons.favorite_border,
                    actionLabel: 'Khám phá ưu đãi',
                    onAction: () => Navigator.maybePop(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      emptyHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final f = items[i];
                  return Card(
                    key: ValueKey(f.id),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(
                          f.isBrand ? Icons.storefront_outlined : Icons.local_offer_outlined,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      title: Text(
                        f.title ?? (f.isBrand ? 'Thương hiệu' : 'Voucher'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(f.isBrand
                          ? 'Thương hiệu đang theo dõi'
                          : [if (f.brandName != null) f.brandName!, if (f.salePrice != null) formatVnd(f.salePrice!)]
                              .join(' · ')),
                      trailing: IconButton(
                        key: Key('remove-${f.id}'),
                        tooltip: f.isBrand ? 'Bỏ theo dõi' : 'Bỏ yêu thích',
                        onPressed: () => _remove(f),
                        icon: const Icon(Icons.favorite, color: AppColors.danger),
                      ),
                      // F06: thuong hieu -> trang thuong hieu; voucher -> chi tiet
                      onTap: () => Navigator.pushNamed(
                        context,
                        f.isBrand ? AppRoutes.brand : AppRoutes.voucherDetail,
                        arguments: f.targetId,
                      ),
                    ),
                  );
                },
              ),
      );
}
