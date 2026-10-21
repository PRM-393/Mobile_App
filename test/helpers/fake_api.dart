import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voucher_platform_mobile/models/auth_user.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';
import 'package:voucher_platform_mobile/services/token_storage.dart';

// Phan hoi gia: status + body; body duoc boc { data, error, meta } nhu may chu that (F01)
class FakeResponse {
  const FakeResponse.ok(this.data)
      : status = 200,
        reason = null,
        message = null,
        details = null;

  const FakeResponse.error(this.status, this.message, {this.reason, this.details}) : data = null;

  final int status;
  final Object? data;
  final String? message;
  final String? reason;
  final Map<String, dynamic>? details;

  String get body => jsonEncode(
        status < 400
            ? {'data': data, 'error': null, 'meta': null}
            : {
                'data': null,
                'error': {'code': status, 'message': message, 'reason': reason, 'details': details},
                'meta': null,
              },
      );
}

// May chu gia theo route "METHOD /path" (khong kem query); ghi lai cac request da goi de kiem tra
class FakeApi {
  FakeApi(this.routes, {this.offline = false});

  final Map<String, FakeResponse Function(http.Request req)> routes;
  bool offline;
  final List<http.Request> requests = [];

  ApiClient client() => ApiClient(
        baseUrl: 'http://api.test/api',
        httpClient: MockClient((req) async {
          if (offline) throw const SocketLikeException();
          requests.add(req);
          final key = '${req.method} ${req.url.path.replaceFirst('/api', '')}';
          final handler = routes[key];
          final res = handler == null ? const FakeResponse.error(404, 'Not found') : handler(req);
          return http.Response(res.body, res.status, headers: {'content-type': 'application/json; charset=utf-8'});
        }),
      );

  Iterable<http.Request> calls(String method, String path) =>
      requests.where((r) => r.method == method && r.url.path == '/api$path');
}

class SocketLikeException implements Exception {
  const SocketLikeException();
}

// Phien dang nhap san cho test can nguoi dung da dang nhap
class LoggedInTokenStorage extends TokenStorage {
  @override
  Future<LoginResponse?> read() async => LoginResponse(
        accessToken: 'access',
        refreshToken: 'refresh',
        user: AuthUser.fromJson({'id': 'u1', 'email': 'khach@voucher.local', 'role': 'CUSTOMER', 'fullName': 'Khách'}),
      );

  @override
  Future<void> save(LoginResponse session) async {}

  @override
  Future<void> clear() async {}
}

const _future = '2099-01-01T00:00:00.000Z';

// Voucher trong vi dung dinh dang GET /wallet moi
Map<String, dynamic> walletVoucher(
  String id, {
  String status = 'ACTIVE',
  String title = 'Voucher 100K',
  String expireAt = _future,
  bool canRefund = true,
  String? refundReason,
  bool canReview = false,
  bool hasReviewed = false,
}) =>
    {
      'id': id,
      'orderId': 'o1',
      'campaignId': 'c-$id',
      'code': 'HL-$id',
      'status': status,
      'issuedAt': '2026-10-12T03:00:00.000Z',
      'expireAt': expireAt,
      'refundableUntil': '2099-01-01T00:00:00.000Z',
      'usedAt': status == 'USED' ? '2026-10-13T03:00:00.000Z' : null,
      'campaign': {'id': 'c-$id', 'title': title, 'salePrice': '80000', 'faceValue': '100000'},
      'refund': {
        'canRefund': canRefund,
        'reasonCode': canRefund ? null : 'REFUND_WINDOW_PASSED',
        'reason': refundReason,
        'refundableUntil': '2026-10-19T03:00:00.000Z',
      },
      'review': {'canReview': canReview, 'hasReviewed': hasReviewed},
    };
