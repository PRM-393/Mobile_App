import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';

// F01: ApiClient doc dinh dang { data, error, meta } va van tuong thich phan hoi cu
void main() {
  ApiClient clientReturning(int status, Object body) => ApiClient(
        baseUrl: 'http://api.test/api',
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'}),
        ),
      );

  test('phan hoi boc { data, error, meta } tra ve phan data', () async {
    final api = clientReturning(200, {
      'data': {'items': [1, 2], 'total': 2, 'page': 1, 'pageSize': 20},
      'error': null,
      'meta': {'page': 1, 'pageSize': 20, 'total': 2, 'totalPages': 1},
    });
    expect(await api.get('/vouchers'), {'items': [1, 2], 'total': 2, 'page': 1, 'pageSize': 20});
  });

  test('data null (vd. dang xuat) tra ve null', () async {
    final api = clientReturning(200, {'data': null, 'error': null, 'meta': null});
    expect(await api.post('/auth/logout'), isNull);
  });

  test('phan hoi dinh dang cu (khong boc) giu nguyen', () async {
    final api = clientReturning(200, [
      {'id': 'a'},
    ]);
    expect(await api.get('/wallet'), [
      {'id': 'a'},
    ]);
  });

  test('loi dinh dang moi: lay error.message', () async {
    final api = clientReturning(400, {
      'data': null,
      'error': {'code': 400, 'message': 'Mã đã hết hạn, vui lòng yêu cầu mã mới.', 'path': '/api/redeem', 'timestamp': 'x'},
      'meta': null,
    });
    await expectLater(
      api.post('/redeem', body: {}),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Mã đã hết hạn, vui lòng yêu cầu mã mới.')
          .having((e) => e.statusCode, 'statusCode', 400)),
    );
  });

  test('loi dinh dang cu: message dang mang thi noi bang xuong dong', () async {
    final api = clientReturning(400, {
      'statusCode': 400,
      'message': ['email must be an email', 'password too short'],
    });
    await expectLater(
      api.post('/auth/login', body: {}),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'email must be an email\npassword too short')),
    );
  });
}
