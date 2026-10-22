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
      final result = await context.read<OrderService>().create(
        widget.campaign.id,
        _quantity,
      );
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
          // The tom tat don: logo thuong hieu, ten voucher, bo chon so luong
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrandAvatar(imageUrl: c.image, size: 56),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Đơn giá ${formatVnd(c.salePrice)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Số lượng',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: _quantity < _maxQuantity
                            ? () => setState(() => _quantity++)
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                  Text(
                    'Tối đa $_maxQuantity voucher cho mỗi tài khoản trong chiến dịch này.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Chi tiết thanh toán',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                DetailRow('Đơn giá', formatVnd(c.salePrice)),
                DetailRow('Số lượng', 'x$_quantity'),
                const Divider(height: AppSpacing.lg),
                DetailRow(
                  'Tổng cộng',
                  formatVnd(c.salePrice * _quantity),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            'Đơn hàng được giữ chỗ trong 15 phút. Nếu không hoàn tất thanh toán, đơn sẽ tự hủy '
            'và trả lại tồn kho.',
            icon: Icons.timer_outlined,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(
              _error!,
              icon: Icons.error_outline,
              tone: StatusTone.danger,
            ),
          ],
        ],
      ),
      // Thanh hanh dong co dinh: tong tien + nut thanh toan
      bottomNavigationBar: StickyActionBar(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formatVnd(c.salePrice * _quantity),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: 'Xác nhận thanh toán',
                loading: _loading,
                onPressed: _maxQuantity > 0 ? _pay : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
