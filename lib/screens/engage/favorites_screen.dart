import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/engage.dart';
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Voucher yêu thích')),
    body: FutureBuilder<List<Favorite>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingState();
        }
        if (snap.hasError) return ErrorState(snap.error.toString());
        final items = snap.data!;
        if (items.isEmpty) {
          return EmptyState(
            'Chưa có voucher yêu thích nào',
            icon: Icons.favorite_border,
            actionLabel: 'Khám phá ưu đãi',
            onAction: () => Navigator.maybePop(context),
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
                onTap: () => Navigator.pushNamed(
                  context,
                  f.isBrand ? AppRoutes.brand : AppRoutes.voucherDetail,
                  arguments: f.targetId,
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
