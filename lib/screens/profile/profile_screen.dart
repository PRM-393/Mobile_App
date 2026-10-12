import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';

// FR-AUTH-05/08: ho so ca nhan, diem vao Yeu thich / Thong bao / Hoan tien, dang xuat
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(user?.fullName ?? (user == null ? 'Khách' : 'Khách hàng'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  if (user != null) Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (user == null)
            FilledButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.login), child: const Text('Đăng nhập'))
          else ...[
            Card(
              child: Column(
                children: [
                  _menu(context, Icons.favorite_border, 'Yêu thích', AppRoutes.favorites),
                  _menu(context, Icons.notifications_none, 'Thông báo', AppRoutes.notifications),
                  _menu(context, Icons.currency_exchange, 'Yêu cầu hoàn tiền', AppRoutes.refundList),
                  // TODO(F17): man chinh sua ho so (ho ten, so dien thoai, anh dai dien) - FR-AUTH-05
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, minimumSize: const Size.fromHeight(48)),
              onPressed: auth.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, IconData icon, String label, String route) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => AppRoutes.push(context, route),
      );
}
