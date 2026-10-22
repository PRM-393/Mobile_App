// Phan 2 cua kiem thu tich hop: chay SAU khi web cua hang da redeem voucher (FE test/live).
//   flutter test test/live/after_redeem_test.dart --dart-define=LIVE_API=http://localhost:3999/api
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';
import 'package:voucher_platform_mobile/services/auth_service.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';

const liveApi = String.fromEnvironment('LIVE_API');
const stateFile = String.fromEnvironment('STATE_FILE', defaultValue: '../BE/.e2e-live.json');

void main() {
  test('Mobile <-> BE: sau khi cua hang redeem', () async {
    final state = jsonDecode(File(stateFile).readAsStringSync()) as Map<String, dynamic>;
    final api = ApiClient(baseUrl: liveApi)..accessTokenGetter = () => state['customerAccess'] as String?;
    final results = <String, String?>{};
    Future<void> step(String name, Future<void> Function() fn) async {
      try {
        await fn();
        results[name] = null;
      } catch (e) {
        results[name] = e.toString().split('\n').first;
      }
    }

    final orders = OrderService(api);
    final engage = EngageService(api);
    await step('vi: voucher da chuyen sang USED', () async {
      final v = (await orders.myWallet()).firstWhere((v) => v.id == state['voucherItemId']);
      if (v.status != 'USED') throw 'status=${v.status}';
    });
    await step('thong bao: co thong bao da su dung', () async {
      final page = await engage.myNotifications();
      if (!page.items.any((n) => n.type == 'VOUCHER_USED')) throw 'khong co VOUCHER_USED (${page.items.map((n) => n.type).toSet()})';
    });
    await step('danh gia: tao danh gia', () => engage.createReview(state['campaignId'] as String, 5, comment: 'Ngon'));
    await step('auth: dang xuat', () => AuthService(api).logout());

    final failed = results.values.where((v) => v != null).length;
    stdout.writeln('\n=== MOBILE (sau redeem): ${results.length - failed}/${results.length} buoc qua');
    for (final e in results.entries) {
      stdout.writeln('${e.value == null ? 'OK  ' : 'FAIL'} ${e.key}${e.value == null ? '' : ' -> ${e.value}'}');
    }
  }, skip: liveApi.isEmpty ? 'can --dart-define=LIVE_API' : null);
}
