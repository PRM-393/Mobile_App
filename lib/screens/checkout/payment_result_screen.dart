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

// Quay lai app tu trang payOS (app resumed) thi hoi lai trang thai ngay, khong doi lan hoi ke tiep.
class _PaymentResultScreenState extends State<PaymentResultScreen> with WidgetsBindingObserver {
  late Order _order = widget.args.order;
  late String? _paymentUrl = widget.args.paymentUrl ?? widget.args.order.paymentUrl;
  Timer? _timer;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_order.isFinal) _timer = Timer.periodic(widget.pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_order.isFinal) _refresh();
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

  // Cong payOS loi luc tao don nen chua co link: xin may chu tao lai link (thanh toan lai) roi mo trang payOS
  Future<void> _createLink() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await context.read<OrderService>().retryPayment(_order.id);
      if (!mounted) return;
      setState(() {
        _order = result.order;
        _paymentUrl = result.paymentUrl;
        if (_paymentUrl == null) _error = 'Chưa tạo được liên kết thanh toán payOS. Vui lòng thử lại sau ít phút.';
      });
      if (_paymentUrl != null) await _openPayment();
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
          // Vong tron trang thai lon, mau theo ket qua don
          Center(
            key: ValueKey('status-${_order.status}'),
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Thông tin đơn hàng',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                DetailRow('Voucher', _order.campaignTitle ?? 'Đơn hàng'),
                DetailRow('Mã đơn', _order.id),
                DetailRow('Số lượng', 'x${_order.quantity}'),
                DetailRow('Thời gian', formatDateTime(_order.createdAt)),
                if (pending && _order.reservedUntil != null)
                  DetailRow('Giữ chỗ đến', formatDateTime(_order.reservedUntil!)),
                const Divider(height: AppSpacing.lg),
                DetailRow(
                  'Tổng tiền',
                  formatVnd(_order.totalAmount),
                  emphasize: true,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(_error!, icon: Icons.error_outline, tone: StatusTone.danger),
          ],
        ],
      ),
      // Nut hanh dong nam o thanh duoi co dinh, luon thay duoc du noi dung dai
      bottomNavigationBar: StickyActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pending && _paymentUrl != null)
              PrimaryButton(key: const Key('open-payos'), label: 'Mở trang thanh toán payOS', icon: Icons.open_in_new, onPressed: _openPayment),
            if (pending && _paymentUrl == null)
              PrimaryButton(key: const Key('retry-payos'), label: 'Tạo lại liên kết payOS', loading: _busy, onPressed: _createLink),
            if (pending) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Kiểm tra lại')),
            ],
            if (_order.status == 'FULFILLED') ...[
              PrimaryButton(
                key: const Key('go-wallet'),
                label: 'Xem voucher trong ví',
                icon: Icons.account_balance_wallet_outlined,
                onPressed: _goToWallet,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  context.read<MainTabController>().go(MainTabController.home);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Về trang chủ'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
