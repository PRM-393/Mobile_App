import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/wallet_provider.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// UC-03: gui yeu cau hoan tien, he thong tu xet theo BR-05 (khong can nguoi duyet).
// Hien han chot hoan; khong du dieu kien thi khoa nut va noi ro ly do (FR-REFUND-04/07).
class RefundRequestScreen extends StatefulWidget {
  const RefundRequestScreen({super.key, required this.voucher});

  final VoucherItem voucher;

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _loading = false;
  RefundRequest? _result;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reason = _reasonController.text.trim();
      final result = await context.read<RefundService>().request(widget.voucher.id, reason: reason.isEmpty ? null : reason);
      if (!mounted) return;
      setState(() => _result = result);
      context.read<WalletProvider>().load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _describe(RefundRequest r) => switch (r.status) {
        'COMPLETED' => 'Hoàn tiền thành công${r.amount == null ? '' : ' ${formatVnd(r.amount!)}'}. '
            'Tiền sẽ về tài khoản / phương thức bạn đã thanh toán.',
        'REJECTED' => 'Không đủ điều kiện hoàn tiền: ${r.rejectReason ?? ''}',
        'FAILED' => 'Hoàn tiền không thành công: ${r.rejectReason ?? ''}. Voucher đã được khôi phục trong ví.',
        'MANUAL_PENDING' => 'Yêu cầu đang chờ quản trị viên hoàn tiền thủ công. Voucher tạm khóa trong lúc chờ.',
        _ => 'Yêu cầu đang được xử lý.',
      };

  @override
  Widget build(BuildContext context) {
    final v = widget.voucher;
    final eligibility = v.refund;
    final deadline = eligibility?.refundableUntil ?? v.refundableUntil;
    final blocked = eligibility != null && !eligibility.canRefund;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu hoàn tiền')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(v.campaign?.title ?? 'Voucher', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text('Mã tra cứu: ${v.code}', style: const TextStyle(color: AppColors.textSecondary)),
            if (v.campaign != null)
              Text('Số tiền hoàn dự kiến: ${formatVnd(v.campaign!.salePrice)}',
                  style: const TextStyle(color: AppColors.textSecondary)),
            if (deadline != null)
              Text('Hạn chót yêu cầu hoàn: ${formatDateTime(deadline)}',
                  key: const Key('refund-deadline'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Chỉ áp dụng cho voucher chưa sử dụng, trong vòng 7 ngày kể từ ngày mua và còn ít nhất '
              '3 ngày trước hạn sử dụng.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            if (result != null) ...[
              SectionCard(
                title: result.statusLabel,
                child: Text(_describe(result), key: const Key('refund-result')),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.refundList),
                child: const Text('Theo dõi yêu cầu hoàn tiền'),
              ),
              OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
            ] else if (blocked) ...[
              Container(
                key: const Key('refund-blocked'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(eligibility.reason ?? 'Voucher không đủ điều kiện hoàn tiền.',
                    style: const TextStyle(color: AppColors.danger)),
              ),
              const SizedBox(height: AppSpacing.md),
              const PrimaryButton(label: 'Gửi yêu cầu', onPressed: null),
            ] else ...[
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Lý do hoàn tiền (không bắt buộc)'),
              ),
              if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(label: 'Gửi yêu cầu', loading: _loading, onPressed: _submit),
            ],
          ],
        ),
      ),
    );
  }
}
