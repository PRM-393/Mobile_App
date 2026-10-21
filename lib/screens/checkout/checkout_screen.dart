import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/campaign.dart';
import '../../routes.dart';
import 'payment_result_screen.dart';
import '../../services/notification_service.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// UC-01: chon so luong, tao don (giu ton kho 15 phut), chuyen sang cong thanh toan sandbox - FR-ORDER-01..05.
// Ket qua thanh toan chi duoc cong nhan qua webhook phia may chu, app khong tu ket luan (FR-ORDER-05).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.campaign});

  final VoucherCampaign campaign;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _quantity = 1;
  bool _loading = false;
  String? _error;

  int get _maxQuantity {
    final limit = widget.campaign.limitPerUser ?? 5; // BR-01: mac dinh 5
    final available = widget.campaign.availableQuantity;
    return available < limit ? available : limit;
  }

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = context.read<NotificationService>();
      final result = await context.read<OrderService>().create(widget.campaign.id, _quantity);
      // LO7: thong bao cuc bo sau thao tac quan trong (tao don, nhac thanh toan trong 15 phut)
      await notifications.orderCreated();
      final uri = Uri.tryParse(result.paymentUrl ?? '');
      if (uri != null && uri.hasScheme) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      // Man ket qua tu hoi trang thai don tu may chu (FR-ORDER-05)
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.paymentResult,
        arguments: PaymentResultArgs(order: result.order, paymentUrl: result.paymentUrl),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SectionCard(
            title: c.title,
            child: Text('Đơn giá: ${formatVnd(c.salePrice)}', style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Số lượng', style: TextStyle(color: AppColors.textSecondary)),
          Row(
            children: [
              IconButton.outlined(
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text('$_quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              IconButton.outlined(
                onPressed: _quantity < _maxQuantity ? () => setState(() => _quantity++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Text('Tối đa $_maxQuantity voucher cho mỗi tài khoản trong chiến dịch này.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const Divider(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(formatVnd(c.salePrice * _quantity),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Đơn hàng được giữ chỗ trong 15 phút. Nếu không hoàn tất thanh toán, đơn sẽ tự hủy '
            'và trả lại tồn kho (FR-ORDER-03).',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Tiến hành thanh toán', loading: _loading, onPressed: _maxQuantity > 0 ? _pay : null),
        ],
      ),
    );
  }
}
