import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/main_tab_controller.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'orders/order_history_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';
import 'wallet/wallet_screen.dart';

// Tab chinh: Kham pha, Tim kiem, Vi voucher, Don hang, Ca nhan.
// Guest xem duoc Kham pha / Tim kiem; cac tab con lai yeu cau dang nhap (FR-AUTH-11).
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = context.watch<MainTabController>();
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    Widget guard(Widget child, String title) => loggedIn ? child : _LoginRequired(title: title);

    return Scaffold(
      body: IndexedStack(
        index: tabs.index,
        children: [
          const HomeScreen(),
          const SearchScreen(),
          guard(const WalletScreen(), 'Ví voucher'),
          guard(const OrderHistoryScreen(), 'Đơn hàng'),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.index,
        onDestinationSelected: tabs.go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Khám phá'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Tìm kiếm'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Ví voucher'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Đơn hàng'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.md),
                const Text('Vui lòng đăng nhập để sử dụng chức năng này.', textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                FilledButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.login), child: const Text('Đăng nhập')),
              ],
            ),
          ),
        ),
      );
}
