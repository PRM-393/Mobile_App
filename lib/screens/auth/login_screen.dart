import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/env.dart';
import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// Kiem tra email (dung lai trong widget test)
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Vui lòng nhập email';
  if (!Env.demoLogin && !_emailPattern.hasMatch(v)) return 'Email không hợp lệ';
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
  if (!Env.demoLogin && v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
  return null;
}

enum _Step { email, login, register }

// FR-AUTH-01/02: nhap email truoc. Email da dang ky -> nhap mat khau; chua dang ky -> tao mat khau moi + xac nhan
// la xong, khong can xac thuc email. Quen mat khau thi nhan ma qua email (ForgotPasswordScreen).
// Form + TextFormField + validator (Module 7).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _Step _step = _Step.email;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  Future<void> _run(Future<void> Function() action) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _submit() => switch (_step) {
    _Step.email => _run(() async {
      final registered = await context.read<AuthProvider>().isRegistered(
        _email,
      );
      setState(() => _step = registered ? _Step.login : _Step.register);
    }),
    _Step.login => _run(() async {
      await context.read<AuthProvider>().login(
        _email,
        _passwordController.text,
      );
      _done();
    }),
    _Step.register => _run(() async {
      await context.read<AuthProvider>().register(
        _email,
        _passwordController.text,
      );
      _done();
    }),
  };

  // Quay ve man hinh chinh; cac tab can dang nhap se tu hien noi dung
  void _done() {
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _changeEmail() => setState(() {
    _step = _Step.email;
    _error = null;
    _passwordController.clear();
    _confirmController.clear();
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _Step.email => 'Mua và dùng voucher đa thương hiệu',
      _Step.login => 'Chào mừng bạn quay lại! Nhập mật khẩu để đăng nhập.',
      _Step.register =>
        'Email chưa có tài khoản. Tạo mật khẩu để đăng ký ngay.',
    };
    return Scaffold(
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
                Text(
                  _step == _Step.register
                      ? 'Tạo tài khoản'
                      : 'Voucher Platform',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  key: const Key('loginStepTitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  key: const Key('emailField'),
                  controller: _emailController,
                  readOnly: _step != _Step.email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: _step == _Step.email
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'ban@vidu.com',
                    prefixIcon: const Icon(Icons.mail_outline, size: 20),
                    suffixIcon: _step == _Step.email
                        ? null
                        : TextButton(
                            key: const Key('changeEmail'),
                            onPressed: _changeEmail,
                            child: const Text('Đổi'),
                          ),
                  ),
                  validator: validateEmail,
                  onFieldSubmitted: (_) =>
                      _step == _Step.email ? _submit() : null,
                ),
                if (_step != _Step.email) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('passwordField'),
                    controller: _passwordController,
                    obscureText: _obscure,
                    autofocus: true,
                    autofillHints: [
                      _step == _Step.login
                          ? AutofillHints.password
                          : AutofillHints.newPassword,
                    ],
                    textInputAction: _step == _Step.login
                        ? TextInputAction.done
                        : TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: _step == _Step.login
                          ? 'Mật khẩu'
                          : 'Mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: validatePassword,
                    onFieldSubmitted: (_) =>
                        _step == _Step.login ? _submit() : null,
                  ),
                ],
                if (_step == _Step.register) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('confirmPasswordField'),
                    controller: _confirmController,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
                    ),
                    validator: (v) => v != _passwordController.text
                        ? 'Mật khẩu xác nhận không khớp'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
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
                  label: switch (_step) {
                    _Step.email => 'Tiếp tục',
                    _Step.login => 'Đăng nhập',
                    _Step.register => 'Đăng ký',
                  },
                  loading: _loading,
                  onPressed: _submit,
                ),
                if (_step == _Step.login)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('forgotPassword'),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.forgotPassword,
                        arguments: _email,
                      ),
                      child: const Text('Quên mật khẩu?'),
                    ),
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
}
