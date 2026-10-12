import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/search_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance.dart';
import '../../widgets/common.dart';
import '../../widgets/voucher_card.dart';

// FR-SEARCH-02/03/05/06: tim theo tu khoa, loc "gan toi" theo ban kinh, luoi responsive (Module 6)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SearchProvider>().search());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm voucher hoặc thương hiệu...',
              ),
              onSubmitted: search.setKeyword,
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              children: [
                _radiusChip(search, null, 'Tất cả'),
                for (final km in radiusOptionsKm) _radiusChip(search, km, 'Gần tôi $km km'),
              ],
            ),
          ),
          if (search.locationDenied)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Không truy cập được vị trí nên không thể lọc theo khoảng cách. Đang hiện danh sách mặc định.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          Expanded(child: _results(search)),
        ],
      ),
    );
  }

  Widget _radiusChip(SearchProvider search, int? km, String label) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(label: Text(label), selected: search.radiusKm == km, onSelected: (_) => search.setRadius(km)),
      );

  Widget _results(SearchProvider search) {
    if (search.loading && search.results.isEmpty) return const LoadingState();
    if (search.error != null) return ErrorState(search.error!, onRetry: search.search);
    if (search.results.isEmpty) return const EmptyState('Không tìm thấy voucher phù hợp');
    return RefreshIndicator(
      onRefresh: search.search,
      // LayoutBuilder: so cot thay doi theo be rong man hinh (dien thoai nho / lon / tablet)
      child: LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (constraints.maxWidth / 200).floor().clamp(2, 5),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.68,
          ),
          itemCount: search.results.length,
          itemBuilder: (context, i) {
            final c = search.results[i];
            return VoucherCard(
              campaign: c,
              distanceLabel: search.radiusKm != null && search.hasLocation ? 'Trong bán kính ${search.radiusKm} km' : null,
              onTap: () => AppRoutes.push(context, AppRoutes.voucherDetail, arguments: c.id),
            );
          },
        ),
      ),
    );
  }
}
