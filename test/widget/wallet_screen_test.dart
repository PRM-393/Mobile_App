import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voucher_platform_mobile/providers/wallet_provider.dart';
import 'package:voucher_platform_mobile/screens/wallet/wallet_screen.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';
import 'package:voucher_platform_mobile/services/wallet_cache.dart';

import '../helpers/fake_api.dart';

// Widget test (Module 11): man vi tai du lieu tu API, chia 4 tab, nut theo trang thai voucher (FR-REDEEM-01),
// mat mang thi hien vi da luu va an nut tao ma (NFR-MOB-12, LIM-07)
void main() {
  Widget buildApp(FakeApi api, {WalletCache? cache}) => ChangeNotifierProvider(
        create: (_) => WalletProvider(OrderService(api.client()), cache: cache),
        child: const MaterialApp(home: WalletScreen()),
      );

  FakeApi walletApi(List<Map<String, dynamic>> data) => FakeApi({'GET /wallet': (_) => FakeResponse.ok(data)});

  testWidgets('tab "Đang hiệu lực": voucher ACTIVE co nut su dung; REFUND_PENDING hien nhan "Đang hoàn tiền", khong cho dung',
      (tester) async {
    await tester.pumpWidget(buildApp(walletApi([
      walletVoucher('v1', title: 'Voucher 100K'),
      walletVoucher('v2', status: 'REFUND_PENDING', title: 'Trà sữa'),
      walletVoucher('v3', status: 'USED', title: 'Combo bánh mì'),
    ])));
    await tester.pumpAndSettle();

    expect(find.text('Voucher 100K'), findsOneWidget);
    expect(find.text('Trà sữa'), findsOneWidget);
    expect(find.text('Combo bánh mì'), findsNothing);
    expect(find.text('Đang hoàn tiền'), findsOneWidget);
    expect(find.text('Sử dụng ngay'), findsOneWidget, reason: 'chi voucher ACTIVE moi tao ma duoc');
    expect(find.byKey(const ValueKey('v1')), findsOneWidget);
  });

  testWidgets('het han xet theo expireAt: voucher ACTIVE qua han nam o tab "Hết hạn"', (tester) async {
    await tester.pumpWidget(buildApp(walletApi([
      walletVoucher('v1', title: 'Đã quá hạn', expireAt: '2020-01-01T00:00:00.000Z'),
    ])));
    await tester.pumpAndSettle();
    expect(find.text('Đã quá hạn'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Hết hạn'));
    await tester.pumpAndSettle();
    expect(find.text('Đã quá hạn'), findsOneWidget);
    expect(find.text('Sử dụng ngay'), findsNothing);
  });

  testWidgets('tab "Đã dùng": nut danh gia chi hien khi may chu cho phep (BR-10)', (tester) async {
    await tester.pumpWidget(buildApp(walletApi([
      walletVoucher('v1', status: 'USED', title: 'Combo bánh mì', canReview: true),
      walletVoucher('v2', status: 'USED', title: 'Đã đánh giá', hasReviewed: true),
    ])));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Đã dùng'));
    await tester.pumpAndSettle();

    expect(find.text('Combo bánh mì'), findsOneWidget);
    expect(find.text('Đã đánh giá'), findsOneWidget);
    expect(find.text('Đánh giá'), findsOneWidget);
    expect(find.text('Sử dụng ngay'), findsNothing);
  });

  testWidgets('vi rong thi hien thong bao trong', (tester) async {
    await tester.pumpWidget(buildApp(walletApi([])));
    await tester.pumpAndSettle();
    expect(find.text('Không có voucher nào trong mục này.'), findsOneWidget);
  });

  testWidgets('mat mang: hien vi da luu kem banner, an nut tao ma va noi ro ly do (LIM-07)', (tester) async {
    final cache = MemoryWalletCache();
    final api = walletApi([walletVoucher('v1', title: 'Voucher 100K')]);
    await tester.pumpWidget(buildApp(api, cache: cache));
    await tester.pumpAndSettle();
    expect(find.text('Sử dụng ngay'), findsOneWidget);
    expect(find.byKey(const Key('wallet-offline-banner')), findsNothing);

    // Mat mang roi tai lai: van xem duoc vi
    api.offline = true;
    await tester.drag(find.text('Voucher 100K'), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('Voucher 100K'), findsOneWidget);
    expect(find.byKey(const Key('wallet-offline-banner')), findsOneWidget);
    expect(find.text('Sử dụng ngay'), findsNothing);
    expect(find.byKey(const Key('redeem-offline-hint')), findsOneWidget);
  });

  testWidgets('mat mang va chua tung luu vi: bao loi kem nut thu lai', (tester) async {
    final api = walletApi([])..offline = true;
    await tester.pumpWidget(buildApp(api, cache: MemoryWalletCache()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không kết nối được máy chủ'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
