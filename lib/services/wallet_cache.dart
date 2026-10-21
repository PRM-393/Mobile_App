import 'dart:convert';

import 'package:sqflite/sqflite.dart';

// Vi da luu lan tai thanh cong gan nhat
class CachedWallet {
  const CachedWallet({required this.items, required this.savedAt});

  final List<Map<String, dynamic>> items;
  final DateTime savedAt;
}

// Cache vi de xem khi mat mang (NFR-MOB-12, LIM-07). Tach interface de widget test dung ban gia trong bo nho.
abstract class WalletCache {
  Future<void> save(List<Map<String, dynamic>> items);
  Future<CachedWallet?> load();
  Future<void> clear();
}

// SQLite (sqflite): moi voucher mot dong, giu thu tu nhu may chu tra ve. Dang xuat thi xoa (du lieu cua tai khoan cu).
class SqliteWalletCache implements WalletCache {
  SqliteWalletCache({this._factory, this._path});

  static const _table = 'wallet_vouchers';

  final DatabaseFactory? _factory;
  final String? _path;
  Database? _db;

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final factory = _factory ?? databaseFactory;
    final path = _path ?? '${await factory.getDatabasesPath()}/voucher_wallet.db';
    return _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE $_table (id TEXT PRIMARY KEY, position INTEGER NOT NULL, json TEXT NOT NULL, saved_at INTEGER NOT NULL)',
        ),
      ),
    );
  }

  @override
  Future<void> save(List<Map<String, dynamic>> items) async {
    final db = await _open();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.delete(_table);
      final batch = txn.batch();
      for (var i = 0; i < items.length; i++) {
        batch.insert(_table, {'id': items[i]['id'], 'position': i, 'json': jsonEncode(items[i]), 'saved_at': now});
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<CachedWallet?> load() async {
    final db = await _open();
    final rows = await db.query(_table, orderBy: 'position ASC');
    if (rows.isEmpty) return null;
    return CachedWallet(
      items: rows.map((r) => jsonDecode(r['json'] as String) as Map<String, dynamic>).toList(),
      savedAt: DateTime.fromMillisecondsSinceEpoch(rows.first['saved_at'] as int),
    );
  }

  @override
  Future<void> clear() async {
    final db = await _open();
    await db.delete(_table);
  }
}

// Ban luu trong bo nho: dung cho test va khi khong mo duoc SQLite
class MemoryWalletCache implements WalletCache {
  CachedWallet? _data;

  @override
  Future<void> save(List<Map<String, dynamic>> items) async =>
      _data = CachedWallet(items: List.of(items), savedAt: DateTime.now());

  @override
  Future<CachedWallet?> load() async => _data;

  @override
  Future<void> clear() async => _data = null;
}
