import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/engage.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/voucher_services.dart';

// F16: thong bao tu may chu (nguon duy nhat). Khi app dang mo, kiem tra moi [pollInterval];
// thong bao moi chua doc duoc hien thanh thong bao cuc bo (LO7, Module 10).
// Moc "da bao toi dau" luu bang SharedPreferences de mo lai app khong bao lai thong bao cu.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider(
    this._service, {
    this._local,
    this._preferences,
    this.pollInterval = const Duration(seconds: 60),
  });

  final EngageService _service;
  final NotificationService? _local;
  final PreferencesService? _preferences;
  final Duration pollInterval;

  List<AppNotification> _items = const [];
  int _unread = 0;
  bool _loading = false;
  String? _error;
  Timer? _timer;
  List<NotificationSetting> _settings = const [];

  List<AppNotification> get items => _items;
  int get unread => _unread;
  bool get loading => _loading;
  String? get error => _error;
  List<NotificationSetting> get settings => _settings;

  // Goi khi dang nhap; dung khi dang xuat
  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => load(silent: true));
    load(silent: true);
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _items = const [];
    _unread = 0;
    notifyListeners();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final page = await _service.myNotifications();
      _items = page.items;
      _unread = page.unread;
      _error = null;
      await _showNewOnDevice(page.items);
    } catch (e) {
      if (!silent) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Lan dau (chua co moc) chi ghi moc, khong bao lai thong bao cu.
  // Chua co thong bao nao thi lay moc la luc nay, de thong bao dau tien den sau van duoc hien len may.
  Future<void> _showNewOnDevice(List<AppNotification> items) async {
    final prefs = _preferences;
    if (prefs == null) return;
    final last = prefs.lastNotifiedAt;
    if (items.isEmpty) {
      if (last == null) await prefs.setLastNotifiedAt(DateTime.now().toUtc());
      return;
    }
    final newest = items.map((n) => n.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
    if (last != null) {
      final fresh = items.where((n) => !n.isRead && n.createdAt.isAfter(last)).toList().reversed;
      for (final n in fresh) {
        await _local?.show(n.title, n.body);
      }
    }
    if (last == null || newest.isAfter(last)) await prefs.setLastNotifiedAt(newest);
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    _items = [for (final x in _items) x.id == n.id ? x.markedRead(DateTime.now()) : x];
    _unread = (_unread - 1).clamp(0, 1 << 30);
    notifyListeners();
    try {
      await _service.markNotificationRead(n.id);
    } catch (_) {
      // lan tai sau se dong bo lai
    }
  }

  Future<void> markAllRead() async {
    final now = DateTime.now();
    _items = [for (final x in _items) x.isRead ? x : x.markedRead(now)];
    _unread = 0;
    notifyListeners();
    await _service.markAllNotificationsRead();
  }

  Future<void> loadSettings() async {
    _settings = await _service.notificationSettings();
    notifyListeners();
  }

  // Bat / tat mot nhom: doi ngay tren man hinh, loi thi tra lai
  Future<void> toggleSetting(String type, bool enabled) async {
    final before = _settings;
    _settings = [
      for (final s in _settings) s.type == type ? NotificationSetting(type: s.type, label: s.label, enabled: enabled) : s,
    ];
    notifyListeners();
    try {
      _settings = await _service.updateNotificationSetting(type, enabled);
    } catch (_) {
      _settings = before;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
