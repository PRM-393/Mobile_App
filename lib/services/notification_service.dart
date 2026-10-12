import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// FR-ENGAGE-06 / LO7: hien thong bao cuc bo tren thiet bi (vd. voucher da phat hanh, sap het han).
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
