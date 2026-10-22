import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/engage.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

// FR-ENGAGE-01: danh sach thuong hieu / voucher da danh dau yeu thich
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
            final isCampaign = f.targetType == 'CAMPAIGN';
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                leading: BrandAvatar(
                  size: 48,
                  icon: isCampaign
                      ? Icons.local_offer_outlined
                      : Icons.storefront_outlined,
                ),
                title: Text(
                  isCampaign ? 'Voucher' : 'Thương hiệu',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  f.targetId,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.favorite,
                  color: AppColors.danger,
                  size: 20,
                ),
                // TODO(F06): hien ten va anh thay vi ma; mo trang thuong hieu khi la BRAND
                onTap: isCampaign
                    ? () => Navigator.pushNamed(
                        context,
                        AppRoutes.voucherDetail,
                        arguments: f.targetId,
                      )
                    : null,
              ),
            );
          },
        );
      },
    ),
  );
}
