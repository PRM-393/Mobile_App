import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../services/voucher_services.dart';

// Thay doi cua vi giua hai lan tai: dung de ban thong bao cuc bo (LO7)
class WalletChanges {
  const WalletChanges({this.issued = 0, this.used = const [], this.refunded = const []});

  final int issued;
  final List<String> used;
  final List<String> refunded;

  bool get isEmpty => issued == 0 && used.isEmpty && refunded.isEmpty;
}

// So sanh anh chup lan truoc (voucherId -> trang thai) voi danh sach moi.
// previous == null (lan dau mo app / vua dang nhap) thi khong bao gi ca de tranh bao lai voucher cu.
WalletChanges diffWallet(Map<String, String>? previous, List<VoucherItem> items) {
  if (previous == null) return const WalletChanges();
  var issued = 0;
  final used = <String>[], refunded = <String>[];
  for (final item in items) {
    final before = previous[item.id];
    final title = item.campaign?.title ?? 'Voucher ${item.code}';
    if (before == null) {
      issued++;
    } else if (before != item.status) {
      if (item.status == 'USED') used.add(title);
      if (item.status == 'REFUNDED') refunded.add(title);
    }
  }
  return WalletChanges(issued: issued, used: used, refunded: refunded);
}

// Vi voucher chia theo tab trang thai (FR-REDEEM-01)
class WalletProvider extends ChangeNotifier {
  WalletProvider(this._orderService, {this._preferences, this._notifications});

  final OrderService _orderService;
  final PreferencesService? _preferences;
  final NotificationService? _notifications;

  static const tabs = ['ACTIVE', 'USED', 'EXPIRED', 'REFUNDED'];

  List<VoucherItem> _items = const [];
  List<VoucherItem> _visible = const [];
  String _tab = 'ACTIVE';
  bool _loading = false;
  String? _error;

  String get tab => _tab;
  bool get loading => _loading;
  String? get error => _error;

  // Danh sach da loc duoc giu lai (cung mot doi tuong) cho toi khi du lieu / tab doi,
  // de Selector o man hinh chi rebuild khi that su thay doi (Module 12)
  List<VoucherItem> get visibleItems => _visible;

  void selectTab(String tab) {
    if (tab == _tab) return;
    _tab = tab;
    _refilter();
    notifyListeners();
  }

  void _refilter() => _visible = _items.where((i) => i.effectiveStatus == _tab).toList(growable: false);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _orderService.myWallet();
      _refilter();
      await _notifyChanges();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _notifyChanges() async {
    final prefs = _preferences;
    if (prefs == null) return;
    final changes = diffWallet(prefs.walletSnapshot, _items);
    await prefs.saveWalletSnapshot({for (final i in _items) i.id: i.status});
    final n = _notifications;
    if (n == null || changes.isEmpty) return;
    if (changes.issued > 0) await n.vouchersIssued(changes.issued);
    for (final title in changes.used) {
      await n.voucherUsed(title);
    }
    for (final title in changes.refunded) {
      await n.voucherRefunded(title);
    }
  }
}
