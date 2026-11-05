import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';

// Doi mat khau khi dang dang nhap: nhap mat khau hien tai, mat khau moi va xac nhan.
// Cac thiet bi khac se bi dang xuat, thiet bi nay giu nguyen phien.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().changePassword(_current.text, _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đổi mật khẩu. Các thiết bị khác đã được đăng xuất.')),
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
    appBar: AppBar(title: const Text('Đổi mật khẩu')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('currentPasswordField'),
                controller: _current,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', prefixIcon: Icon(Icons.lock_outline, size: 20)),
                validator: (v) => (v ?? '').isEmpty ? 'Vui lòng nhập mật khẩu hiện tại' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('nextPasswordField'),
                controller: _next,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(labelText: 'Mật khẩu mới', prefixIcon: Icon(Icons.lock_reset_outlined, size: 20)),
                validator: (v) => validatePassword(v) ?? (v == _current.text ? 'Mật khẩu mới phải khác mật khẩu hiện tại' : null),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('confirmPasswordField'),
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', prefixIcon: Icon(Icons.lock_reset_outlined, size: 20)),
                validator: (v) => v != _next.text ? 'Mật khẩu xác nhận không khớp' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                InfoBanner(_error!, icon: Icons.error_outline, tone: StatusTone.danger),
              ],
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(label: 'Đổi mật khẩu', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    ),
  );
}
