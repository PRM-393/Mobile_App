// Kiem thu tich hop that: goi BE dang chay bang dung cac service cua app (khong mock).
// Chay BE truoc:  (BE) npx ts-node -T test/helpers/serve-memory.ts 3999
// Roi:            flutter test test/live --dart-define=LIVE_API=http://localhost:3999/api
// Khong co LIVE_API thi bo qua.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';
import 'package:voucher_platform_mobile/services/auth_service.dart';
import 'package:voucher_platform_mobile/services/profile_service.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';

const liveApi = String.fromEnvironment('LIVE_API');
const mailFile = String.fromEnvironment('MAIL_FILE', defaultValue: '../BE/.e2e-mail.json');
const stateFile = String.fromEnvironment('STATE_FILE', defaultValue: '../BE/.e2e-live.json');

final results = <String, String?>{};

Future<T?> step<T>(String name, Future<T> Function() fn) async {
  try {
    final v = await fn();
    results[name] = null;
    return v;
  } catch (e) {
    results[name] = e.toString().split('\n').first;
    return null;
  }
}

String lastOtp(String email) {
  final mails = (jsonDecode(File(mailFile).readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final text = mails.lastWhere((m) => m['to'] == email)['text'] as String;
  return RegExp(r'\b\d{6}\b').firstMatch(text)!.group(0)!;
}

void main() {
  test('Mobile <-> BE: luong khach hang day du', () async {
    final api = ApiClient(baseUrl: liveApi);
    String? access;
    api.accessTokenGetter = () => access;
    final auth = AuthService(api);
    final search = SearchService(api);
    final orders = OrderService(api);
    final redeem = RedeemService(api);
    final refunds = RefundService(api);
    final engage = EngageService(api);
    final email = 'live${DateTime.now().millisecondsSinceEpoch}@test.local';

    await step('auth: email moi chua dang ky', () async {
      if (await auth.isRegistered(email)) throw 'bao da dang ky';
    });
    await step('auth: dang ky bang mat khau', () => auth.register(email, 'matkhau1', fullName: 'Khach Live'));
    await step('auth: email da dang ky', () async {
      if (!await auth.isRegistered(email)) throw 'bao chua dang ky';
    });
    await step('auth: dang nhap bang mat khau', () => auth.login(email, 'matkhau1'));
    // doi mat khau thu hoi moi phien cu nen phien dung cho cac buoc sau lay tu lan dang nhap bang mat khau moi
    await step('auth: quen mat khau - ma qua email', () async {
      await auth.requestResetCode(email);
      await auth.resetPassword(email, lastOtp(email), 'matkhau2');
    });
    final session = await step('auth: dang nhap bang mat khau moi', () => auth.login(email, 'matkhau2'));
    access = session?.accessToken;

    await step('tim kiem: danh muc', () => search.categories());
    final found = await step('tim kiem: tu khoa + sap xep', () => search.search(keyword: 'highlands', sort: 'newest'));
    await step('tim kiem: gan toi', () => search.search(lat: 10.7769, lng: 106.7009, radiusKm: 10));
    final campaignId = found?.items.isNotEmpty == true ? found!.items.first.id : null;
    await step('chi tiet voucher', () => search.detail(campaignId!));

    final created = await step('don hang: tao don', () => orders.create(campaignId!, 1));
    final orderId = created?.order.id;
    await step('don hang: xem trang thai', () => orders.getOrder(orderId!));
    await step('don hang: lich su', () => orders.myOrders());
    await step('don hang: thanh toan lai', () => orders.retryPayment(orderId!));
    final paid = await step('don hang: thanh toan gia lap', () => orders.simulatePayment(orderId!));
    if (paid != null && paid.status != 'FULFILLED') results['don hang: thanh toan gia lap'] = 'status=${paid.status}';

    final wallet = await step('vi: danh sach voucher', () => orders.myWallet());
    final items = wallet?.where((v) => v.status == 'ACTIVE').toList() ?? [];
    final token = await step('redeem: sinh QR + OTP', () => redeem.requestToken(items.first.id));

    await step('yeu thich: bat / tat', () => engage.toggleFavorite('CAMPAIGN', campaignId!));
    await step('yeu thich: danh sach co ten that', () async {
      final favs = await engage.myFavorites();
      if (favs.any((f) => f.title == null)) throw 'favorite thieu ten';
    });
    // F06: trang thuong hieu + theo doi
    final detail = await step('chi tiet: co ten thuong hieu', () async {
      final d = await search.detail(campaignId!);
      if (d.brandName == null) throw 'thieu brandName';
      return d;
    });
    final brand = await step('thuong hieu: trang cong khai', () => search.brandPage(detail!.brandId));
    await step('thuong hieu: theo doi', () async {
      if (!await engage.toggleFavorite('BRAND', brand!.id)) throw 'chua theo doi';
      final after = await search.brandPage(brand.id);
      if (after.followerCount != brand.followerCount + 1) throw 'followerCount=${after.followerCount}';
    });
    // F17: ho so
    final profile = ProfileService(api);
    await step('ho so: xem', () => profile.me());
    await step('ho so: sua ho ten + so dien thoai + anh', () async {
      const png = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      final u = await profile.update(fullName: 'Khach Live', phone: '0901234567', avatar: png);
      if (u.phone != '0901234567' || u.avatar != png) throw 'chua luu';
    });
    final page = await step('thong bao: danh sach', () => engage.myNotifications());
    if (page != null && page.items.isEmpty) results['thong bao: danh sach'] = 'khong co thong bao voucher ve vi';
    await step('thong bao: doc tat ca', () => engage.markAllNotificationsRead());
    final settings = await step('thong bao: cai dat', () => engage.notificationSettings());
    await step('thong bao: tat mot nhom', () => engage.updateNotificationSetting(settings!.first.type, false));
    await step('thong bao: dang ky device token', () => engage.registerDeviceToken('fcm-live-test', 'android'));

    // voucher thu 2 (neu co) dung de hoan tien; voucher 1 de cua hang redeem
    final buy2 = await step('don hang: mua them de hoan', () => orders.create(campaignId!, 1));
    if (buy2 != null) await step('don hang: thanh toan don 2', () => orders.simulatePayment(buy2.order.id));
    final wallet2 = await step("vi: tai lai", () => orders.myWallet()) ?? [];
    final refundable = wallet2.where((v) => v.status == 'ACTIVE' && v.id != items.first.id).toList();
    await step('hoan tien: gui yeu cau', () => refunds.request(refundable.first.id, reason: 'test'));
    await step('hoan tien: danh sach', () => refunds.myRequests());
    await step('thong bao: co ket qua hoan tien', () async {
      final page = await engage.myNotifications();
      if (!page.items.any((n) => n.type == 'REFUND_RESULT')) throw 'khong co REFUND_RESULT';
    });

    final refreshed = await step('auth: lam moi token', () => auth.refresh(session!.refreshToken));
    access = refreshed?.accessToken ?? access;

    File(stateFile).writeAsStringSync(jsonEncode({
      'customerEmail': email,
      'customerAccess': access,
      'campaignId': campaignId,
      'voucherItemId': items.isNotEmpty ? items.first.id : null,
      'otpCode': token?.otpCode,
      'qrPayload': token?.qrPayload,
    }));

    final failed = results.entries.where((e) => e.value != null).toList();
    stdout.writeln('\n=== MOBILE: ${results.length - failed.length}/${results.length} buoc qua');
    for (final e in results.entries) {
      stdout.writeln('${e.value == null ? 'OK  ' : 'FAIL'} ${e.key}${e.value == null ? '' : ' -> ${e.value}'}');
    }
  }, skip: liveApi.isEmpty ? 'can --dart-define=LIVE_API' : null, timeout: const Timeout(Duration(minutes: 2)));
}
