// Cau hinh moi truong, truyen qua --dart-define khi chay/build (NFR-MNT-02: khong hard-code).
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
// Mac dinh 10.0.2.2 la dia chi may host khi chay tren Android emulator.
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
}
