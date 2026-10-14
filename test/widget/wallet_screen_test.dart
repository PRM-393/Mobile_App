import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:voucher_platform_mobile/providers/wallet_provider.dart';
import 'package:voucher_platform_mobile/screens/wallet/wallet_screen.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';

Map<String, dynamic> voucher(String id, String status, String title) => {
  'id': id,
  'orderId': 'o1',
  'campaignId': 'c1',
  'code': 'HL-$id',
  'status': status,
  'issuedAt': '2026-10-12T03:00:00.000Z',
  'expireAt': '2099-01-01T00:00:00.000Z',
  'usedAt': status == 'USED' ? '2026-10-13T03:00:00.000Z' : null,
  'campaign': {'id': 'c1', 'title': title, 'salePrice': '80000', 'faceValue': '100000'},
};

// Widget test (Module 11): man vi tai du lieu tu API, chia tab, nut theo trang thai voucher (FR-REDEEM-01)
void main() {
  Widget buildApp(List<Map<String, dynamic>> data) {
    final api = ApiClient(
      baseUrl: 'http://api.test/api',
      httpClient: MockClient(
        (_) async => http.Response(jsonEncode(data), 200, headers: {'content-type': 'application/json; charset=utf-8'}),
      ),
    );
    return ChangeNotifierProvider(
      create: (_) => WalletProvider(OrderService(api)),
      child: const MaterialApp(home: WalletScreen()),
    );
  }

  testWidgets('tab "Đang hiệu lực" chi hien voucher ACTIVE kem nut su dung va hoan tien', (tester) async {
    await tester.pumpWidget(
      buildApp([voucher('v1', 'ACTIVE', 'Voucher 100K'), voucher('v2', 'USED', 'Combo bánh mì')]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Voucher 100K'), findsOneWidget);
    expect(find.text('Combo bánh mì'), findsNothing);
    expect(find.text('Sử dụng ngay'), findsOneWidget);
    expect(find.text('Hoàn tiền'), findsOneWidget);
    expect(find.byKey(const ValueKey('v1')), findsOneWidget);
  });

  testWidgets('chuyen sang tab "Đã dùng" hien voucher da dung va nut danh gia', (tester) async {
    await tester.pumpWidget(
      buildApp([voucher('v1', 'ACTIVE', 'Voucher 100K'), voucher('v2', 'USED', 'Combo bánh mì')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đã dùng'));
    await tester.pumpAndSettle();

    expect(find.text('Combo bánh mì'), findsOneWidget);
    expect(find.text('Voucher 100K'), findsNothing);
    expect(find.text('Đánh giá'), findsOneWidget);
    expect(find.text('Sử dụng ngay'), findsNothing);
  });

  testWidgets('vi rong thi hien thong bao trong', (tester) async {
    await tester.pumpWidget(buildApp([]));
    await tester.pumpAndSettle();
    expect(find.text('Không có voucher nào trong mục này.'), findsOneWidget);
  });
}
