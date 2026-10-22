import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

// Tham so mo man danh gia: danh gia theo chien dich (moi chien dich 1 lan - DC-09)
class ReviewArgs {
  const ReviewArgs({required this.campaignId, required this.campaignTitle});

  factory ReviewArgs.fromVoucher(VoucherItem v) =>
      ReviewArgs(campaignId: v.campaignId, campaignTitle: v.campaign?.title ?? 'Voucher');

  final String campaignId;
  final String campaignTitle;
}

// FR-ENGAGE-02/03: danh gia 1-5 sao + binh luan; may chu chi nhan khi khach da dung voucher cua chien dich (BR-10)
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.args});

  final ReviewArgs args;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comment = _commentController.text.trim();
      await context.read<EngageService>().createReview(widget.args.campaignId, _rating, comment: comment.isEmpty ? null : comment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Đánh giá')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(widget.args.campaignTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var n = 1; n <= 5; n++)
                  IconButton(
                    key: Key('star-$n'),
                    iconSize: 40,
                    onPressed: () => setState(() => _rating = n),
                    icon: Icon(n <= _rating ? Icons.star : Icons.star_border, color: AppColors.secondary),
                  ),
              ],
            ),
            Text('$_rating / 5 sao', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('review-comment'),
              controller: _commentController,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(hintText: 'Chia sẻ trải nghiệm của bạn...'),
            ),
            if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: 'Gửi đánh giá', loading: _loading, onPressed: _submit),
          ],
        ),
      );
}
