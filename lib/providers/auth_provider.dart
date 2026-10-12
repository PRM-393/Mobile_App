import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

// Trang thai dang nhap toan ung dung (Provider + ChangeNotifier - Module 5).
// Tu dang nhap lai bang refresh token da luu (FR-AUTH-03), khong co "thiet bi tin cay" (BR-23).
class AuthProvider extends ChangeNotifier {
  AuthProvider({required ApiClient api, required this._authService, required this._storage}) {
    api.accessTokenGetter = () => _session?.accessToken;
    api.onUnauthorized = _refreshSession;
  }

  final AuthService _authService;
  final TokenStorage _storage;

  LoginResponse? _session;
  bool _isHydrated = false;
  Future<bool>? _refreshing;

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

  Future<void> requestOtp(String email) => _authService.requestOtp(email);

  Future<void> verifyOtp(String email, String otp) async {
    final session = await _authService.verifyOtp(email, otp);
    await _setSession(session);
  }

  Future<void> logout() async {
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
    return _refreshing ??= () async {
      final refreshToken = _session?.refreshToken;
      if (refreshToken == null) return false;
      try {
        await _setSession(await _authService.refresh(refreshToken));
        return true;
      } catch (_) {
        await _clearSession();
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }
}
