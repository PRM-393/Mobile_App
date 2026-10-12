import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/wallet_provider.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

// UC-03: gui yeu cau hoan tien, he thong tu dong xet theo BR-05 (khong can nguoi duyet)
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
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _describe(RefundRequest r) => switch (r.status) {
        'COMPLETED' => 'Hoàn tiền thành công.',
        'REJECTED' => 'Không đủ điều kiện hoàn tiền: ${r.rejectReason ?? ''}',
        'MANUAL_PENDING' => 'Yêu cầu đang chờ quản trị viên hoàn tiền thủ công.',
        _ => 'Yêu cầu đang được xử lý.',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Yêu cầu hoàn tiền')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(widget.voucher.campaign?.title ?? 'Voucher', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Chỉ áp dụng cho voucher chưa sử dụng, trong vòng 7 ngày kể từ ngày mua và còn ít nhất '
                '3 ngày trước hạn sử dụng (BR-05).',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Lý do hoàn tiền (không bắt buộc)'),
              ),
              if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: AppSpacing.md),
              if (_result != null) ...[
                SectionCard(title: 'Kết quả', child: Text(_describe(_result!))),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
              ] else
                PrimaryButton(label: 'Gửi yêu cầu', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      );
}
