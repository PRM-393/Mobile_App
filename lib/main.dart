import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/env.dart';
import 'providers/auth_provider.dart';
import 'providers/main_tab_controller.dart';
import 'providers/search_provider.dart';
import 'providers/wallet_provider.dart';
import 'routes.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/token_storage.dart';
import 'services/voucher_services.dart';
import 'theme/app_theme.dart';

// Diem vao app khach hang: khoi tao service, khoi phuc phien dang nhap, dang ky Provider (Module 5)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiClient(baseUrl: Env.apiBaseUrl);
  final auth = AuthProvider(api: api, authService: AuthService(api), storage: TokenStorage());
  final notifications = NotificationService();
  await Future.wait([auth.hydrate(), notifications.init()]);

  final searchService = SearchService(api);
  final orderService = OrderService(api);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider.value(value: notifications),
        Provider.value(value: searchService),
        Provider.value(value: orderService),
        Provider(create: (_) => RedeemService(api)),
        Provider(create: (_) => RefundService(api)),
        Provider(create: (_) => EngageService(api)),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => MainTabController()),
        ChangeNotifierProvider(create: (_) => SearchProvider(searchService)),
        ChangeNotifierProvider(create: (_) => WalletProvider(orderService)),
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
