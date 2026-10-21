import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voucher_platform_mobile/models/engage.dart';
import 'package:voucher_platform_mobile/providers/notification_provider.dart';
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

Map<String, dynamic> notification(String id, String createdAt, {bool read = false, String title = 'Voucher đã về ví'}) => {
  'id': id,
  'type': 'VOUCHER_ISSUED',
  'title': title,
  'body': 'Body $id',
  'data': {'orderId': 'o-$id'},
  'createdAt': createdAt,
  'readAt': read ? createdAt : null,
};

// Ghi lai cac thong bao thay vi hien len thiet bi
class RecordingNotifications extends NotificationService {
  final calls = <String>[];

  @override
  Future<void> show(String title, String body) async => calls.add('$title|$body');
}

// May chu gia tra { data, error, meta } (F01)
ApiClient fakeApi(Object? Function(http.Request r) handler, {List<String>? log}) => ApiClient(
  baseUrl: 'http://api.test/api',
  httpClient: MockClient((r) async {
    log?.add('${r.method} ${r.url.path}');
    return http.Response(
      jsonEncode({'data': handler(r), 'error': null, 'meta': null}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

// Unit test (Module 11, AAA): SharedPreferences, danh sach vi, thong bao (F16 / LO7)
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
      await first.setLastNotifiedAt(DateTime.utc(2026, 10, 20, 3));

      final reopened = await PreferencesService.create();
      expect(reopened.recentKeywords, ['highlands']);
      expect(reopened.lastNotifiedAt, DateTime.utc(2026, 10, 20, 3));

      await reopened.clearUserData();
      expect(reopened.recentKeywords, isEmpty);
      expect(reopened.lastNotifiedAt, isNull);
    });
  });

  test('WalletProvider: danh sach loc giu nguyen doi tuong khi khong doi (Selector khong rebuild thua)', () async {
    final wallet = WalletProvider(OrderService(fakeApi((_) => [voucher('v1', 'ACTIVE'), voucher('v2', 'USED')])));
    await wallet.load();
    expect(wallet.visibleItems.map((v) => v.id), ['v1']);
    final before = wallet.visibleItems;
    wallet.selectTab('ACTIVE');
    expect(identical(before, wallet.visibleItems), isTrue);
    wallet.selectTab('USED');
    expect(wallet.visibleItems.map((v) => v.id), ['v2']);
  });

  group('NotificationPage', () {
    test('doc { items, unread, total } va van doc duoc mang cu', () {
      final page = NotificationPage.fromJson({
        'items': [notification('n1', '2026-10-20T03:00:00Z')],
        'unread': 1,
        'total': 1,
        'page': 1,
        'pageSize': 20,
      });
      expect([page.items.single.data['orderId'], page.unread, page.total], ['o-n1', 1, 1]);
      final legacy = NotificationPage.fromJson([
        notification('a', '2026-10-20T03:00:00Z'),
        notification('b', '2026-10-20T03:00:00Z', read: true),
      ]);
      expect(legacy.unread, 1);
    });
  });

  group('NotificationProvider (F16, LO7)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('lan dau chi ghi moc; lan sau chi bao thong bao moi chua doc len thiet bi', () async {
      var items = [notification('n1', '2026-10-20T03:00:00Z', title: 'Cu')];
      final local = RecordingNotifications();
      final provider = NotificationProvider(
        EngageService(fakeApi((_) => {'items': items, 'unread': items.length, 'total': items.length})),
        local: local,
        preferences: await PreferencesService.create(),
      );

      await provider.load();
      expect(local.calls, isEmpty);
      expect(provider.unread, 1);

      items = [
        notification('n3', '2026-10-20T05:00:00Z', title: 'Moi 2'),
        notification('n2', '2026-10-20T04:00:00Z', title: 'Moi 1', read: true),
        notification('n1', '2026-10-20T03:00:00Z', title: 'Cu'),
      ];
      await provider.load(silent: true);
      expect(local.calls, ['Moi 2|Body n3']);

      // Tai lai khong bao trung
      await provider.load(silent: true);
      expect(local.calls, hasLength(1));
    });

    test('danh dau da doc cap nhat ngay tren man hinh va goi may chu', () async {
      final log = <String>[];
      final provider = NotificationProvider(EngageService(fakeApi((r) {
        if (r.url.path.endsWith('/notifications/me')) {
          return {
            'items': [notification('n1', '2026-10-20T03:00:00Z'), notification('n2', '2026-10-20T04:00:00Z')],
            'unread': 2,
            'total': 2,
          };
        }
        return null;
      }, log: log)));
      await provider.load();
      await provider.markRead(provider.items.first);
      expect(provider.unread, 1);
      expect(provider.items.first.isRead, isTrue);
      await provider.markAllRead();
      expect(provider.unread, 0);
      expect(log, containsAll(['PATCH /api/notifications/n1/read', 'PATCH /api/notifications/read-all']));
    });

    test('tat mot nhom thong bao goi PUT /notifications/settings', () async {
      final log = <String>[];
      final provider = NotificationProvider(EngageService(fakeApi((r) {
        final enabled = r.method == 'PUT' ? (jsonDecode(r.body) as Map)['enabled'] : true;
        return [
          {'type': 'VOUCHER_ISSUED', 'label': 'Voucher đã phát hành', 'enabled': enabled},
        ];
      }, log: log)));
      await provider.loadSettings();
      expect(provider.settings.single.enabled, isTrue);
      await provider.toggleSetting('VOUCHER_ISSUED', false);
      expect(provider.settings.single.enabled, isFalse);
      expect(log, contains('PUT /api/notifications/settings'));
    });
  });
}
