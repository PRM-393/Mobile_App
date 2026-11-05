import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/campaign.dart';
import '../services/preferences_service.dart';

// Mot dong trong gio: chi giu thong tin de hien thi; gia va ton kho that luon lay lai tu may chu khi mo gio
class CartItem {
  const CartItem({
    required this.campaignId,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    this.brandName,
    this.image,
  });

  final String campaignId;
  final String title;
  final double unitPrice;
  final int quantity;
  final String? brandName;
  final String? image;

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({int? quantity, String? title, double? unitPrice, String? brandName}) => CartItem(
    campaignId: campaignId,
    title: title ?? this.title,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    brandName: brandName ?? this.brandName,
    image: image,
  );

  Map<String, dynamic> toJson() => {
    'campaignId': campaignId,
    'title': title,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'brandName': brandName,
    'image': image,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    campaignId: json['campaignId'] as String,
    title: json['title'] as String? ?? '',
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    brandName: json['brandName'] as String?,
    image: json['image'] as String?,
  );
}

// Gio hang tren thiet bi (Provider + SharedPreferences - Module 5, 9). Khach vang lai cung them duoc,
// den luc mua moi can dang nhap. May chu chi nhan don theo tung voucher nen moi dong thanh toan thanh mot don.
class CartProvider extends ChangeNotifier {
  CartProvider([this._preferences]) {
    _items = _read();
  }

  final PreferencesService? _preferences;
  List<CartItem> _items = const [];

  List<CartItem> get items => _items;
  int get totalQuantity => _items.fold(0, (sum, e) => sum + e.quantity);
  bool contains(String campaignId) => _items.any((e) => e.campaignId == campaignId);

  List<CartItem> _read() {
    final raw = _preferences?.cartJson;
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return const []; // du lieu hong thi bat dau gio moi
    }
  }

  void _commit(List<CartItem> items) {
    _items = items;
    _preferences?.setCartJson(jsonEncode(items.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  // Tra ve false neu gio da co so luong toi da duoc mua cua voucher nay
  bool add(VoucherCampaign campaign, {int quantity = 1}) {
    final max = campaign.maxPerOrder;
    final current = _items.where((e) => e.campaignId == campaign.id).firstOrNull;
    if (max <= 0 || (current?.quantity ?? 0) >= max) return false;
    final next = ((current?.quantity ?? 0) + quantity).clamp(1, max);
    final line = CartItem(
      campaignId: campaign.id,
      title: campaign.title,
      unitPrice: campaign.salePrice,
      quantity: next,
      brandName: campaign.brandName ?? current?.brandName,
      image: campaign.image,
    );
    _commit(current == null
        ? [..._items, line]
        : [for (final e in _items) e.campaignId == campaign.id ? line : e]);
    return true;
  }

  void setQuantity(String campaignId, int quantity) {
    if (quantity < 1) return remove(campaignId);
    _commit([for (final e in _items) e.campaignId == campaignId ? e.copyWith(quantity: quantity) : e]);
  }

  void remove(String campaignId) {
    if (!contains(campaignId)) return;
    _commit(_items.where((e) => e.campaignId != campaignId).toList());
  }

  // Cap nhat gia / ten moi nhat tu may chu, giam so luong neu ton kho hoac gioi han da thap hon
  void syncWith(VoucherCampaign campaign) {
    final current = _items.where((e) => e.campaignId == campaign.id).firstOrNull;
    if (current == null) return;
    final max = campaign.maxPerOrder;
    final quantity = max > 0 && current.quantity > max ? max : current.quantity;
    if (quantity == current.quantity && current.unitPrice == campaign.salePrice && current.title == campaign.title) return;
    _commit([
      for (final e in _items)
        e.campaignId == campaign.id
            ? e.copyWith(quantity: quantity, title: campaign.title, unitPrice: campaign.salePrice, brandName: campaign.brandName)
            : e,
    ]);
  }

  void clear() {
    if (_items.isEmpty) return;
    _commit(const []);
  }
}
