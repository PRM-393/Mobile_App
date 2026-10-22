import '../models/auth_user.dart';
import 'api_client.dart';

// FR-AUTH-01/02/03/08: dang ky bang email, dang nhap bang OTP, lam moi token, dang xuat
class AuthService {
  AuthService(this._api, {this.deviceId});
  final Future<String> Function()? deviceId;

  final ApiClient _api;

  Future<void> register(String email, {String? fullName}) => _api.post(
    '/auth/register',
    body: {'email': email, 'fullName': fullName},
    authenticated: false,
  );

  Future<void> requestOtp(String email) => _api.post(
    '/auth/otp/request',
    body: {'email': email},
    authenticated: false,
  );

  Future<LoginResponse> verifyOtp(String email, String otp) async {
    final json = await _api.post(
      '/auth/otp/verify',
      body: {
        'email': email,
        'otp': otp,
        if (deviceId != null) 'deviceId': await deviceId!(),
      },
      authenticated: false,
    );
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

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
