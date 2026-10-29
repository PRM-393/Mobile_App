import 'package:flutter/foundation.dart';

import '../models/engage.dart';
import '../services/voucher_services.dart';

// FR-ENGAGE-01 (F06): yeu thich voucher / theo doi thuong hieu.
//
// Truoc day moi man tu goi EngageService.isFavorite(), ma ham do tai TOAN BO danh sach yeu thich chi de
// kiem mot muc - mo mot chi tiet voucher la mot luot tai ca danh sach. Nang hon: bat/tat o man chi tiet
// khong cho man "Yeu thich" biet, nen quay ve danh sach van thay muc vua bo.
//
// Provider nay giu danh sach o mot cho: moi man doc tu day, bat/tat o bat ky dau cung lam ca app doi theo
// (Provider + ChangeNotifier - Module 5).
class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider(this._service);

  final EngageService _service;

  List<Favorite> _items = const [];
  bool _loaded = false;
  bool _loading = false;
  String? _error;

  List<Favorite> get items => _items;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  // Hai nhom hien rieng tren man danh sach: theo doi thuong hieu va yeu thich voucher
  List<Favorite> get brands => _items.where((f) => f.isBrand).toList();
  List<Favorite> get campaigns => _items.where((f) => !f.isBrand).toList();

  bool isFavorite(String targetType, String targetId) =>
      _items.any((f) => f.targetType == targetType && f.targetId == targetId);

  // Tai lai tu may chu. Goi khi mo man danh sach, khi keo de lam moi, va mot lan khi mo man chi tiet
  // neu chua tung tai (ensureLoaded).
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _items = await _service.myFavorites();
      _error = null;
      _loaded = true;
    } catch (e) {
      if (!silent) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLoaded() => _loaded ? Future.value() : load(silent: true);

  // Bat / tat; tra ve true neu sau khi bam dang o trang thai yeu thich.
  // May chu la nguon su that: doi giao dien theo ket qua tra ve, khong doan truoc.
  Future<bool> toggle(String targetType, String targetId) async {
    final favorited = await _service.toggleFavorite(targetType, targetId);
    if (favorited) {
      // Chua co thong tin hien thi (ten / gia) cho muc vua them: tai lai de danh sach du du lieu
      await load(silent: true);
    } else {
      _items = [
        for (final f in _items)
          if (!(f.targetType == targetType && f.targetId == targetId)) f,
      ];
      _loaded = true;
      notifyListeners();
    }
    return favorited;
  }

  // Bo yeu thich ngay tren danh sach, co hoan tac: go khoi giao dien truoc cho muot,
  // loi thi tra muc do ve cho cu.
  Future<void> remove(Favorite favorite) async {
    final before = _items;
    _items = [for (final f in _items) if (f.id != favorite.id) f];
    notifyListeners();
    try {
      await _service.toggleFavorite(favorite.targetType, favorite.targetId);
    } catch (_) {
      _items = before;
      notifyListeners();
      rethrow;
    }
  }

  // Hoan tac sau khi bo nham: bat lai roi tai lai de lay dung thong tin hien thi
  Future<void> undoRemove(Favorite favorite) async {
    await _service.toggleFavorite(favorite.targetType, favorite.targetId);
    await load(silent: true);
  }

  // Dang xuat: xoa du lieu cua tai khoan cu
  void clear() {
    _items = const [];
    _loaded = false;
    _error = null;
    notifyListeners();
  }
}
