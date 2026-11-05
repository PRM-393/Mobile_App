import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voucher_platform_mobile/models/auth_user.dart';
import 'package:voucher_platform_mobile/models/campaign.dart';
import 'package:voucher_platform_mobile/models/order.dart';
import 'package:voucher_platform_mobile/providers/auth_provider.dart';
import 'package:voucher_platform_mobile/providers/cart_provider.dart';
import 'package:voucher_platform_mobile/providers/main_tab_controller.dart';
import 'package:voucher_platform_mobile/providers/notification_provider.dart';
import 'package:voucher_platform_mobile/providers/search_provider.dart';
import 'package:voucher_platform_mobile/providers/wallet_provider.dart';
import 'package:voucher_platform_mobile/routes.dart';
import 'package:voucher_platform_mobile/screens/checkout/checkout_screen.dart';
import 'package:voucher_platform_mobile/screens/checkout/payment_result_screen.dart';
import 'package:voucher_platform_mobile/screens/home/home_screen.dart';
import 'package:voucher_platform_mobile/screens/orders/order_history_screen.dart';
import 'package:voucher_platform_mobile/services/auth_service.dart';
import 'package:voucher_platform_mobile/services/notification_service.dart';
import 'package:voucher_platform_mobile/services/preferences_service.dart';
import 'package:voucher_platform_mobile/services/token_storage.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';

import '../helpers/fake_api.dart';

// Hanh trinh mua voucher tren app: gio hang, khach vang lai dang nhap xong di tiep, gioi han mua, don het han

Map<String, dynamic> _campaign({int total = 100, int limit = 5, String status = 'PUBLISHED'}) => {
  'id': 'c1',
  'brandId': 'b1',
  'brand': {'name': 'Highlands'},
  'title': 'Voucher 100K',
  'voucherType': 'PREPAID',
  'salePrice': 80000,
  'faceValue': 100000,
  'totalQuantity': total,
  'soldQuantity': 0,
  'reservedQuantity': 0,
  'limitPerUser': limit,
  'status': status,
  'saleStartAt': '2026-01-01T00:00:00.000Z',
  'saleEndAt': '2099-01-01T00:00:00.000Z',
  'voucherExpireAt': '2099-02-01T00:00:00.000Z',
};

Map<String, dynamic> _order(String status, {DateTime? until, String id = 'o1'}) => {
  'id': id,
  'campaignId': 'c1',
  'quantity': 1,
  'totalAmount': '80000',
  'status': status,
  'createdAt': '2026-10-20T03:00:00.000Z',
  'reservedUntil': (until ?? DateTime.now().add(const Duration(minutes: 10))).toUtc().toIso8601String(),
  'campaign': {'id': 'c1', 'title': 'Voucher 100K'},
};

class _GuestStorage extends TokenStorage {
  @override
  Future<LoginResponse?> read() async => null;
  @override
  Future<void> save(LoginResponse session) async {}
  @override
  Future<void> clear() async {}
}

const _session = {
  'accessToken': 'a',
  'refreshToken': 'r',
  'user': {'id': 'u1', 'email': 'ban@vidu.com', 'role': 'CUSTOMER'},
};

void main() {
  group('CartProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    VoucherCampaign campaign({int total = 100, int limit = 5}) => VoucherCampaign.fromJson(_campaign(total: total, limit: limit));

    test('them trung voucher thi cong so luong, khong vuot gioi han mua', () {
      final cart = CartProvider();
      for (var i = 0; i < 2; i++) {
        expect(cart.add(campaign(limit: 2)), isTrue);
      }
      expect(cart.add(campaign(limit: 2)), isFalse);
      expect(cart.items.single.quantity, 2);
      expect(cart.totalQuantity, 2);
    });

    test('luu tren thiet bi, mo lai app van con; dang xuat xoa', () async {
      final prefs = await PreferencesService.create();
      CartProvider(prefs).add(campaign());
      final reopened = CartProvider(prefs);
      expect(reopened.items.single.title, 'Voucher 100K');
      expect(reopened.items.single.unitPrice, 80000);
      reopened.clear();
      expect(CartProvider(prefs).items, isEmpty);
    });

    test('dong bo may chu: gia moi va giam so luong khi ton kho con it', () {
      final cart = CartProvider()..add(campaign(), quantity: 4);
      cart.syncWith(VoucherCampaign.fromJson({..._campaign(total: 2), 'salePrice': 70000}));
      expect(cart.items.single.quantity, 2);
      expect(cart.items.single.unitPrice, 70000);
    });

    test('du lieu luu bi hong thi gio rong, khong lam sap app', () async {
      SharedPreferences.setMockInitialValues({'cart_items': 'khong-phai-json'});
      expect(CartProvider(await PreferencesService.create()).items, isEmpty);
    });
  });

  // App day du route, mo dung man hinh can test
  Future<(FakeApi, AuthProvider, CartProvider, MainTabController)> pumpApp(
    WidgetTester tester, {
    required Map<String, FakeResponse Function(dynamic)> routes,
    bool loggedIn = true,
    required void Function(BuildContext context) open,
  }) async {
    final api = FakeApi(routes.map((k, v) => MapEntry(k, (req) => v(req))));
    final client = api.client();
    final auth = AuthProvider(
      api: client,
      authService: AuthService(client),
      storage: loggedIn ? LoggedInTokenStorage() : _GuestStorage(),
    );
    await auth.hydrate();
    final cart = CartProvider();
    final tabs = MainTabController();
    final search = SearchService(client);
    final orders = OrderService(client);
    final engage = EngageService(client);
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider.value(value: NotificationService()),
        Provider.value(value: search),
        Provider.value(value: orders),
        Provider.value(value: engage),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: cart),
        ChangeNotifierProvider.value(value: tabs),
        ChangeNotifierProvider(create: (_) => SearchProvider(search)),
        ChangeNotifierProvider(create: (_) => WalletProvider(orders)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(engage)),
      ],
      child: MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(child: TextButton(onPressed: () => open(context), child: const Text('mo'))),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('mo'));
    await tester.pumpAndSettle();
    return (api, auth, cart, tabs);
  }

  final detailRoutes = <String, FakeResponse Function(dynamic)>{
    'GET /vouchers/c1': (_) => FakeResponse.ok(_campaign()),
    'GET /campaigns/c1/reviews': (_) => const FakeResponse.ok({'items': [], 'total': 0}),
    'GET /campaigns/c1/reviews/eligibility': (_) => const FakeResponse.ok({'canReview': false}),
    'GET /favorites/me': (_) => const FakeResponse.ok([]),
    'GET /orders/me': (_) => const FakeResponse.ok([]),
  };

  group('Gio hang tren man hinh', () {
    testWidgets('khach vang lai them vao gio, thay so luong, doi so luong va xoa', (tester) async {
      final (_, _, cart, _) = await pumpApp(
        tester,
        loggedIn: false,
        routes: detailRoutes,
        open: (c) => Navigator.pushNamed(c, AppRoutes.voucherDetail, arguments: 'c1'),
      );
      await tester.tap(find.byKey(const Key('add-to-cart')));
      await tester.pump();
      expect(find.text('Đã thêm vào giỏ hàng'), findsOneWidget);
      expect(cart.totalQuantity, 1);

      await tester.tap(find.byKey(const Key('cart-button')));
      await tester.pumpAndSettle();
      expect(find.text('Giỏ hàng (1)'), findsOneWidget);
      expect(find.text('Voucher 100K'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cart-plus-c1')));
      await tester.pump();
      expect(find.text('Giỏ hàng (2)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cart-remove-c1')));
      await tester.pump();
      expect(find.textContaining('Giỏ hàng đang trống'), findsOneWidget);
    });

    testWidgets('voucher trong gio da ngung ban thi khoa mua va bao ly do', (tester) async {
      final (_, _, _, _) = await pumpApp(
        tester,
        routes: {
          ...detailRoutes,
          'GET /vouchers/c1': (_) => FakeResponse.ok(_campaign(status: 'PAUSED')),
        },
        open: (c) {
          c.read<CartProvider>().add(VoucherCampaign.fromJson(_campaign()));
          Navigator.pushNamed(c, AppRoutes.cart);
        },
      );
      expect(find.textContaining('Ngừng bán'), findsOneWidget);
      expect(find.byKey(const Key('cart-buy-c1')), findsNothing);
    });

    testWidgets('mua tu gio: mang so luong sang man mua, tao don xong bo khoi gio', (tester) async {
      final (api, _, cart, _) = await pumpApp(
        tester,
        routes: {
          ...detailRoutes,
          'POST /orders': (_) => FakeResponse.ok({'order': _order('PENDING'), 'paymentUrl': null}),
          'GET /orders/o1': (_) => FakeResponse.ok(_order('PENDING')),
        },
        open: (c) {
          c.read<CartProvider>().add(VoucherCampaign.fromJson(_campaign()), quantity: 3);
          Navigator.pushNamed(c, AppRoutes.cart);
        },
      );
      await tester.tap(find.byKey(const Key('cart-buy-c1')));
      await tester.pumpAndSettle();
      expect(find.text('x3'), findsOneWidget);

      await tester.tap(find.text('Xác nhận thanh toán'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(api.calls('POST', '/orders').single.body, contains('"quantity":3'));
      expect(cart.items, isEmpty);
      expect(find.text('Đang chờ thanh toán'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('khach vang lai bam mua: dang nhap xong vao thang man mua, khong mat voucher dang chon', (tester) async {
    final (_, auth, _, _) = await pumpApp(
      tester,
      loggedIn: false,
      routes: {
        ...detailRoutes,
        'POST /auth/check-email': (_) => const FakeResponse.ok({'registered': true}),
        'POST /auth/login': (_) => const FakeResponse.ok(_session),
      },
      open: (c) => Navigator.pushNamed(c, AppRoutes.voucherDetail, arguments: 'c1'),
    );
    await tester.tap(find.text('Mua ngay'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('emailField')), 'ban@vidu.com');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('passwordField')), 'matkhau1');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(auth.isLoggedIn, isTrue);
    expect(find.text('Xác nhận thanh toán'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết voucher'), findsOneWidget);
  });

  group('Man mua hang', () {
    testWidgets('don cu con giu cho: nhac tiep tuc va tinh vao gioi han mua', (tester) async {
      final (api, _, _, _) = await pumpApp(
        tester,
        routes: {
          ...detailRoutes,
          'GET /orders/me': (_) => FakeResponse.ok([_order('PENDING')]),
          'POST /orders/o1/pay': (_) => FakeResponse.ok({'order': _order('PENDING'), 'paymentUrl': null}),
          'GET /orders/o1': (_) => FakeResponse.ok(_order('PENDING')),
        },
        open: (c) => Navigator.pushNamed(
          c,
          AppRoutes.checkout,
          arguments: CheckoutArgs(campaign: VoucherCampaign.fromJson(_campaign(limit: 2)), quantity: 2),
        ),
      );
      expect(find.byKey(const Key('pending-order')), findsOneWidget);
      expect(find.text('Mỗi tài khoản mua tối đa 2 voucher. Bạn còn được mua 1.'), findsOneWidget);
      expect(find.text('x1'), findsOneWidget); // so luong tu giam theo gioi han con lai

      await tester.ensureVisible(find.text('Tiếp tục thanh toán đơn này'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục thanh toán đơn này'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(api.calls('POST', '/orders/o1/pay'), hasLength(1));
      expect(api.calls('POST', '/orders'), isEmpty); // khong tao them don
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('da dat gioi han thi khoa nut va noi ro', (tester) async {
      await pumpApp(
        tester,
        routes: {
          ...detailRoutes,
          'GET /orders/me': (_) => FakeResponse.ok([_order('PENDING')]),
        },
        open: (c) => Navigator.pushNamed(c, AppRoutes.checkout, arguments: VoucherCampaign.fromJson(_campaign(limit: 1))),
      );
      expect(find.text('Bạn đã đạt giới hạn 1 voucher của chiến dịch này.'), findsOneWidget);
      final bar = tester.widget<FilledButton>(find.ancestor(of: find.text('Xác nhận thanh toán'), matching: find.byType(FilledButton)));
      expect(bar.onPressed, isNull);
    });
  });

  group('Sau khi mua', () {
    testWidgets('don het thoi gian giu cho: khong cho mo trang thanh toan, co nut mua lai', (tester) async {
      final expired = Order.fromJson(_order('PENDING', until: DateTime.now().subtract(const Duration(minutes: 1))));
      await pumpApp(
        tester,
        routes: {...detailRoutes, 'GET /orders/o1': (_) => FakeResponse.ok(_order('PENDING', until: DateTime.now().subtract(const Duration(minutes: 1))))},
        open: (c) => Navigator.pushNamed(c, AppRoutes.paymentResult, arguments: PaymentResultArgs(order: expired, paymentUrl: 'https://pay.payos.vn/x')),
      );
      expect(find.text('Đã hết thời gian giữ chỗ'), findsOneWidget);
      expect(find.byKey(const Key('open-payos')), findsNothing);
      expect(find.byKey(const Key('buy-again')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('thanh toan xong: nut xem voucher mo dung muc Dang hieu luc cua vi', (tester) async {
      late WalletProvider wallet;
      final (_, _, _, tabs) = await pumpApp(
        tester,
        routes: {...detailRoutes, 'GET /wallet': (_) => const FakeResponse.ok([])},
        open: (c) {
          wallet = c.read<WalletProvider>()..selectTab('USED');
          Navigator.pushNamed(c, AppRoutes.paymentResult, arguments: PaymentResultArgs(order: Order.fromJson(_order('FULFILLED'))));
        },
      );
      expect(find.textContaining('Ví voucher'), findsOneWidget);
      await tester.tap(find.byKey(const Key('go-wallet')));
      await tester.pumpAndSettle();
      expect(tabs.index, MainTabController.wallet);
      expect(wallet.tab, 'ACTIVE');
    });

    testWidgets('tab don hang: don da phat hanh co Xem voucher, don huy co Mua lai', (tester) async {
      final (_, _, _, tabs) = await pumpApp(
        tester,
        routes: {
          ...detailRoutes,
          'GET /orders/me': (_) => FakeResponse.ok([_order('FULFILLED'), _order('CANCELLED', id: 'o2')]),
        },
        open: (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
      );
      expect(find.byKey(const Key('order-again-o2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('order-wallet-o1')));
      await tester.pump();
      expect(tabs.index, MainTabController.wallet);
    });
  });

  testWidgets('trang chu: chon danh muc van giu cach sap xep Ban chay', (tester) async {
    final (api, _, _, _) = await pumpApp(
      tester,
      routes: {
        'GET /categories': (_) => const FakeResponse.ok([{'id': 'cat1', 'name': 'Cà phê'}]),
        'GET /vouchers': (_) => const FakeResponse.ok({'items': [], 'total': 0}),
      },
      open: (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const HomeScreen())),
    );
    await tester.tap(find.text('Bán chạy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cà phê'));
    await tester.pumpAndSettle();
    final last = api.calls('GET', '/vouchers').last.url.queryParameters;
    expect(last['sort'], 'best_seller');
    expect(last['categoryId'], 'cat1');
  });
}
