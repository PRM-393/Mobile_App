// Cau hinh moi truong (NFR-MNT-02: khong hard-code dia chi trong tung man hinh).
// Mac dinh tro toi BE da deploy tren Render nen ca nhom chay / build APK ngay khong can cau hinh:
//   flutter run
//   flutter build apk --release
// Chay voi BE tren may minh thi truyen them (10.0.2.2 = may host khi dung Android emulator):
//   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
// Doi BE production: sua defaultBackend duoi day.
class Env {
  Env._();

  static const defaultBackend = 'https://voucher-platform-api.onrender.com/api';

  // Chi de demo local: --dart-define=DEMO_LOGIN=true cho phep nhap ten ngan (admin, owner, staff, user) va mat khau 123.
  static const bool demoLogin = bool.fromEnvironment('DEMO_LOGIN');

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBackend,
  );
}
