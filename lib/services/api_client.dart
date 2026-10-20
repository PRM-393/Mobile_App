import 'dart:convert';

import 'package:http/http.dart' as http;

// Loi tra ve tu API, message da duoc chuan hoa de hien thi cho nguoi dung (NFR-USA-02)
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

// HTTP client dung chung: gan "Authorization: Bearer <token>" (SRS 8.3) va tu lam moi access token
// khi het han (401) roi thu lai request mot lan (FR-AUTH-03).
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  // Duoc AuthProvider gan sau khi khoi tao (tranh phu thuoc vong)
  String? Function()? accessTokenGetter;
  Future<bool> Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, Object?>? query}) => _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', path, body: body);

  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool authenticated = true,
    bool retry = true,
  }) async {
    final params = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null && e.value.toString().isNotEmpty) e.key: e.value.toString(),
    };
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params.isEmpty ? null : params);
    final token = authenticated ? accessTokenGetter?.call() : null;
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request));
    } catch (_) {
      throw const ApiException('Không kết nối được máy chủ. Vui lòng kiểm tra mạng và thử lại.');
    }

    if (response.statusCode == 401 && authenticated && retry && onUnauthorized != null) {
      if (await onUnauthorized!()) {
        return _send(method, path, query: query, body: body, authenticated: authenticated, retry: false);
      }
    }

    final decoded = response.bodyBytes.isEmpty ? null : _tryDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
    if (response.statusCode >= 400) {
      throw ApiException(_messageOf(decoded) ?? 'Đã có lỗi xảy ra, vui lòng thử lại.',
          statusCode: response.statusCode);
    }
    return unwrap(decoded);
  }

  // F01: may chu tra { data, error, meta } -> tra ve data cho service; phan hoi khong boc (dinh dang cu) giu nguyen
  static Object? unwrap(Object? decoded) {
    if (decoded is Map && decoded.containsKey('data') && decoded.containsKey('error') && decoded.containsKey('meta')) {
      return decoded['data'];
    }
    return decoded;
  }

  static Object? _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // Loi tu BE: { error: { message } } (F01) hoac { message } (dinh dang cu, message co the la object / mang)
  static String? _messageOf(Object? decoded) {
    if (decoded is Map && decoded['error'] is Map) return (decoded['error'] as Map)['message']?.toString();
    Object? message = decoded is Map ? decoded['message'] : null;
    if (message is Map) message = message['message'];
    if (message is List) return message.join('\n');
    return message?.toString();
  }
}
