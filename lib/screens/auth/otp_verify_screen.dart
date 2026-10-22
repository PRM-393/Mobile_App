import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

// FR-AUTH-02/03: xac thuc OTP 6 so, nhan access token (15 phut) + refresh token (60 ngay)
class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key, required this.email});

  final String email;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  int _resendIn = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 1) t.cancel();
      setState(() => _resendIn--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().verifyOtp(
        widget.email,
        _otpController.text.trim(),
      );
      // Quay ve man hinh chinh; cac tab can dang nhap se tu hien noi dung
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      setState(() => _error = 'Mã OTP không đúng hoặc đã hết hạn. $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await context.read<AuthProvider>().requestOtp(widget.email);
      _startResendCountdown();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Xác thực OTP')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 34,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Nhập mã xác thực',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Mã 6 số đã gửi tới ${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  letterSpacing: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '------',
                  counterText: '',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    letterSpacing: 14,
                    color: AppColors.border,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                ),
                validator: (v) =>
                    (v ?? '').length == 6 ? null : 'Mã OTP gồm 6 chữ số',
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                InfoBanner(
                  _error!,
                  icon: Icons.error_outline,
                  tone: StatusTone.danger,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Xác nhận',
                loading: _loading,
                onPressed: _verify,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: _resendIn > 0 ? null : _resend,
                icon: Icon(
                  _resendIn > 0
                      ? Icons.timer_outlined
                      : Icons.refresh_rounded,
                  size: 18,
                ),
                label: Text(
                  _resendIn > 0
                      ? 'Gửi lại mã sau 00:${_resendIn.toString().padLeft(2, '0')}'
                      : 'Gửi lại mã',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Đổi email khác'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
