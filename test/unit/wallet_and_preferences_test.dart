import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voucher_platform_mobile/models/order.dart';
import 'package:voucher_platform_mobile/providers/wallet_provider.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';
import 'package:voucher_platform_mobile/services/notification_service.dart';
import 'package:voucher_platform_mobile/services/preferences_service.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';

Map<String, dynamic> voucher(String id, String status, {String title = 'Voucher 100K'}) => {
  'id': id,
  'orderId': 'o1',
  'campaignId': 'c1',
  'code': 'HL-$id',
  'status': status,
  'issuedAt': '2026-10-12T03:00:00.000Z',
  'expireAt': '2099-01-01T00:00:00.000Z',
  'campaign': {'id': 'c1', 'title': title, 'salePrice': '80000', 'faceValue': '100000'},
};

// Ghi lai cac thong bao thay vi hien len thiet bi
class RecordingNotifications extends NotificationService {
  final calls = <String>[];

  @override
  Future<void> show(String title, String body) async => calls.add('$title|$body');
}

// Unit test (Module 11, AAA): logic SharedPreferences va phat hien thay doi vi de ban thong bao (LO7)
void main() {
  group('PreferencesService (SharedPreferences - Module 9)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('tu khoa gan day: moi nhat dung dau, khong trung, toi da 8', () async {
      final prefs = await PreferencesService.create();
      for (var i = 1; i <= 10; i++) {
        await prefs.addRecentKeyword('kw$i');
      }
      await prefs.addRecentKeyword('KW9');
      await prefs.addRecentKeyword('  ');

      expect(prefs.recentKeywords.length, PreferencesService.maxRecentKeywords);
      expect(prefs.recentKeywords.first, 'KW9');
      expect(prefs.recentKeywords.where((k) => k.toLowerCase() == 'kw9').length, 1);
    });

    test('du lieu con sau khi mo lai app; dang xuat thi xoa', () async {
      final first = await PreferencesService.create();
      await first.addRecentKeyword('highlands');
      await first.saveWalletSnapshot({'v1': 'ACTIVE'});

      final reopened = await PreferencesService.create();
      expect(reopened.recentKeywords, ['highlands']);
      expect(reopened.walletSnapshot, {'v1': 'ACTIVE'});

      await reopened.clearUserData();
      expect(reopened.recentKeywords, isEmpty);
      expect(reopened.walletSnapshot, isNull);
    });
  });

  group('diffWallet', () {
    List<VoucherItem> items(List<Map<String, dynamic>> list) => list.map(VoucherItem.fromJson).toList();

    test('lan dau (chua co anh chup) khong bao gi ca', () {
      expect(diffWallet(null, items([voucher('v1', 'ACTIVE')])).isEmpty, isTrue);
    });

    test('phat hien voucher moi, da dung, da hoan', () {
      final changes = diffWallet(
        {'v1': 'ACTIVE', 'v2': 'ACTIVE'},
        items([
          voucher('v1', 'USED', title: 'Combo sang'),
          voucher('v2', 'REFUNDED', title: 'Giam 20%'),
          voucher('v3', 'ACTIVE'),
          voucher('v4', 'ACTIVE'),
        ]),
      );
      expect(changes.issued, 2);
      expect(changes.used, ['Combo sang']);
      expect(changes.refunded, ['Giam 20%']);
    });
  });

  group('WalletProvider ban thong bao cuc bo (LO7)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('lan tai dau im lang; lan sau co voucher moi va voucher da dung thi thong bao', () async {
      var response = [voucher('v1', 'ACTIVE')];
      final api = ApiClient(
        baseUrl: 'http://api.test/api',
        httpClient: MockClient(
          (_) async =>
              http.Response(jsonEncode(response), 200, headers: {'content-type': 'application/json; charset=utf-8'}),
        ),
      );
      final notifications = RecordingNotifications();
      final wallet = WalletProvider(
        OrderService(api),
        preferences: await PreferencesService.create(),
        notifications: notifications,
      );

      await wallet.load();
      expect(notifications.calls, isEmpty);
      expect(wallet.visibleItems.map((v) => v.id), ['v1']);

      response = [voucher('v1', 'USED', title: 'Voucher 100K'), voucher('v2', 'ACTIVE')];
      await wallet.load();
      expect(notifications.calls, [
        'Voucher đã về ví|Bạn có 1 voucher mới trong ví.',
        'Đã sử dụng voucher|Voucher 100K',
      ]);

      // Danh sach loc giu nguyen doi tuong khi khong doi tab / du lieu (Selector khong rebuild thua)
      final before = wallet.visibleItems;
      wallet.selectTab('ACTIVE');
      expect(identical(before, wallet.visibleItems), isTrue);
    });
  });
}
