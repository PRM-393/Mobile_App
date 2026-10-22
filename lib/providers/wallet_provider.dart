import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/api_client.dart';
import '../services/voucher_services.dart';
import '../services/wallet_cache.dart';

// Vi voucher chia theo tab trang thai (FR-REDEEM-01). Mat mang thi hien vi da luu trong SQLite (NFR-MOB-12):
// xem duoc nhung khong sinh ma su dung (LIM-07).
class WalletProvider extends ChangeNotifier {
  WalletProvider(this._orderService, {this._cache});

  final OrderService _orderService;
  final WalletCache? _cache;

  static const tabs = ['ACTIVE', 'USED', 'EXPIRED', 'REFUNDED'];

  List<VoucherItem> _items = const [];
  List<VoucherItem> _visible = const [];
  String _tab = 'ACTIVE';
  bool _loading = false;
  String? _error;
  bool _offline = false;
  DateTime? _cachedAt;

  String get tab => _tab;
  bool get loading => _loading;
  String? get error => _error;
  List<VoucherItem> get items => _items;

  // Dang hien du lieu da luu vi khong goi duoc may chu
  bool get offline => _offline;
  DateTime? get cachedAt => _cachedAt;

  // Danh sach da loc duoc giu lai (cung mot doi tuong) cho toi khi du lieu / tab doi,
  // de Selector o man hinh chi rebuild khi that su thay doi (Module 12)
  List<VoucherItem> get visibleItems => _visible;

  void selectTab(String tab) {
    if (tab == _tab) return;
    _tab = tab;
    _refilter();
    notifyListeners();
  }

  void _refilter() => _visible = _items.where((i) => i.tab == _tab).toList(growable: false);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final json = await _orderService.myWalletJson();
      _items = json.map(VoucherItem.fromJson).toList(growable: false);
      _offline = false;
      _cachedAt = null;
      _refilter();
      await _saveCache(json);
    } on ApiException catch (e) {
      if (!(e.isNetworkError && await _loadCache())) _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCache(List<Map<String, dynamic>> json) async {
    try {
      await _cache?.save(json);
    } catch (_) {
      // cache la phu: loi ghi SQLite khong anh huong vi dang hien
    }
  }

  Future<bool> _loadCache() async {
    try {
      final cached = await _cache?.load();
      if (cached == null) return false;
      _items = cached.items.map(VoucherItem.fromJson).toList(growable: false);
      _offline = true;
      _cachedAt = cached.savedAt;
      _refilter();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Dang xuat: xoa vi cua tai khoan cu khoi bo nho va SQLite
  Future<void> clear() async {
    _items = const [];
    _visible = const [];
    _offline = false;
    _cachedAt = null;
    notifyListeners();
    try {
      await _cache?.clear();
    } catch (_) {}
  }
}
