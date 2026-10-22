import 'package:shared_preferences/shared_preferences.dart';

// Du lieu nho dang key-value luu tren thiet bi bang SharedPreferences (Module 9, NFR-MOB-05):
// tu khoa tim kiem gan day va moc thong bao da hien tren thiet bi.
// Token dang nhap KHONG luu o day ma luu bang flutter_secure_storage (TokenStorage).
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const maxRecentKeywords = 8;
  static const _recentKeywordsKey = 'recent_keywords';
  static const _lastNotifiedKey = 'last_notified_at';

  static Future<PreferencesService> create() async =>
      PreferencesService(await SharedPreferences.getInstance());

  // ---- Tu khoa tim kiem gan day: moi nhat dung dau, khong trung, toi da 8 ----
  List<String> get recentKeywords =>
      _prefs.getStringList(_recentKeywordsKey) ?? const [];

  Future<void> addRecentKeyword(String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) return;
    final list = [
      k,
      ...recentKeywords.where((e) => e.toLowerCase() != k.toLowerCase()),
    ];
    await _prefs.setStringList(
      _recentKeywordsKey,
      list.take(maxRecentKeywords).toList(),
    );
  }

  Future<void> clearRecentKeywords() => _prefs.remove(_recentKeywordsKey);

  // ---- Moc thong bao da hien tren thiet bi (F16): chi bao thong bao moi hon moc nay ----
  DateTime? get lastNotifiedAt {
    final raw = _prefs.getString(_lastNotifiedKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastNotifiedAt(DateTime value) => _prefs.setString(_lastNotifiedKey, value.toUtc().toIso8601String());

  // Dang xuat: xoa du lieu cua tai khoan cu
  Future<void> clearUserData() async {
    await _prefs.remove(_lastNotifiedKey);
    await _prefs.remove(_recentKeywordsKey);
  }
}
