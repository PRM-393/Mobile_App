import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
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
          // Tu khoa gan day doc tu SharedPreferences (Module 9)
          if (search.recentKeywords.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                key: const Key('recent-keywords'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  for (final k in search.recentKeywords)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ActionChip(
                        avatar: const Icon(Icons.history, size: 16),
                        label: Text(k),
                        onPressed: () {
                          _controller.text = k;
                          search.setKeyword(k);
                        },
                      ),
                    ),
                  TextButton(onPressed: search.clearRecentKeywords, child: const Text('Xóa lịch sử')),
                ],
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
          // Module 12: luoi ket qua chi rebuild khi ket qua / trang thai tai thay doi
          Expanded(
            child: Selector<SearchProvider, (bool, String?, List<VoucherCampaign>, int?, bool)>(
              selector: (_, s) => (s.loading, s.error, s.results, s.radiusKm, s.hasLocation),
              builder: (context, state, _) => _results(context.read<SearchProvider>(), state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radiusChip(SearchProvider search, int? km, String label) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: ChoiceChip(label: Text(label), selected: search.radiusKm == km, onSelected: (_) => search.setRadius(km)),
      );

  Widget _results(SearchProvider search, (bool, String?, List<VoucherCampaign>, int?, bool) state) {
    final (loading, error, results, radiusKm, hasLocation) = state;
    if (loading && results.isEmpty) return const LoadingState();
    if (error != null) return ErrorState(error, onRetry: search.search);
    if (results.isEmpty) return const EmptyState('Không tìm thấy voucher phù hợp');
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
          itemCount: results.length,
          itemBuilder: (context, i) {
            final c = results[i];
            return VoucherCard(
              key: ValueKey(c.id),
              campaign: c,
              distanceLabel: radiusKm != null && hasLocation ? 'Trong bán kính $radiusKm km' : null,
              onTap: () => AppRoutes.push(context, AppRoutes.voucherDetail, arguments: c.id),
            );
          },
        ),
      ),
    );
  }
}
