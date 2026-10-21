import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final service = context.read<SearchService>();
    _categories = service.categories();
    _featured = service.search(sort: 'newest', categoryId: _categoryId, pageSize: 10);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _featured;
  }

  void _selectCategory(String? id) {
    setState(() {
      _categoryId = id;
      _featured = context.read<SearchService>().search(sort: 'newest', categoryId: id, pageSize: 10);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Khám phá ưu đãi', style: TextStyle(fontWeight: FontWeight.w800)),
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
              const Text('Danh mục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<List<Category>>(
                future: _categories,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
                  final cats = snap.data ?? const [];
                  if (cats.isEmpty) return const Text('Chưa có danh mục', style: TextStyle(color: AppColors.textSecondary));
                  return SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _chip('Tất cả', _categoryId == null, () => _selectCategory(null)),
                        for (final c in cats) _chip(c.name, _categoryId == c.id, () => _selectCategory(c.id)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Voucher mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<SearchResult>(
                future: _featured,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) return const LoadingState();
                  if (snap.hasError) return ErrorState(snap.error.toString(), onRetry: () => setState(_load));
                  final items = snap.data?.items ?? const [];
                  if (items.isEmpty) return const EmptyState('Chưa có voucher nào');
                  return SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, i) => VoucherCard(
                        width: 180,
                        campaign: items[i],
                        onTap: () => AppRoutes.push(context, AppRoutes.voucherDetail, arguments: items[i].id),
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
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}
