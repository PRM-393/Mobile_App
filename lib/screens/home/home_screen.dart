import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../providers/main_tab_controller.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/voucher_card.dart';

// FR-SEARCH-01/04: man Kham pha - danh muc + voucher moi nhat (loc theo danh muc)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Category>> _categories;
  late Future<SearchResult> _featured;
  String? _categoryId;
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final service = context.read<SearchService>();
    _categories = service.categories();
    _featured = service.search(
      sort: _sort,
      categoryId: _categoryId,
      pageSize: 20,
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await _featured;
  }

  void _selectCategory(String? id) {
    setState(() {
      _categoryId = id;
      _featured = context.read<SearchService>().search(
        sort: 'newest',
        categoryId: id,
        pageSize: 10,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'vouch.',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Ưu đãi tốt. Kết nối bền.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => AppRoutes.push(context, AppRoutes.notifications),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33045D50),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chạm để săn deal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Hàng trăm ưu đãi đang chờ bạn khám phá hôm nay.',
                        style: TextStyle(
                          color: Color(0xFFD9FFF3),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.read<MainTabController>().go(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tìm voucher hoặc thương hiệu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Khám phá theo danh mục',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<List<Category>>(
            future: _categories,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              if (snap.hasError) {
                return ErrorState(
                  'Không tải được danh mục',
                  onRetry: () => setState(_load),
                );
              }
              final cats = snap.data ?? const [];
              if (cats.isEmpty) {
                return const Text(
                  'Chưa có danh mục',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip(
                      'Tất cả',
                      _categoryId == null,
                      () => _selectCategory(null),
                    ),
                    for (final c in cats)
                      _chip(
                        c.name,
                        _categoryId == c.id,
                        () => _selectCategory(c.id),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const FittedBox(child: Text('Voucher mới')),
                  selected: _sort == 'newest',
                  onSelected: (_) {
                    _sort = 'newest';
                    setState(_load);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const FittedBox(child: Text('Bán chạy')),
                  selected: _sort == 'best_seller',
                  onSelected: (_) {
                    _sort = 'best_seller';
                    setState(_load);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<SearchResult>(
            future: _featured,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const LoadingState();
              }
              if (snap.hasError) {
                return ErrorState(
                  snap.error.toString(),
                  onRetry: () => setState(_load),
                );
              }
              final items = snap.data?.items ?? const [];
              if (items.isEmpty) return const EmptyState('Chưa có voucher nào');
              return SizedBox(
                height: 310,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) => VoucherCard(
                    width: 180,
                    campaign: items[i],
                    onTap: () => AppRoutes.push(
                      context,
                      AppRoutes.voucherDetail,
                      arguments: items[i].id,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: AppSpacing.sm),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}
