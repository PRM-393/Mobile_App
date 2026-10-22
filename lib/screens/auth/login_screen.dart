import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// Kiem tra email (dung lai trong widget test)
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Vui lòng nhập email';
  if (!_emailPattern.hasMatch(v)) return 'Email không hợp lệ';
  return null;
}

// FR-AUTH-01/02: khach hang dang nhap bang email + OTP (khong dung mat khau).
// Form + TextFormField + validator (Module 7).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().requestOtp(email);
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.otp, arguments: email);
      }
    } catch (e) {
      setState(() => _error = 'Không thể gửi mã OTP lúc này. $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Khoi nhan dien thuong hieu: logo bo goc mau teal + ten app
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: appHeaderGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: appCardShadow,
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Voucher Platform',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Mua và dùng voucher đa thương hiệu',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                key: const Key('emailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'ban@vidu.com',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
                validator: validateEmail,
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                InfoBanner(_error!, icon: Icons.error_outline, tone: StatusTone.danger),
              ],
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Gửi mã OTP',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Đăng nhập bằng email + OTP, không cần mật khẩu',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Mã OTP 6 số có hiệu lực 5 phút.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),
              // Khach xem duoc Kham pha / Tim kiem ma khong can dang nhap (FR-AUTH-11)
              TextButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Tiếp tục với tư cách khách'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
