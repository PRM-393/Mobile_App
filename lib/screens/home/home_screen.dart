import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../providers/auth_provider.dart';
import '../../providers/main_tab_controller.dart';
import '../../providers/notification_provider.dart';
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
      titleSpacing: AppSpacing.md,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào, ${_greetingName(context)}',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Ưu đãi đa thương hiệu quanh bạn',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        // F16: so thong bao chua doc (Selector: chi rebuild chuong khi so thay doi)
        Selector<NotificationProvider, int>(
          selector: (_, n) => n.unread,
          builder: (context, unread, _) => IconButton(
            tooltip: 'Thông báo',
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => AppRoutes.push(context, AppRoutes.notifications),
          ),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // O tim kiem gia: cham de nhay sang tab Tim kiem
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.control),
            onTap: () => context.read<MainTabController>().go(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tìm voucher, thương hiệu...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Banner khuyen mai
          GradientHeaderCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giảm đến 50% cuối tuần',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Hàng trăm ưu đãi đang chờ bạn khám phá hôm nay.',
                        style: TextStyle(
                          color: Color(0xFFD9FFF3),
                          fontSize: 13,
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
          const SectionHeader('Khám phá theo danh mục'),
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
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            'Ưu đãi nổi bật',
            subtitle: 'Chọn cách sắp xếp bên dưới',
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            children: [
              _chip('Voucher mới', _sort == 'newest', () {
                _sort = 'newest';
                setState(_load);
              }),
              _chip('Bán chạy', _sort == 'best_seller', () {
                _sort = 'best_seller';
                setState(_load);
              }),
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
              if (items.isEmpty) {
                return const EmptyState(
                  'Chưa có voucher nào trong danh mục này',
                  icon: Icons.local_offer_outlined,
                );
              }
              // Hang the ngang cho nhom dau, phan con lai xem dang danh sach doc
              final highlight = items.take(5).toList();
              final rest = items.skip(5).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 290,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: highlight.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, i) => VoucherCard(
                        width: 190,
                        campaign: highlight[i],
                        onTap: () => _openDetail(highlight[i].id),
                      ),
                    ),
                  ),
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const SectionHeader('Tất cả ưu đãi'),
                    const SizedBox(height: AppSpacing.sm),
                    for (final item in rest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                        child: VoucherCard(
                          campaign: item,
                          onTap: () => _openDetail(item.id),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

  void _openDetail(String id) =>
      AppRoutes.push(context, AppRoutes.voucherDetail, arguments: id);

  // Ten hien o loi chao: ho ten, phan truoc @ cua email, hoac "Khách" khi chua dang nhap
  String _greetingName(BuildContext context) {
    // Doc dang nullable: man nay cung chay trong test khong dang ky AuthProvider
    final user = context.watch<AuthProvider?>()?.user;
    if (user == null) return 'Khách';
    final name = user.fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user.email.split('@').first;
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: AppSpacing.sm),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    ),
  );
}
