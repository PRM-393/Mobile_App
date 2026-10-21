import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/order.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_client.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/countdown_timer.dart';

// FR-REDEEM-02/03: hien QR dong (60 giay) + ma OTP tuong ung, tu lam moi khi het han, giu man hinh sang.
// Nhan vien quet QR hoac nhap OTP tren web cua hang. Voucher vua duoc dung / bi gioi han tao ma thi dung lam moi.
class RedeemQrScreen extends StatefulWidget {
  const RedeemQrScreen({super.key, required this.voucher});

  final VoucherItem voucher;

  @override
  State<RedeemQrScreen> createState() => _RedeemQrScreenState();
}

class _RedeemQrScreenState extends State<RedeemQrScreen> {
  RedeemToken? _token;
  bool _loading = false;
  ApiException? _error;
  // Loi khong tu het (voucher da dung / het han / cho hoan, gioi han 10 lan / 10 phut): khong tu lam moi nua
  bool _stopped = false;

  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _keepScreenOn(true);
    _fetchToken();
    // Nhan vien xac nhan xong thi bao ngay cho khach, khong doi ma het han moi biet
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkUsed());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _keepScreenOn(false);
    super.dispose();
  }

  Future<void> _checkUsed() async {
    if (_stopped || !mounted) return;
    try {
      final detail = await context.read<OrderService>().walletDetail(widget.voucher.id);
      if (!mounted || detail.voucher.status != 'USED') return;
      _statusTimer?.cancel();
      setState(() {
        _stopped = true;
        _token = null;
        _error = const ApiException('Voucher đã được sử dụng.', reason: 'VOUCHER_USED');
      });
      context.read<WalletProvider>().load();
    } catch (_) {
      // mat mang tam thoi: thu lai o lan sau
    }
  }

  // Giu man hinh sang de nhan vien kip quet (khong co plugin trong test thi bo qua)
  Future<void> _keepScreenOn(bool on) async {
    try {
      await (on ? WakelockPlus.enable() : WakelockPlus.disable());
    } catch (_) {}
  }

  Future<void> _fetchToken() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await context.read<RedeemService>().requestToken(widget.voucher.id);
      if (mounted) {
        setState(() {
          _token = token;
          _stopped = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final fatal = e.reason == 'TOKEN_RATE_LIMITED' || (e.reason?.startsWith('VOUCHER_') ?? false) || e.statusCode == 404;
      setState(() {
        _error = e;
        _stopped = fatal;
        if (fatal) _token = null;
      });
      // Voucher vua duoc nhan vien xac nhan: cap nhat vi
      if (e.reason == 'VOUCHER_USED') context.read<WalletProvider>().load();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onExpire() {
    if (!_stopped) _fetchToken();
  }

  @override
  Widget build(BuildContext context) {
    final token = _token;
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('Sử dụng voucher')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            widget.voucher.campaign?.title ?? 'Voucher',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          if (error?.reason == 'VOUCHER_USED')
            const _Outcome(
              key: Key('redeem-used'),
              icon: Icons.check_circle,
              color: AppColors.success,
              title: 'Voucher đã được sử dụng',
              message: 'Cảm ơn bạn! Voucher đã được cửa hàng xác nhận.',
            )
          else if (_stopped && error != null)
            _Outcome(
              key: const Key('redeem-blocked'),
              icon: Icons.block,
              color: AppColors.danger,
              title: error.reason == 'TOKEN_RATE_LIMITED' ? 'Tạm thời không tạo được mã' : 'Không thể sử dụng voucher',
              message: _blockedMessage(error),
            )
          else ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: token == null
                    ? const SizedBox(width: 240, height: 240, child: Center(child: CircularProgressIndicator()))
                    : QrImageView(key: const Key('redeem-qr'), data: token.qrPayload, size: 240),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (token != null) ...[
              CountdownTimer(expiresAt: token.expiresAt, onExpire: _onExpire),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Mã OTP thay thế (nếu nhân viên không quét được QR)',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                token.otpCode,
                key: const Key('redeem-otp'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 8),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Mã tự làm mới sau mỗi 60 giây. Đưa mã cho nhân viên tại quầy, không gửi ảnh chụp mã cho người khác.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(error.message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (error?.reason == 'VOUCHER_USED')
            PrimaryButton(label: 'Về ví voucher', onPressed: () => Navigator.pop(context))
          else
            PrimaryButton(label: 'Làm mới mã', loading: _loading, onPressed: _fetchToken),
        ],
      ),
    );
  }

  String _blockedMessage(ApiException e) {
    final retryAt = e.details?['retryAt'];
    if (e.reason == 'TOKEN_RATE_LIMITED' && retryAt is String && DateTime.tryParse(retryAt) != null) {
      return 'Bạn đã tạo mã quá nhiều lần. Vui lòng thử lại sau ${formatDateTime(DateTime.parse(retryAt))}.';
    }
    return e.message;
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({super.key, required this.icon, required this.color, required this.title, required this.message});

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 64),
            const SizedBox(height: AppSpacing.sm),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      );
}
