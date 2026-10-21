import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order.dart';
import '../../providers/main_tab_controller.dart';
import '../../providers/wallet_provider.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// Tham so mo man ket qua: don vua tao / thanh toan lai, kem link payOS neu co
class PaymentResultArgs {
  const PaymentResultArgs({required this.order, this.paymentUrl});

  final Order order;
  final String? paymentUrl;
}

// FR-ORDER-05: sau khi mo trang thanh toan, app hoi trang thai don tu may chu (khong tin ket qua tren app)
// moi [pollInterval] cho toi khi don co ket qua cuoi cung hoac het thoi gian giu cho.
class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({super.key, required this.args, this.pollInterval = const Duration(seconds: 3)});

  final PaymentResultArgs args;
  final Duration pollInterval;

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  late Order _order = widget.args.order;
  late final String? _paymentUrl = widget.args.paymentUrl ?? widget.args.order.paymentUrl;
  Timer? _timer;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!_order.isFinal) _timer = Timer.periodic(widget.pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final latest = await context.read<OrderService>().getOrder(_order.id);
      if (!mounted) return;
      setState(() {
        _order = latest;
        _error = null;
      });
      if (latest.isFinal) {
        _timer?.cancel();
        // Voucher moi ve vi: tai lai vi (kem thong bao cuc bo "voucher da ve vi")
        if (latest.status == 'FULFILLED') unawaited(context.read<WalletProvider>().load());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _openPayment() async {
    final uri = Uri.tryParse(_paymentUrl ?? '');
    if (uri != null && uri.hasScheme) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // Che do demo: may chu chua cau hinh payOS nen thanh toan thu tren may chu
  Future<void> _simulate() async {
    setState(() => _busy = true);
    try {
      final updated = await context.read<OrderService>().simulatePayment(_order.id);
      if (!mounted) return;
      setState(() => _order = updated);
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goToWallet() {
    context.read<MainTabController>().go(MainTabController.wallet);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, message) = switch (_order.status) {
      'FULFILLED' => (Icons.check_circle, AppColors.success, 'Thanh toán thành công', 'Voucher đã được phát hành vào ví của bạn.'),
      'PAID' => (Icons.hourglass_bottom, AppColors.secondary, 'Đã nhận thanh toán', 'Đang phát hành voucher...'),
      'CANCELLED' => (Icons.cancel, AppColors.danger, 'Đơn hàng đã hủy', 'Thanh toán không thành công hoặc đã quá 15 phút giữ chỗ.'),
      'PAYMENT_MISMATCH' => (Icons.report, AppColors.danger, 'Số tiền không khớp', 'Bộ phận hỗ trợ sẽ hoàn lại số tiền bạn đã thanh toán.'),
      'REFUNDED_OVERSOLD' => (Icons.currency_exchange, AppColors.danger, 'Voucher đã hết', 'Bạn được hoàn 100% số tiền đã thanh toán.'),
      _ => (Icons.schedule, AppColors.secondary, 'Đang chờ thanh toán', 'Hoàn tất thanh toán trên trang payOS, kết quả sẽ tự cập nhật.'),
    };
    final pending = _order.status == 'PENDING';
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Icon(icon, color: color, size: 88, key: ValueKey('status-${_order.status}')),
          const SizedBox(height: AppSpacing.md),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: _order.campaignTitle ?? 'Đơn hàng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Số lượng: ${_order.quantity} · Tổng tiền: ${formatVnd(_order.totalAmount)}'),
                if (pending && _order.reservedUntil != null)
                  Text('Giữ chỗ đến: ${formatDateTime(_order.reservedUntil!)}',
                      style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (pending && _paymentUrl != null)
            PrimaryButton(label: 'Mở trang thanh toán payOS', onPressed: _openPayment),
          if (pending && _paymentUrl == null)
            PrimaryButton(key: const Key('simulate-pay'), label: 'Thanh toán thử (demo)', loading: _busy, onPressed: _simulate),
          if (pending) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Kiểm tra lại')),
          ],
          if (_order.status == 'FULFILLED')
            PrimaryButton(key: const Key('go-wallet'), label: 'Xem voucher trong ví', onPressed: _goToWallet),
        ],
      ),
    );
  }
}
