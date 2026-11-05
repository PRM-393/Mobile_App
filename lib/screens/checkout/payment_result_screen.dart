import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/main_tab_controller.dart';
import '../../providers/wallet_provider.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/payment_link.dart';
import '../../widgets/common.dart';
import '../../widgets/payment_qr_card.dart';

// Tham so mo man ket qua: don vua tao / thanh toan lai, kem link payOS neu co
class PaymentResultArgs {
  const PaymentResultArgs({required this.order, this.paymentUrl, this.groupOrders = const []});

  final Order order;
  final String? paymentUrl;
  // Cac don cung thanh toan tu gio hang (gom ca order); rong voi don mua rieng
  final List<Order> groupOrders;
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
  late List<Order> _group = widget.args.groupOrders;
  late String? _paymentUrl = widget.args.paymentUrl ?? widget.args.order.paymentUrl;
  Timer? _timer;
  bool _busy = false;
  bool _saving = false;
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
        await _refreshGroup();
        if (!mounted) return;
        // Voucher moi ve vi: tai lai vi (kem thong bao cuc bo "voucher da ve vi")
        if (latest.status == 'FULFILLED') unawaited(context.read<WalletProvider>().load());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  // Don dai dien da co ket qua: lay ket qua tung don con lai trong nhom de hien dung tung voucher
  Future<void> _refreshGroup() async {
    if (_group.isEmpty) return;
    final service = context.read<OrderService>();
    try {
      final latest = await Future.wait(_group.map((o) => service.getOrder(o.id)));
      if (mounted) setState(() => _group = latest);
    } catch (_) {
      // van giu ket qua don dai dien; khach xem lai trong tab Don hang
    }
  }

  Future<void> _openPayment() async {
    final opened = await openPaymentLink(_paymentUrl);
    if (!opened && mounted) {
      setState(() => _error = 'Không mở được trang thanh toán. Vui lòng kiểm tra trình duyệt trên máy rồi thử lại.');
    }
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
      if (_paymentUrl != null && result.order.paymentQr == null) await _openPayment();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveQr(String qr) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await savePaymentQr(qr, 'thanh-toan-${_order.id.substring(0, 8)}');
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu ảnh QR. Mở ứng dụng ngân hàng và chọn ảnh này để thanh toán.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Không lưu được ảnh QR. Hãy kiểm tra quyền truy cập ảnh của ứng dụng.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Voucher moi nam o muc "Dang hieu luc" cua vi, du lan truoc khach dang xem muc khac
  void _goToWallet() {
    context.read<WalletProvider>().selectTab('ACTIVE');
    context.read<MainTabController>().go(MainTabController.wallet);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _goToOrders() {
    context.read<MainTabController>().go(MainTabController.orders);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _buyAgain() => Navigator.pushReplacementNamed(context, AppRoutes.voucherDetail, arguments: _order.campaignId);

  @override
  Widget build(BuildContext context) {
    final pending = _order.status == 'PENDING';
    // Het thoi gian giu cho: lien ket thanh toan da het han, may chu se tu huy don
    final expired = pending && _order.reservedUntil != null && !_order.canRetry(DateTime.now());
    final (icon, color, title, message) = switch (_order.status) {
      'PENDING' when expired => (Icons.timer_off_outlined, AppColors.danger, 'Đã hết thời gian giữ chỗ', 'Đơn này không còn thanh toán được và sẽ tự hủy. Bạn có thể mua lại nếu voucher còn hàng.'),
      'FULFILLED' => (Icons.check_circle, AppColors.success, 'Thanh toán thành công', 'Voucher đã vào Ví voucher, mục Đang hiệu lực. Mở ví để lấy mã QR khi dùng tại cửa hàng.'),
      'PAID' => (Icons.hourglass_bottom, AppColors.secondary, 'Đã nhận thanh toán', 'Đang phát hành voucher...'),
      'CANCELLED' => (Icons.cancel, AppColors.danger, 'Đơn hàng đã hủy', 'Thanh toán không thành công hoặc đã quá 15 phút giữ chỗ.'),
      'PAYMENT_MISMATCH' => (Icons.report, AppColors.danger, 'Số tiền không khớp', 'Bộ phận hỗ trợ sẽ hoàn lại số tiền bạn đã thanh toán.'),
      'REFUNDED_OVERSOLD' => (Icons.currency_exchange, AppColors.danger, 'Voucher đã hết', 'Bạn sẽ được hoàn 100% số tiền đã thanh toán và nhận thông báo khi tiền được chuyển lại.'),
      _ => (Icons.schedule, AppColors.secondary, 'Đang chờ thanh toán', 'Hoàn tất thanh toán trên trang payOS rồi quay lại đây, kết quả sẽ tự cập nhật. Đơn được lưu ở tab Đơn hàng.'),
    };
    final canPay = pending && !expired;
    final qr = canPay ? _order.paymentQr : null;
    final total = canPay
        ? _order.paymentAmount ?? _order.totalAmount
        : _group.isEmpty
            ? _order.totalAmount
            : _group.fold<double>(0, (sum, o) => sum + o.totalAmount);
    return Scaffold(
      appBar: AppBar(title: Text(canPay ? 'Thanh toán' : 'Kết quả thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Dang co ma QR thi uu tien ma; cac truong hop khac hien vong tron trang thai theo ket qua don
          if (qr != null) ...[
            PaymentQrCard(
              data: qr,
              amount: _order.paymentAmount ?? _order.totalAmount,
              expiresAt: _order.reservedUntil,
              onExpire: _refresh,
            ),
          ] else
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
            qr != null
                ? 'Chuyển khoản xong, kết quả sẽ tự cập nhật. Dùng một điện thoại thì lưu ảnh QR rồi chọn ảnh đó trong ứng dụng ngân hàng.'
                : message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Thông tin đơn hàng',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                if (_group.isEmpty) ...[
                  DetailRow('Voucher', _order.campaignTitle ?? 'Đơn hàng'),
                  DetailRow('Mã đơn', '#${_order.id.length > 8 ? _order.id.substring(0, 8).toUpperCase() : _order.id.toUpperCase()}'),
                  DetailRow('Số lượng', 'x${_order.quantity}'),
                ] else
                  for (final o in _group)
                    DetailRow(
                      o.campaignTitle ?? 'Voucher',
                      'x${o.quantity}${o.isFinal && o.status != 'FULFILLED' ? ' (không thành công)' : ''}',
                    ),
                DetailRow('Thời gian', formatDateTime(_order.createdAt)),
                if (canPay && _order.reservedUntil != null)
                  DetailRow('Giữ chỗ đến', formatDateTime(_order.reservedUntil!)),
                const Divider(height: AppSpacing.lg),
                DetailRow(
                  'Tổng tiền',
                  formatVnd(total),
                  emphasize: true,
                ),
              ],
            ),
          ),
          if (canPay && _group.isEmpty && _order.paymentAmount != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const InfoBanner('Mã này thanh toán chung cho các voucher đã chọn cùng lúc trong giỏ hàng.', icon: Icons.info_outline),
          ],
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
            if (qr != null)
              PrimaryButton(key: const Key('save-qr'), label: 'Lưu ảnh QR', icon: Icons.download_outlined, loading: _saving, onPressed: () => _saveQr(qr)),
            if (canPay && qr == null && _paymentUrl != null)
              PrimaryButton(key: const Key('open-payos'), label: 'Mở trang thanh toán payOS', icon: Icons.open_in_new, onPressed: _openPayment),
            if (canPay && _paymentUrl == null)
              PrimaryButton(key: const Key('retry-payos'), label: 'Tạo lại liên kết payOS', loading: _busy, onPressed: _createLink),
            if (canPay) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Kiểm tra lại')),
              if (qr != null && _paymentUrl != null)
                TextButton(key: const Key('open-payos'), onPressed: _openPayment, child: const Text('Không quét được? Mở trang payOS')),
              TextButton(key: const Key('go-orders'), onPressed: _goToOrders, child: const Text('Xem trong tab Đơn hàng')),
            ],
            if (expired || _order.status == 'CANCELLED')
              PrimaryButton(key: const Key('buy-again'), label: 'Mua lại', onPressed: _buyAgain),
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
