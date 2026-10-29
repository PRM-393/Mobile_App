import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

class WrongAppException implements Exception {
  const WrongAppException();

  @override
  String toString() => 'Tài khoản này dành cho trang web quản lý. Ứng dụng chỉ dành cho khách hàng.';
}

// Trang thai dang nhap toan ung dung (Provider + ChangeNotifier - Module 5).
// Tu dang nhap lai bang refresh token da luu (FR-AUTH-03), khong co "thiet bi tin cay" (BR-23).
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required ApiClient api,
    required this._authService,
    required this._storage,
  }) {
    api.accessTokenGetter = () => _session?.accessToken;
    api.onUnauthorized = _refreshSession;
  }

  final AuthService _authService;
  final TokenStorage _storage;

  LoginResponse? _session;
  bool _isHydrated = false;
  Future<bool>? _refreshing;
  int _generation = 0;

  AuthUser? get user => _session?.user;
  bool get isLoggedIn => _session != null;
  bool get isHydrated => _isHydrated;

  // Doc phien da luu khi app khoi dong
  Future<void> hydrate() async {
    try {
      _session = await _storage.read();
    } catch (_) {
      _session = null;
    }
    _isHydrated = true;
    notifyListeners();
  }

  Future<bool> isRegistered(String email) => _authService.isRegistered(email);

  Future<void> login(String email, String password) => _start(() => _authService.login(email, password));

  Future<void> register(String email, String password, {String? fullName}) =>
      _start(() => _authService.register(email, password, fullName: fullName));

  Future<void> requestResetCode(String email) => _authService.requestResetCode(email);

  Future<void> resetPassword(String email, String code, String password) =>
      _authService.resetPassword(email, code, password);

  // App chi danh cho khach hang (FR-AUTH-07): tai khoan web (chu thuong hieu, nhan vien, quan tri) bi tu choi.
  Future<void> _start(Future<LoginResponse> Function() request) async {
    final generation = ++_generation;
    final session = await request();
    if (generation != _generation) return;
    if (session.user.role != 'CUSTOMER') {
      throw const WrongAppException();
    }
    await _setSession(session);
  }

  // F17: luu thong tin ho so moi vao phien hien tai (giu nguyen token)
  Future<void> updateUser(AuthUser user) async {
    final current = _session;
    if (current == null) return;
    await _setSession(LoginResponse(accessToken: current.accessToken, refreshToken: current.refreshToken, user: user));
  }

  Future<void> logout() async {
    ++_generation;
    try {
      await _authService.logout();
    } catch (_) {
      // bo qua loi mang, van xoa phien cuc bo
    }
    await _clearSession();
  }

  Future<void> _setSession(LoginResponse session) async {
    await _storage.save(session);
    _session = session;
    notifyListeners();
  }

  Future<void> _clearSession() async {
    await _storage.clear();
    _session = null;
    notifyListeners();
  }

  // Goi tu ApiClient khi gap 401: lam moi token mot lan, cac request dong thoi dung chung ket qua
  Future<bool> _refreshSession() {
    if (_session == null) return Future.value(false);
    return _refreshing ??= () async {
      final generation = _generation;
      final refreshToken = _session?.refreshToken;
      if (refreshToken == null) return false;
      try {
        final session = await _authService.refresh(refreshToken);
        if (generation != _generation) return false;
        await _setSession(session);
        return true;
      } catch (_) {
        if (generation == _generation) await _clearSession();
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }
}
