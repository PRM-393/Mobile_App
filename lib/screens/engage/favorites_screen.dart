import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/engage.dart';
import '../../providers/main_tab_controller.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// FR-ENGAGE-01: danh sach thuong hieu dang theo doi / voucher da danh dau yeu thich
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Favorite>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<EngageService>().myFavorites();
  }

  void _reload() {
    if (mounted) setState(() { _future = context.read<EngageService>().myFavorites(); });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yêu thích')),
    body: FutureBuilder<List<Favorite>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingState();
        }
        if (snap.hasError) return ErrorState(snap.error.toString(), onRetry: _reload);
        final items = snap.data!;
        if (items.isEmpty) {
          return EmptyState(
            'Chưa có voucher hoặc thương hiệu yêu thích nào',
            icon: Icons.favorite_border,
            actionLabel: 'Khám phá ưu đãi',
            onAction: () {
              context.read<MainTabController>().go(MainTabController.home);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          );
        }
        return ListView.separated(
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
                  child: Icon(f.isBrand ? Icons.storefront_outlined : Icons.local_offer_outlined, color: AppColors.primaryDark),
                ),
                title: Text(
                  f.title ?? (f.isBrand ? 'Thương hiệu' : 'Voucher'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(f.isBrand
                    ? 'Thương hiệu đang theo dõi'
                    : [if (f.brandName != null) f.brandName!, if (f.salePrice != null) formatVnd(f.salePrice!)].join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                // F06: thuong hieu -> trang thuong hieu; voucher -> chi tiet
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    f.isBrand ? AppRoutes.brand : AppRoutes.voucherDetail,
                    arguments: f.targetId,
                  );
                  _reload();
                },
              ),
            );
          },
        );
      },
    ),
  );
}
