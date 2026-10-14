import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// Du lieu nho dang key-value luu tren thiet bi bang SharedPreferences (Module 9, NFR-MOB-05):
// tu khoa tim kiem gan day va anh chup trang thai vi de phat hien voucher moi / da dung.
// Token dang nhap KHONG luu o day ma luu bang flutter_secure_storage (TokenStorage).
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const maxRecentKeywords = 8;
  static const _recentKeywordsKey = 'recent_keywords';
  static const _walletSnapshotKey = 'wallet_snapshot';

  static Future<PreferencesService> create() async => PreferencesService(await SharedPreferences.getInstance());

  // ---- Tu khoa tim kiem gan day: moi nhat dung dau, khong trung, toi da 8 ----
  List<String> get recentKeywords => _prefs.getStringList(_recentKeywordsKey) ?? const [];

  Future<void> addRecentKeyword(String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) return;
    final list = [k, ...recentKeywords.where((e) => e.toLowerCase() != k.toLowerCase())];
    await _prefs.setStringList(_recentKeywordsKey, list.take(maxRecentKeywords).toList());
  }

  Future<void> clearRecentKeywords() => _prefs.remove(_recentKeywordsKey);

  // ---- Anh chup vi lan tai truoc: voucherId -> trang thai ----
  Map<String, String>? get walletSnapshot {
    final raw = _prefs.getString(_walletSnapshotKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWalletSnapshot(Map<String, String> snapshot) =>
      _prefs.setString(_walletSnapshotKey, jsonEncode(snapshot));

  // Dang xuat: xoa du lieu cua tai khoan cu
  Future<void> clearUserData() async {
    await _prefs.remove(_walletSnapshotKey);
    await _prefs.remove(_recentKeywordsKey);
  }
}
