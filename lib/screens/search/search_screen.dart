import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../providers/search_provider.dart';
import '../../services/voucher_services.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/voucher_card.dart';
import '../../utils/distance.dart';
import 'store_map_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _keyword = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SearchProvider>().search();
    });
  }

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _filters() async {
    final search = context.read<SearchProvider>();
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _FilterSheet(search: search, service: context.read<SearchService>()),
    );
    if (applied == true) await search.search();
  }

  Future<void> _map() async {
    final search = context.read<SearchProvider>();
    if (!search.hasLocation && !await search.ensureLocation()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa có quyền vị trí. Bạn vẫn có thể xem danh sách.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreMapScreen(
          campaigns: search.results,
          latitude: search.latitude,
          longitude: search.longitude,
          radiusKm: search.radiusKm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm'),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            onPressed: _filters,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Bản đồ',
            onPressed: _map,
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // O tim kiem + nut bo loc + nut ban do
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              key: const Key('search-keyword'),
              controller: _keyword,
              textInputAction: TextInputAction.search,
              onSubmitted: search.setKeyword,
              decoration: InputDecoration(
                hintText: 'Tìm voucher, thương hiệu...',
                prefixIcon: IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: () => search.setKeyword(_keyword.text),
                  icon: const Icon(Icons.search, color: AppColors.primary),
                ),
              ),
            ),
          ),
          // Tim kiem gan day (Module 9: luu bang shared_preferences)
          if (search.recentKeywords.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  for (final k in search.recentKeywords)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.history,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        label: Text(k),
                        onPressed: () {
                          _keyword.text = k;
                          search.setKeyword(k);
                        },
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: search.radiusKm == null,
                    showCheckmark: false,
                    onSelected: (_) => search.setRadius(null),
                  ),
                ),
                for (final km in radiusOptionsKm)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text('Gần tôi $km km'),
                      selected: search.radiusKm == km,
                      showCheckmark: false,
                      onSelected: (_) => search.setRadius(km),
                    ),
                  ),
              ],
            ),
          ),
          if (search.locationDenied)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: InfoBanner(
                'Chưa được cấp vị trí. Đang hiển thị danh sách mặc định.',
                icon: Icons.location_off_outlined,
                tone: StatusTone.warning,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${search.total} kết quả',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: search.loading
                ? const LoadingState()
                : search.results.isEmpty
                ? search.error != null
                      ? ErrorState(search.error!, onRetry: search.search)
                      : const EmptyState(
                          'Không tìm thấy voucher phù hợp',
                          icon: Icons.search_off_rounded,
                        )
                : RefreshIndicator(
                    onRefresh: search.search,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: search.results.length + 1,
                      itemBuilder: (context, i) {
                        if (i == search.results.length) {
                          return Column(
                            children: [
                              if (search.error != null) Text(search.error!),
                              if (search.hasMore)
                                TextButton(
                                  onPressed: search.loadingMore
                                      ? null
                                      : search.loadMore,
                                  child: Text(
                                    search.loadingMore
                                        ? 'Đang tải…'
                                        : 'Tải thêm',
                                  ),
                                ),
                            ],
                          );
                        }
                        final c = search.results[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                          child: VoucherCard(
                            campaign: c,
                            distanceLabel: c.distanceKm == null
                                ? null
                                : formatDistance(c.distanceKm!),
                            onTap: () => AppRoutes.push(
                              context,
                              AppRoutes.voucherDetail,
                              arguments: c.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}


class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.search, required this.service});
  final SearchProvider search;
  final SearchService service;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final _form = GlobalKey<FormState>();
  late final _categories = widget.service.categories();
  late String _sort = widget.search.sort;
  late String? _category = widget.search.categoryId;
  late final _min = TextEditingController(
    text: widget.search.minPrice?.toString() ?? '',
  );
  late final _max = TextEditingController(
    text: widget.search.maxPrice?.toString() ?? '',
  );
  late final _discount = TextEditingController(
    text: widget.search.minDiscount?.toString() ?? '',
  );
  late final _discountMax = TextEditingController(
    text: widget.search.maxDiscount?.toString() ?? '',
  );
  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _discount.dispose();
    _discountMax.dispose();
    super.dispose();
  }

  String? money(String? v) =>
      v == null || v.isEmpty || int.tryParse(v) != null && int.parse(v) >= 0
      ? null
      : 'Nhập số nguyên không âm';
  String? percent(String? v) =>
      v == null ||
          v.isEmpty ||
          double.tryParse(v) != null &&
              double.parse(v) >= 0 &&
              double.parse(v) <= 100
      ? null
      : 'Nhập từ 0 đến 100';
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lọc và sắp xếp',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Category>>(
              future: _categories,
              builder: (context, snap) => snap.hasError
                  ? const Text(
                      'Không tải được danh mục. Bạn vẫn có thể lọc giá.',
                    )
                  : DropdownButtonFormField<String>(
                      initialValue:
                          snap.data?.any((c) => c.id == _category) == true
                          ? _category
                          : '',
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Tất cả'),
                        ),
                        for (final c in snap.data ?? <Category>[])
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => _category = v,
                    ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Sắp xếp'),
              items: [
                for (final entry in {
                  'newest': 'Mới nhất',
                  'best_seller': 'Bán chạy',
                  'price_asc': 'Giá tăng dần',
                  'price_desc': 'Giá giảm dần',
                  'discount_desc': 'Giảm nhiều nhất',
                  if (widget.search.hasLocation) 'distance_asc': 'Gần nhất',
                }.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (v) => _sort = v!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _min,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá từ (VND)'),
              validator: money,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _max,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá đến (VND)'),
              validator: (v) =>
                  money(v) ??
                  (int.tryParse(v ?? '') != null &&
                          int.tryParse(_min.text) != null &&
                          int.parse(v!) < int.parse(_min.text)
                      ? 'Giá đến phải lớn hơn hoặc bằng giá từ'
                      : null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giảm tối thiểu (%)',
              ),
              validator: percent,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discountMax,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giảm tối đa (%)'),
              validator: (v) =>
                  percent(v) ??
                  (double.tryParse(v ?? '') != null &&
                          double.tryParse(_discount.text) != null &&
                          double.parse(v!) < double.parse(_discount.text)
                      ? 'Mức tối đa phải lớn hơn hoặc bằng tối thiểu'
                      : null),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                final s = widget.search;
                s.categoryId = _category;
                s.sort = _sort;
                s.minPrice = int.tryParse(_min.text);
                s.maxPrice = int.tryParse(_max.text);
                s.minDiscount = double.tryParse(_discount.text);
                s.maxDiscount = double.tryParse(_discountMax.text);
                Navigator.pop(context, true);
              },
              child: const Text('Áp dụng'),
            ),
            TextButton(
              onPressed: () {
                final s = widget.search;
                s.categoryId = null;
                s.sort = 'newest';
                s.minPrice = s.maxPrice = null;
                s.minDiscount = s.maxDiscount = null;
                Navigator.pop(context, true);
              },
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      ),
    ),
  );
}
