import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voucher_platform_mobile/models/order.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';
import 'package:voucher_platform_mobile/services/wallet_cache.dart';

import '../helpers/fake_api.dart';

void main() {
  group('ApiException doc reason / details cua loi nghiep vu', () {
    test('loi VOUCHER_USED kem chi tiet', () async {
      final api = FakeApi({
        'POST /redeem/token': (_) => const FakeResponse.error(400, 'Voucher đã được sử dụng lúc 10:00 21/10/2026 tại Lê Lợi.',
            reason: 'VOUCHER_USED', details: {'storeName': 'Lê Lợi'}),
      }).client();
      try {
        await api.post('/redeem/token', body: {'voucherItemId': 'v1'});
        fail('phai nem loi');
      } on ApiException catch (e) {
        expect(e.statusCode, 400);
        expect(e.reason, 'VOUCHER_USED');
        expect(e.details?['storeName'], 'Lê Lợi');
        expect(e.message, contains('Lê Lợi'));
        expect(e.isNetworkError, isFalse);
      }
    });

    test('mat mang: isNetworkError de vi chuyen sang du lieu da luu', () async {
      final api = (FakeApi({})..offline = true).client();
      await expectLater(
        api.get('/wallet'),
        throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'isNetworkError', isTrue)),
      );
    });
  });

  group('VoucherItem: 4 tab cua vi (FR-REDEEM-01)', () {
    final now = DateTime.utc(2026, 10, 21, 7);
    VoucherItem item(String status, {String expireAt = '2099-01-01T00:00:00.000Z'}) =>
        VoucherItem.fromJson(walletVoucher('v1', status: status, expireAt: expireAt));

    test('REFUND_PENDING nam o tab dang hieu luc, nhan "Đang hoàn tiền", khong tao ma duoc', () {
      final v = item('REFUND_PENDING');
      expect(v.tab, 'ACTIVE');
      expect(v.statusLabel, 'Đang hoàn tiền');
      expect(v.canRedeem, isFalse);
    });

    test('ACTIVE qua han -> tab het han ngay, khong tao ma duoc', () {
      final v = item('ACTIVE', expireAt: '2026-10-21T06:59:00.000Z');
      expect(v.effectiveStatusAt(now), 'EXPIRED');
      expect(v.tab, 'EXPIRED');
      expect(v.canRedeem, isFalse);
    });

    test('doc dieu kien hoan va danh gia tu may chu', () {
      final v = VoucherItem.fromJson(walletVoucher('v1', status: 'USED', canRefund: false, refundReason: 'Đã dùng', canReview: true));
      expect(v.refund?.canRefund, isFalse);
      expect(v.refund?.reason, 'Đã dùng');
      expect(v.refund?.refundableUntil, isNotNull);
      expect(v.canReview, isTrue);
      expect(v.tab, 'USED');
    });
  });

  group('SqliteWalletCache (sqflite) - NFR-MOB-12', () {
    DatabaseFactory? factory;

    setUpAll(() async {
      // May khong co SQLite native (vd. mot so may CI) thi bo qua nhom test nay
      try {
        sqfliteFfiInit();
        final f = databaseFactoryFfi;
        final db = await f.openDatabase(inMemoryDatabasePath);
        await db.close();
        factory = f;
      } catch (_) {
        factory = null;
      }
    });

    test('luu, doc lai dung thu tu va xoa', () async {
      if (factory == null) {
        markTestSkipped('Khong mo duoc SQLite native tren may nay');
        return;
      }
      final cache = SqliteWalletCache(factory: factory, path: inMemoryDatabasePath);
      expect(await cache.load(), isNull);

      await cache.save([walletVoucher('v2', title: 'B'), walletVoucher('v1', title: 'A')]);
      final loaded = await cache.load();
      expect(loaded!.items.map((e) => e['id']), ['v2', 'v1']);
      expect((loaded.items.first['campaign'] as Map)['title'], 'B');
      expect(DateTime.now().difference(loaded.savedAt).inMinutes, lessThan(1));

      // luu lai thay the toan bo (voucher da bi xoa khoi vi khong con)
      await cache.save([walletVoucher('v3')]);
      expect((await cache.load())!.items.map((e) => e['id']), ['v3']);

      await cache.clear();
      expect(await cache.load(), isNull);
    });
  });
}
