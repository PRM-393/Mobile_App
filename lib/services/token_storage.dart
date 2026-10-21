import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_user.dart';

// Luu JWT access/refresh token va ho so nguoi dung (tren web: localStorage duoc ma hoa bang WebCrypto) - NFR-SEC
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'voucher_platform_access_token';
  static const _refreshKey = 'voucher_platform_refresh_token';
  static const _userKey = 'voucher_platform_user';

  Future<String>? _device;
  Future<String> deviceId() => _device ??= () async {
    const key = 'voucher_device_id';
    final existing = await _storage.read(key: key);
    if (existing != null) return existing;
    final random = Random.secure();
    final id = List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    await _storage.write(key: key, value: id);
    return id;
  }();

  Future<void> save(LoginResponse session) async {
    await _storage.write(key: _accessKey, value: session.accessToken);
    await _storage.write(key: _refreshKey, value: session.refreshToken);
    await _storage.write(
      key: _userKey,
      value: jsonEncode(session.user.toJson()),
    );
  }

  Future<LoginResponse?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    final rawUser = await _storage.read(key: _userKey);
    if (access == null || refresh == null || rawUser == null) return null;
    return LoginResponse(
      accessToken: access,
      refreshToken: refresh,
      user: AuthUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>),
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }
}
