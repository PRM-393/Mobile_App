import '../models/auth_user.dart';
import 'api_client.dart';

// F17 / FR-AUTH-05: ho so khach hang (GET / PATCH /users/me)
class ProfileService {
  ProfileService(this._api);

  final ApiClient _api;

  Future<AuthUser> me() async => AuthUser.fromJson(await _api.get('/users/me') as Map<String, dynamic>);

  // avatar: data URL "data:image/jpeg;base64,..." (<= 2 MB); chuoi rong de xoa anh; null = giu nguyen
  Future<AuthUser> update({String? fullName, String? phone, String? avatar}) async => AuthUser.fromJson(
        await _api.patch('/users/me', body: {
          'fullName': ?fullName,
          'phone': ?phone,
          'avatar': ?avatar,
        }) as Map<String, dynamic>,
      );
}
