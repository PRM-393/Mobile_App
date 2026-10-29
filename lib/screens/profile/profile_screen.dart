import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'profile_edit_screen.dart';

// FR-AUTH-05/08: ho so ca nhan, diem vao Yeu thich / Thong bao / Hoan tien, dang xuat
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  // F17 / FR-AUTH-05: man nay truoc day chi doc ho so tu phien da luu tren may, nen sua ho so o thiet bi
  // khac (hoac xoa anh dai dien) thi may nay van hien du lieu cu cho toi khi dang nhap lai.
  // Doc lai GET /users/me moi lan mo man; loi mang thi giu nguyen du lieu da luu, khong lam trong man hinh.
  Future<void> _refreshProfile() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    try {
      final fresh = await context.read<ProfileService>().me();
      if (mounted) await auth.updateUser(fresh);
    } catch (_) {
      // dang hien ho so cu, khong co gi de bao them
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // The header gradient: avatar + ten + email
          GradientHeaderCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  // F17: anh dai dien da luu (data URL), chua co thi hien bieu tuong
                  child: avatarImage(user?.avatar) == null
                      ? const Icon(Icons.person, size: 34, color: Colors.white)
                      : Image(image: avatarImage(user!.avatar)!, fit: BoxFit.cover),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? (user == null ? 'Khách' : 'Khách hàng'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                        ),
                      ),
                      if (user != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: Color(0xFFD9FFF3),
                            fontSize: 13,
                          ),
                        ),
                        if (user.phone != null && user.phone!.isNotEmpty)
                          Text(user.phone!, style: const TextStyle(color: Color(0xFFD9FFF3), fontSize: 13)),
                      ] else
                        const Text(
                          'Đăng nhập để mua và dùng voucher',
                          style: TextStyle(
                            color: Color(0xFFD9FFF3),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (user != null)
                  IconButton(
                    key: const Key('edit-profile'),
                    tooltip: 'Sửa hồ sơ',
                    onPressed: () => AppRoutes.push(context, AppRoutes.profileEdit),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (user == null)
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              child: const Text('Đăng nhập'),
            )
          else ...[
            Card(
              child: Column(
                children: [
                  _menu(
                    context,
                    Icons.favorite_border,
                    'Yêu thích',
                    AppRoutes.favorites,
                  ),
                  const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                  _menu(
                    context,
                    Icons.notifications_none,
                    'Thông báo',
                    AppRoutes.notifications,
                  ),
                  const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                  _menu(
                    context,
                    Icons.tune_rounded,
                    'Cài đặt thông báo',
                    AppRoutes.notificationSettings,
                  ),
                  const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                  _menu(
                    context,
                    Icons.currency_exchange,
                    'Yêu cầu hoàn tiền',
                    AppRoutes.refundList,
                  ),
                  const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                  _menu(context, Icons.manage_accounts_outlined, 'Sửa hồ sơ', AppRoutes.profileEdit),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Về ứng dụng'),
                subtitle: Text('Voucher Platform · phiên bản 1.0.0'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              onPressed: auth.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => AppRoutes.push(context, route),
  );
}
