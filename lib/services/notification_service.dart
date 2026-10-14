import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// FR-ENGAGE-06 / LO7 (Lab 10.5): hien thong bao cuc bo sau cac thao tac quan trong:
// tao don hang, voucher duoc phat hanh, voucher da duoc su dung tai cua hang, hoan tien thanh cong.
// TODO(F16): tich hop firebase_messaging de nhan push tu FCM, lay FCM token roi goi
// EngageService.registerDeviceToken; can file google-services.json / GoogleService-Info.plist.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'voucher_platform_default',
    'Thông báo voucher',
    channelDescription: 'Voucher phát hành, sắp hết hạn, kết quả hoàn tiền',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Khong khoi tao duoc thong bao cuc bo: $e');
    }
  }

  // ---- Thong bao theo nghiep vu ----
  Future<void> orderCreated() =>
      show('Đã tạo đơn hàng', 'Hoàn tất thanh toán trong 15 phút để giữ voucher của bạn.');

  Future<void> vouchersIssued(int count) =>
      show('Voucher đã về ví', count == 1 ? 'Bạn có 1 voucher mới trong ví.' : 'Bạn có $count voucher mới trong ví.');

  Future<void> voucherUsed(String title) => show('Đã sử dụng voucher', title);

  Future<void> voucherRefunded(String title) => show('Hoàn tiền thành công', title);

  Future<void> show(String title, String body) async {
    if (!_ready) return;
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()),
    );
  }
}
