import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/campaign.dart';
import 'models/order.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verify_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/checkout/payment_result_screen.dart';
import 'screens/engage/favorites_screen.dart';
import 'screens/engage/notification_settings_screen.dart';
import 'screens/engage/notifications_screen.dart';
import 'screens/engage/review_screen.dart';
import 'screens/main_shell.dart';
import 'screens/redeem/redeem_qr_screen.dart';
import 'screens/refund/refund_list_screen.dart';
import 'screens/refund/refund_request_screen.dart';
import 'screens/voucher/voucher_detail_screen.dart';
import 'screens/wallet/wallet_voucher_screen.dart';

// Named routes (Navigator 1.0 - Module 5). Tham so truyen qua RouteSettings.arguments.
class AppRoutes {
  AppRoutes._();

  static const main = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const voucherDetail = '/voucher';
  static const checkout = '/checkout';
  static const paymentResult = '/payment-result';
  static const redeemQr = '/redeem';
  static const refundRequest = '/refund';
  static const refundList = '/refunds';
  static const review = '/review';
  static const notifications = '/notifications';
  static const notificationSettings = '/notification-settings';
  static const favorites = '/favorites';
  static const walletVoucher = '/wallet-voucher';

  // Cac man hinh can dang nhap (protected routes - Module 10, FR-AUTH-11)
  static const protected = {
    checkout,
    paymentResult,
    redeemQr,
    refundRequest,
    refundList,
    review,
    notifications,
    notificationSettings,
    favorites,
    walletVoucher,
  };

  // Mo man hinh; neu can dang nhap ma dang la Guest thi chuyen sang man dang nhap
  static Future<void> push(
    BuildContext context,
    String name, {
    Object? arguments,
  }) {
    if (protected.contains(name) && !context.read<AuthProvider>().isLoggedIn) {
      return Navigator.pushNamed(context, login);
    }
    return Navigator.pushNamed(context, name, arguments: arguments);
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget page = switch (settings.name) {
      main => const MainShell(),
      login => const LoginScreen(),
      otp => OtpVerifyScreen(email: args as String),
      voucherDetail => VoucherDetailScreen(campaignId: args as String),
      checkout => CheckoutScreen(campaign: args as VoucherCampaign),
      paymentResult => PaymentResultScreen(args: args as PaymentResultArgs),
      redeemQr => RedeemQrScreen(voucher: args as VoucherItem),
      refundRequest => RefundRequestScreen(voucher: args as VoucherItem),
      refundList => const RefundListScreen(),
      review => ReviewScreen(args: args as ReviewArgs),
      walletVoucher => WalletVoucherScreen(voucher: args as VoucherItem),
      notifications => const NotificationsScreen(),
      notificationSettings => const NotificationSettingsScreen(),
      favorites => const FavoritesScreen(),
      _ => const Scaffold(body: Center(child: Text('Không tìm thấy màn hình'))),
    };
    return MaterialPageRoute(
      settings: settings,
      builder: (context) =>
          protected.contains(settings.name) &&
              !context.watch<AuthProvider>().isLoggedIn
          ? const LoginScreen()
          : page,
    );
  }
}
