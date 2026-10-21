import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/engage.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import 'review_screen.dart';

// F15 (FR-ENGAGE-02..04): danh gia cua chien dich trong man chi tiet voucher - diem trung binh, danh sach,
// phan hoi cua thuong hieu. Nut "Viết đánh giá" chi hien khi khach da dung voucher va chua danh gia (BR-10).
class CampaignReviewsSection extends StatefulWidget {
  const CampaignReviewsSection({super.key, required this.campaignId, required this.campaignTitle});

  final String campaignId;
  final String campaignTitle;

  @override
  State<CampaignReviewsSection> createState() => _CampaignReviewsSectionState();
}

class _CampaignReviewsSectionState extends State<CampaignReviewsSection> {
  final List<ReviewItem> _items = [];
  ReviewPage? _last;
  ReviewEligibility? _eligibility;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final engage = context.read<EngageService>();
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    try {
      final page = await engage.campaignReviews(widget.campaignId);
      ReviewEligibility? eligibility;
      if (loggedIn) {
        try {
          eligibility = await engage.reviewEligibility(widget.campaignId);
        } catch (_) {
          // khong lay duoc dieu kien thi an nut danh gia
        }
      }
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _last = page;
        _eligibility = eligibility;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final last = _last;
    if (last == null || _loading) return;
    setState(() => _loading = true);
    try {
      final page = await context.read<EngageService>().campaignReviews(widget.campaignId, page: last.page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _last = page;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _write() async {
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.review,
      arguments: ReviewArgs(campaignId: widget.campaignId, campaignTitle: widget.campaignTitle),
    );
    if (created == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final last = _last;
    return Card(
      key: const Key('campaign-reviews'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                if (last?.avgRating != null) ...[
                  const Icon(Icons.star, color: AppColors.secondary, size: 18),
                  Text(
                    ' ${last!.avgRating!.toStringAsFixed(1)} (${last.reviewCount})',
                    key: const Key('review-average'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
            if (_eligibility?.canReview == true)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('write-review'),
                  onPressed: _write,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Viết đánh giá'),
                ),
              ),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.danger)),
            if (!_loading && _error == null && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text('Chưa có đánh giá nào.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            for (final r in _items) _ReviewTile(review: r),
            if (_loading) const Padding(padding: EdgeInsets.all(AppSpacing.sm), child: LinearProgressIndicator()),
            if (!_loading && last != null && last.hasMore)
              TextButton(onPressed: _loadMore, child: const Text('Xem thêm đánh giá')),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewItem review;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var s = 1; s <= 5; s++)
                  Icon(s <= review.rating ? Icons.star : Icons.star_border, color: AppColors.secondary, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(formatDateTime(review.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) Text(review.comment!),
            if (review.brandReply != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Text('Phản hồi của thương hiệu: ${review.brandReply}'),
              ),
          ],
        ),
      );
}
