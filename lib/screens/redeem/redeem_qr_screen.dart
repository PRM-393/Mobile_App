import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/order.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/countdown_timer.dart';

// FR-REDEEM-02/03: hien QR dong (60 giay) + ma OTP tuong ung, tu lam moi khi het han.
// Nhan vien quet QR hoac nhap OTP tren web cua hang.
class RedeemQrScreen extends StatefulWidget {
  const RedeemQrScreen({super.key, required this.voucher});

  final VoucherItem voucher;

  @override
  State<RedeemQrScreen> createState() => _RedeemQrScreenState();
}

class _RedeemQrScreenState extends State<RedeemQrScreen> {
  RedeemToken? _token;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  Future<void> _fetchToken() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await context.read<RedeemService>().requestToken(
        widget.voucher.id,
      );
      if (mounted) setState(() => _token = token);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = _token;
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
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: token == null
                  ? const SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : QrImageView(data: token.qrPayload, size: 240),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (token != null) ...[
            CountdownTimer(expiresAt: token.expiresAt, onExpire: _fetchToken),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Mã OTP thay thế (nếu nhân viên không quét được QR)',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              token.otpCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
              ),
            ),
          ],
          if (_error != null)
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Làm mới mã',
            loading: _loading,
            onPressed: _fetchToken,
          ),
        ],
      ),
    );
  }
}
