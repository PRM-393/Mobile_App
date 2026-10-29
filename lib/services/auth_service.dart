import '../models/auth_user.dart';
import 'api_client.dart';

// FR-AUTH-01/02/03/08/09: kiem tra email, dang ky / dang nhap bang mat khau, quen mat khau (ma qua email),
// lam moi token, dang xuat
class AuthService {
  AuthService(this._api, {this.deviceId});
  final Future<String> Function()? deviceId;

  final ApiClient _api;

  // true: email da co mat khau -> nhap mat khau; false: chuyen sang dang ky
  Future<bool> isRegistered(String email) async {
    final json = await _api.post('/auth/check-email', body: {'email': email}, authenticated: false);
    return (json as Map<String, dynamic>)['registered'] == true;
  }

  Future<LoginResponse> register(String email, String password, {String? fullName}) async {
    final json = await _api.post(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'fullName': ?fullName,
        if (deviceId != null) 'deviceId': await deviceId!(),
      },
      authenticated: false,
    );
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<LoginResponse> login(String email, String password) async {
    final json = await _api.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        if (deviceId != null) 'deviceId': await deviceId!(),
      },
      authenticated: false,
    );
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<void> requestResetCode(String email) =>
      _api.post('/auth/password-reset/code-request', body: {'email': email}, authenticated: false);

  Future<void> resetPassword(String email, String code, String password) => _api.post(
    '/auth/password-reset/code-confirm',
    body: {'email': email, 'code': code, 'password': password},
    authenticated: false,
  );

  Future<LoginResponse> refresh(String refreshToken) async {
    final json = await _api.post(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
      authenticated: false,
    );
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout() => _api.post('/auth/logout');
}
