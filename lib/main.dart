import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/env.dart';
import 'providers/auth_provider.dart';
import 'providers/main_tab_controller.dart';
import 'providers/notification_provider.dart';
import 'providers/search_provider.dart';
import 'providers/wallet_provider.dart';
import 'routes.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'services/token_storage.dart';
import 'services/voucher_services.dart';
import 'services/wallet_cache.dart';
import 'theme/app_theme.dart';

// Diem vao app khach hang: khoi tao service, khoi phuc phien dang nhap, dang ky Provider (Module 5)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiClient(baseUrl: Env.apiBaseUrl);
  final auth = AuthProvider(api: api, authService: AuthService(api), storage: TokenStorage());
  final notifications = NotificationService();
  final preferences = await PreferencesService.create();
  await Future.wait([auth.hydrate(), notifications.init()]);

  final searchService = SearchService(api);
  final orderService = OrderService(api);
  final engageService = EngageService(api);
  // F16: thong bao may chu, hien thanh thong bao cuc bo khi app dang mo
  final notificationProvider = NotificationProvider(engageService, local: notifications, preferences: preferences);
  // F10: vi luu SQLite de xem khi mat mang (NFR-MOB-12)
  final walletProvider = WalletProvider(orderService, cache: SqliteWalletCache());

  // Dang nhap: bat dau kiem tra thong bao; dang xuat: dung va xoa du lieu cua tai khoan cu
  var wasLoggedIn = auth.isLoggedIn;
  if (wasLoggedIn) notificationProvider.startPolling();
  auth.addListener(() {
    if (!wasLoggedIn && auth.isLoggedIn) notificationProvider.startPolling();
    if (wasLoggedIn && !auth.isLoggedIn) {
      notificationProvider.stopPolling();
      preferences.clearUserData();
      walletProvider.clear();
    }
    wasLoggedIn = auth.isLoggedIn;
  });

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider.value(value: notifications),
        Provider.value(value: preferences),
        Provider.value(value: searchService),
        Provider.value(value: orderService),
        Provider(create: (_) => RedeemService(api)),
        Provider(create: (_) => RefundService(api)),
        Provider.value(value: engageService),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => MainTabController()),
        ChangeNotifierProvider(create: (_) => SearchProvider(searchService, preferences: preferences)),
        ChangeNotifierProvider.value(value: walletProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const VoucherApp(),
    ),
  );
}

class VoucherApp extends StatelessWidget {
  const VoucherApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Voucher Platform',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: AppRoutes.main,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      );
}
