import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voucher_platform_mobile/models/order.dart';
import 'package:voucher_platform_mobile/providers/auth_provider.dart';
import 'package:voucher_platform_mobile/providers/wallet_provider.dart';
import 'package:voucher_platform_mobile/routes.dart';
import 'package:voucher_platform_mobile/screens/engage/campaign_reviews_section.dart';
import 'package:voucher_platform_mobile/screens/redeem/redeem_qr_screen.dart';
import 'package:voucher_platform_mobile/screens/refund/refund_list_screen.dart';
import 'package:voucher_platform_mobile/screens/refund/refund_request_screen.dart';
import 'package:voucher_platform_mobile/screens/wallet/wallet_voucher_screen.dart';
import 'package:voucher_platform_mobile/services/auth_service.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';
import 'package:voucher_platform_mobile/services/token_storage.dart';

import '../helpers/fake_api.dart';

// Widget test F10 / F12 / F15 tren app: chi tiet voucher da mua, man QR, hoan tien, danh gia
void main() {
  Future<void> pumpScreen(WidgetTester tester, FakeApi api, Widget home, {bool loggedIn = true}) async {
    // Man hinh dien thoai (1080 x 2400, ti le 2) de cac nut cuoi danh sach nam trong khung
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final client = api.client();
    final auth = AuthProvider(api: client, authService: AuthService(client), storage: loggedIn ? LoggedInTokenStorage() : TokenStorage());
    if (loggedIn) await auth.hydrate();
    final orderService = OrderService(client);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        Provider.value(value: orderService),
        Provider(create: (_) => RedeemService(client)),
        Provider(create: (_) => RefundService(client)),
        Provider(create: (_) => EngageService(client)),
        ChangeNotifierProvider(create: (_) => WalletProvider(orderService)),
      ],
      child: MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
    ));
    await tester.pumpAndSettle();
  }

  group('chi tiet voucher da mua (task 9, 17)', () {
    testWidgets('hien han chot hoan, chi nhanh ap dung; du dieu kien thi nut hoan bat', (tester) async {
      final v = walletVoucher('v1');
      final api = FakeApi({
        'GET /wallet/v1': (_) => FakeResponse.ok({
              ...v,
              'stores': [
                {'id': 's1', 'name': 'Highlands Lê Lợi', 'address': '1 Lê Lợi, Q1'},
              ],
              'redemption': null,
              'refundRequests': [],
            }),
      });
      await pumpScreen(tester, api, WalletVoucherScreen(voucher: VoucherItem.fromJson(v)));

      expect(find.text('Highlands Lê Lợi'), findsOneWidget);
      expect(find.byKey(const Key('refund-deadline')), findsOneWidget);
      expect(find.text('Sử dụng ngay'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(find.byKey(const Key('refund-button')));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('khong du dieu kien hoan: khoa nut va noi ly do (FR-REFUND-04)', (tester) async {
      final v = walletVoucher('v1', canRefund: false, refundReason: 'Đã quá hạn hoàn tiền (hạn chót 08:00 19/10/2026).');
      final api = FakeApi({'GET /wallet/v1': (_) => FakeResponse.ok({...v, 'stores': [], 'refundRequests': []})});
      await pumpScreen(tester, api, WalletVoucherScreen(voucher: VoucherItem.fromJson(v)));

      final button = tester.widget<OutlinedButton>(find.byKey(const Key('refund-button')));
      expect(button.onPressed, isNull);
      expect(find.textContaining('Đã quá hạn hoàn tiền'), findsOneWidget);
    });

    testWidgets('voucher dang cho hoan: khong co nut tao ma, noi ro ly do', (tester) async {
      final v = walletVoucher('v1', status: 'REFUND_PENDING', canRefund: false, refundReason: 'Voucher đang có yêu cầu hoàn tiền được xử lý.');
      final api = FakeApi({'GET /wallet/v1': (_) => FakeResponse.ok({...v, 'stores': [], 'refundRequests': []})});
      await pumpScreen(tester, api, WalletVoucherScreen(voucher: VoucherItem.fromJson(v)));

      expect(find.text('Sử dụng ngay'), findsNothing);
      expect(find.byKey(const Key('use-disabled-reason')), findsOneWidget);
    });

    testWidgets('mat mang: van hien thong tin trong vi, an nut tao ma', (tester) async {
      final v = walletVoucher('v1');
      final api = FakeApi({})..offline = true;
      await pumpScreen(tester, api, WalletVoucherScreen(voucher: VoucherItem.fromJson(v)));

      expect(find.text('Voucher 100K'), findsOneWidget);
      expect(find.text('Sử dụng ngay'), findsNothing);
      expect(find.byKey(const Key('use-offline-reason')), findsOneWidget);
    });
  });

  group('man QR (task 9)', () {
    testWidgets('hien QR + OTP + dong ho 60 giay; lam moi goi lai API', (tester) async {
      final expires = DateTime.now().add(const Duration(seconds: 60)).toUtc().toIso8601String();
      final api = FakeApi({
        'POST /redeem/token': (_) => FakeResponse.ok({'qrPayload': 'v1.abc.1.sig', 'otpCode': '123456', 'expiresAt': expires, 'ttlSeconds': 60}),
        'GET /wallet/v1': (_) => FakeResponse.ok({...walletVoucher('v1'), 'stores': [], 'refundRequests': []}),
      });
      await pumpScreen(tester, api, RedeemQrScreen(voucher: VoucherItem.fromJson(walletVoucher('v1'))));

      expect(find.byKey(const Key('redeem-qr')), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      expect(find.textContaining('Còn hiệu lực'), findsOneWidget);

      await tester.tap(find.text('Làm mới mã'));
      await tester.pumpAndSettle();
      expect(api.calls('POST', '/redeem/token').length, 2);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('vuot 10 lan / 10 phut: bao thoi gian thu lai, khong tu lam moi', (tester) async {
      final api = FakeApi({
        'POST /redeem/token': (_) => const FakeResponse.error(429, 'Bạn đã tạo mã 10 lần trong 10 phút.',
            reason: 'TOKEN_RATE_LIMITED', details: {'retryAt': '2026-10-21T08:00:00.000Z', 'retryAfterSeconds': 120}),
      });
      await pumpScreen(tester, api, RedeemQrScreen(voucher: VoucherItem.fromJson(walletVoucher('v1'))));

      expect(find.byKey(const Key('redeem-blocked')), findsOneWidget);
      // 08:00 UTC = 15:00 gio Viet Nam
      expect(find.textContaining('21/10/2026 15:00'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('nhan vien vua xac nhan: bao "Voucher đã được sử dụng"', (tester) async {
      final api = FakeApi({
        'POST /redeem/token': (_) => const FakeResponse.error(400, 'Voucher đã được sử dụng.', reason: 'VOUCHER_USED'),
        'GET /wallet': (_) => const FakeResponse.ok([]),
      });
      await pumpScreen(tester, api, RedeemQrScreen(voucher: VoucherItem.fromJson(walletVoucher('v1'))));

      expect(find.byKey(const Key('redeem-used')), findsOneWidget);
      expect(find.text('Về ví voucher'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('hoan tien (task 17)', () {
    testWidgets('gui yeu cau: hien ket qua theo trang thai may chu tra ve', (tester) async {
      final api = FakeApi({
        'POST /refunds': (_) => const FakeResponse.ok({
              'id': 'r1',
              'voucherItemId': 'v1',
              'status': 'FAILED',
              'rejectReason': 'Cổng thanh toán từ chối giao dịch hoàn tiền.',
              'createdAt': '2026-10-21T03:00:00.000Z',
            }),
        'GET /wallet': (_) => const FakeResponse.ok([]),
      });
      await pumpScreen(tester, api, RefundRequestScreen(voucher: VoucherItem.fromJson(walletVoucher('v1'))));
      expect(find.byKey(const Key('refund-deadline')), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Đổi kế hoạch');
      await tester.tap(find.text('Gửi yêu cầu'));
      await tester.pumpAndSettle();

      expect(find.text('Hoàn tiền không thành công'), findsOneWidget);
      expect(find.textContaining('Voucher đã được khôi phục'), findsOneWidget);
      expect(api.calls('POST', '/refunds').single.body, contains('Đổi kế hoạch'));
    });

    testWidgets('khong du dieu kien: khoa nut gui, hien ly do', (tester) async {
      final v = walletVoucher('v1', canRefund: false, refundReason: 'Voucher đã được sử dụng nên không thể hoàn tiền.');
      await pumpScreen(tester, FakeApi({}), RefundRequestScreen(voucher: VoucherItem.fromJson(v)));

      expect(find.byKey(const Key('refund-blocked')), findsOneWidget);
      expect(find.textContaining('không thể hoàn tiền'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('theo doi: moi yeu cau co timeline va ly do / ma giao dich', (tester) async {
      final api = FakeApi({
        'GET /refunds/me': (_) => const FakeResponse.ok([
              {
                'id': 'r1',
                'voucherItemId': 'v1',
                'status': 'COMPLETED',
                'createdAt': '2026-10-21T03:00:00.000Z',
                'decidedAt': '2026-10-21T03:01:00.000Z',
                'amount': '80000',
                'campaignTitle': 'Voucher 100K',
                'voucherCode': 'HL-v1',
                'paymentRefund': {'gatewayRefundId': 'SBX-RF-1'},
              },
              {
                'id': 'r2',
                'voucherItemId': 'v2',
                'status': 'MANUAL_PENDING',
                'createdAt': '2026-10-21T04:00:00.000Z',
                'campaignTitle': 'Trà sữa',
              },
            ]),
      });
      await pumpScreen(tester, api, const RefundListScreen());

      expect(find.byKey(const Key('refund-timeline-COMPLETED')), findsOneWidget);
      expect(find.byKey(const Key('refund-timeline-MANUAL_PENDING')), findsOneWidget);
      expect(find.text('Chờ quản trị viên hoàn tiền'), findsOneWidget);
      expect(find.text('Mã giao dịch hoàn: SBX-RF-1'), findsOneWidget);
    });
  });

  group('danh gia (task 19)', () {
    Map<String, FakeResponse Function(dynamic)> reviewRoutes({required bool canReview}) => {
          'GET /campaigns/c1/reviews': (_) => const FakeResponse.ok({
                'items': [
                  {
                    'id': 'rv1',
                    'rating': 4,
                    'comment': 'Ngon',
                    'reviewerName': 'Hân T.',
                    'brandReply': 'Cảm ơn bạn',
                    'createdAt': '2026-10-20T03:00:00.000Z',
                  },
                ],
                'total': 1,
                'page': 1,
                'pageSize': 20,
                'avgRating': 4,
                'reviewCount': 1,
              }),
          'GET /campaigns/c1/reviews/eligibility': (_) => FakeResponse.ok({'canReview': canReview, 'reason': null}),
          'POST /reviews': (_) => const FakeResponse.ok({'id': 'rv2'}),
        };

    testWidgets('hien diem trung binh, danh sach va phan hoi cua thuong hieu', (tester) async {
      final api = FakeApi(reviewRoutes(canReview: false));
      await pumpScreen(tester, api, const Scaffold(body: CampaignReviewsSection(campaignId: 'c1', campaignTitle: 'Voucher 100K')));

      expect(find.byKey(const Key('review-average')), findsOneWidget);
      expect(find.text('Hân T.'), findsOneWidget);
      expect(find.textContaining('Cảm ơn bạn'), findsOneWidget);
      expect(find.byKey(const Key('write-review')), findsNothing, reason: 'khach chua dung voucher khong thay nut');
    });

    testWidgets('Guest khong thay nut danh gia va khong hoi dieu kien', (tester) async {
      final api = FakeApi(reviewRoutes(canReview: true));
      await pumpScreen(tester, api, const Scaffold(body: CampaignReviewsSection(campaignId: 'c1', campaignTitle: 'X')),
          loggedIn: false);
      expect(find.byKey(const Key('write-review')), findsNothing);
      expect(api.calls('GET', '/campaigns/c1/reviews/eligibility'), isEmpty);
    });

    testWidgets('du dieu kien: viet danh gia gui campaignId + so sao + binh luan', (tester) async {
      final api = FakeApi(reviewRoutes(canReview: true));
      await pumpScreen(tester, api, const Scaffold(body: CampaignReviewsSection(campaignId: 'c1', campaignTitle: 'Voucher 100K')));

      await tester.tap(find.byKey(const Key('write-review')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('star-3')));
      await tester.enterText(find.byKey(const Key('review-comment')), 'Tạm ổn');
      await tester.tap(find.text('Gửi đánh giá'));
      await tester.pumpAndSettle();

      final body = api.calls('POST', '/reviews').single.body;
      expect(body, contains('"campaignId":"c1"'));
      expect(body, contains('"rating":3'));
      expect(body, contains('Tạm ổn'));
    });
  });
}
