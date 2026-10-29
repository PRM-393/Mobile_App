import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

// FR-AUTH-09: quen mat khau - gui ma 6 so qua email (hieu luc 15 phut), nhap ma + mat khau moi + xac nhan.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().requestResetCode(widget.email);
      if (!mounted) return;
      setState(() => _sent = true);
      _timer?.cancel();
      setState(() => _resendIn = 60);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_resendIn <= 1) t.cancel();
        if (mounted) setState(() => _resendIn--);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().resetPassword(
        widget.email,
        _codeController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã đổi mật khẩu. Vui lòng đăng nhập bằng mật khẩu mới.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quên mật khẩu')),
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
              Text(
                _sent ? 'Nhập mã xác thực' : 'Đặt lại mật khẩu',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _sent
                    ? 'Mã 6 số đã gửi tới ${widget.email}. Mã có hiệu lực 15 phút.'
                    : 'Chúng tôi sẽ gửi mã xác thực 6 số tới ${widget.email}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_sent) ...[
                TextFormField(
                  key: const Key('resetCodeField'),
                  controller: _codeController,
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
                  ),
                  validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '')
                      ? null
                      : 'Mã gồm 6 chữ số',
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('newPasswordField'),
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('confirmNewPasswordField'),
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
                  ),
                  validator: (v) => v != _passwordController.text
                      ? 'Mật khẩu xác nhận không khớp'
                      : null,
                  onFieldSubmitted: (_) => _reset(),
                ),
              ],
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
                label: _sent ? 'Đổi mật khẩu' : 'Gửi mã xác thực',
                loading: _loading,
                onPressed: _sent ? _reset : _sendCode,
              ),
              if (_sent)
                TextButton(
                  onPressed: _resendIn > 0 || _loading ? null : _sendCode,
                  child: Text(
                    _resendIn > 0
                        ? 'Gửi lại mã sau ${_resendIn}s'
                        : 'Gửi lại mã',
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
