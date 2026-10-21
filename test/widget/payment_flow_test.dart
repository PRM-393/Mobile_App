import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:voucher_platform_mobile/models/order.dart';
import 'package:voucher_platform_mobile/providers/main_tab_controller.dart';
import 'package:voucher_platform_mobile/providers/wallet_provider.dart';
import 'package:voucher_platform_mobile/screens/checkout/payment_result_screen.dart';
import 'package:voucher_platform_mobile/screens/orders/order_history_screen.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';

Map<String, dynamic> orderJson(String status, {DateTime? reservedUntil}) => {
      'id': 'o1',
      'campaignId': 'c1',
      'quantity': 2,
      'totalAmount': '160000',
      'status': status,
      'createdAt': '2026-10-20T03:00:00.000Z',
      'reservedUntil': (reservedUntil ?? DateTime.now().add(const Duration(minutes: 10))).toUtc().toIso8601String(),
      'campaign': {'id': 'c1', 'title': 'Voucher 100K'},
    };

// May chu gia lap tra { data, error, meta } (F01); ghi lai cac request
class FakeServer {
  final requests = <String>[];
  Object? Function(http.Request) handler = (_) => null;

  late final client = MockClient((r) async {
    requests.add('${r.method} ${r.url.path}');
    return http.Response(jsonEncode({'data': handler(r), 'error': null, 'meta': null}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
  });
}

// F09 / F18: unit test model don hang + widget test man ket qua thanh toan va lich su don
void main() {
  group('Order (FR-ORDER-05, FR-ORDER-12)', () {
    test('chi don PENDING con trong thoi gian giu cho moi thanh toan lai duoc', () {
      final now = DateTime.utc(2026, 10, 20, 3);
      Order o(String s, DateTime until) => Order.fromJson(orderJson(s, reservedUntil: until));
      expect(o('PENDING', now.add(const Duration(minutes: 1))).canRetry(now), isTrue);
      expect(o('PENDING', now.subtract(const Duration(minutes: 1))).canRetry(now), isFalse);
      expect(o('FULFILLED', now.add(const Duration(minutes: 1))).canRetry(now), isFalse);
    });

    test('trang thai cuoi va ten chien dich, link payOS rong -> null', () {
      expect(Order.fromJson(orderJson('PAYMENT_MISMATCH')).isFinal, isTrue);
      expect(Order.fromJson(orderJson('PENDING')).isFinal, isFalse);
      expect(Order.fromJson(orderJson('PENDING')).campaignTitle, 'Voucher 100K');
      final r = CreateOrderResult.fromJson({'order': orderJson('PENDING'), 'paymentUrl': null});
      expect(r.paymentUrl, isNull);
    });
  });

  Widget wrap(FakeServer server, Widget child) {
    final api = ApiClient(baseUrl: 'http://api.test/api', httpClient: server.client);
    final orders = OrderService(api);
    return MultiProvider(
      providers: [
        Provider.value(value: orders),
        ChangeNotifierProvider(create: (_) => WalletProvider(orders)),
        ChangeNotifierProvider(create: (_) => MainTabController()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('man ket qua hoi may chu den khi don FULFILLED roi dung lai', (tester) async {
    final server = FakeServer();
    var calls = 0;
    server.handler = (r) {
      if (r.url.path.endsWith('/wallet')) return [];
      calls++;
      return orderJson(calls < 2 ? 'PENDING' : 'FULFILLED');
    };
    await tester.pumpWidget(wrap(
      server,
      PaymentResultScreen(
        args: PaymentResultArgs(order: Order.fromJson(orderJson('PENDING'))),
        pollInterval: const Duration(milliseconds: 100),
      ),
    ));
    expect(find.text('Đang chờ thanh toán'), findsOneWidget);
    // Chua co link payOS -> nut thanh toan thu
    expect(find.byKey(const Key('simulate-pay')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('Thanh toán thành công'), findsOneWidget);
    expect(find.byKey(const Key('go-wallet')), findsOneWidget);

    // Da den trang thai cuoi: khong hoi them
    final before = calls;
    await tester.pump(const Duration(milliseconds: 500));
    expect(calls, before);
  });

  testWidgets('bam thanh toan thu goi simulate-payment va hien ket qua', (tester) async {
    final server = FakeServer();
    server.handler = (r) {
      if (r.url.path.endsWith('/simulate-payment')) return {'outcome': 'FULFILLED', 'order': orderJson('FULFILLED')};
      if (r.url.path.endsWith('/wallet')) return [];
      return orderJson('FULFILLED');
    };
    await tester.pumpWidget(wrap(
      server,
      PaymentResultScreen(
        args: PaymentResultArgs(order: Order.fromJson(orderJson('PENDING'))),
        pollInterval: const Duration(minutes: 5),
      ),
    ));
    await tester.tap(find.byKey(const Key('simulate-pay')));
    await tester.pumpAndSettle();
    expect(server.requests, contains('POST /api/orders/o1/simulate-payment'));
    expect(find.text('Thanh toán thành công'), findsOneWidget);
  });

  testWidgets('lich su don: nut thanh toan lai chi hien cho don con giu cho', (tester) async {
    final server = FakeServer();
    server.handler = (_) => [
          orderJson('PENDING'),
          {...orderJson('CANCELLED'), 'id': 'o2'},
        ];
    await tester.pumpWidget(wrap(server, const OrderHistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán lại'), findsOneWidget);
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(find.text('Voucher 100K'), findsNWidgets(2));
  });
}
