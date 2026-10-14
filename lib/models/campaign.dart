import 'json_utils.dart';

// Doi tuong nghiep vu khop voi entity BE (SRS muc 7)

class Category {
  const Category({required this.id, required this.name, this.icon});

  final String id;
  final String name;
  final String? icon;

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id'] as String, name: json['name'] as String, icon: json['icon'] as String?);
}

class Store {
  const Store({
    required this.id,
    required this.brandId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
  });

  final String id;
  final String brandId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distanceKm;

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'] as String,
        brandId: json['brandId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        latitude: asDouble(json['latitude']),
        longitude: asDouble(json['longitude']),
        distanceKm: asDoubleOrNull(json['distanceKm']),
      );
}

// Loai voucher theo FR-CAMP-02
const voucherTypeLabels = {
  'DISCOUNT': 'Mã giảm giá',
  'PREPAID': 'Voucher mệnh giá',
  'COMBO': 'Combo',
};

class VoucherCampaign {
  const VoucherCampaign({
    required this.id,
    required this.brandId,
    required this.title,
    required this.voucherType,
    required this.salePrice,
    required this.faceValue,
    required this.totalQuantity,
    required this.soldQuantity,
    required this.reservedQuantity,
    required this.saleStartAt,
    required this.saleEndAt,
    required this.voucherExpireAt,
    required this.status,
    this.image,
    this.description,
    this.terms,
    this.discountType,
    this.discountValue,
    this.maxDiscount,
    this.comboItems,
    this.limitPerUser,
    this.stores = const [],
  });

  final String id;
  final String brandId;
  final String title;
  final String? image;
  final String? description;
  final String? terms;
  final String voucherType;
  final double salePrice;
  final double faceValue;
  // FR-CAMP-12: DISCOUNT dung discountType (AMOUNT / PERCENT) + discountValue (+ maxDiscount); COMBO dung comboItems
  final String? discountType;
  final double? discountValue;
  final double? maxDiscount;
  final String? comboItems;
  final int totalQuantity;
  final int soldQuantity;
  final int reservedQuantity;
  final int? limitPerUser;
  final DateTime saleStartAt;
  final DateTime saleEndAt;
  final DateTime voucherExpireAt;
  final String status;
  final List<Store> stores;

  // Ton kho kha dung = tong - da ban - dang giu cho (FR-CAMP-11)
  // Phan tram tiet kiem hien tren the voucher: giam theo % thi lay discountValue, con lai so gia ban voi gia tri
  int? get savingPercent {
    if (voucherType == 'DISCOUNT' && discountType == 'PERCENT') return discountValue?.round();
    if (faceValue <= 0 || salePrice >= faceValue) return null;
    return ((faceValue - salePrice) / faceValue * 100).round();
  }

  int get availableQuantity => (totalQuantity - soldQuantity - reservedQuantity).clamp(0, totalQuantity);

  factory VoucherCampaign.fromJson(Map<String, dynamic> json) => VoucherCampaign(
        id: json['id'] as String,
        brandId: json['brandId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        image: json['image'] as String?,
        description: json['description'] as String?,
        terms: json['terms'] as String?,
        voucherType: json['voucherType'] as String? ?? 'DISCOUNT',
        salePrice: asDouble(json['salePrice']),
        faceValue: asDouble(json['faceValue']),
        discountType: json['discountType'] as String?,
        discountValue: asDoubleOrNull(json['discountValue']),
        maxDiscount: asDoubleOrNull(json['maxDiscount']),
        comboItems: json['comboItems'] as String?,
        totalQuantity: asInt(json['totalQuantity']),
        soldQuantity: asInt(json['soldQuantity']),
        reservedQuantity: asInt(json['reservedQuantity']),
        limitPerUser: json['limitPerUser'] == null ? null : asInt(json['limitPerUser']),
        saleStartAt: asDate(json['saleStartAt']),
        saleEndAt: asDate(json['saleEndAt']),
        voucherExpireAt: asDate(json['voucherExpireAt']),
        status: json['status'] as String? ?? 'PUBLISHED',
        stores: asList(json['stores'], Store.fromJson),
      );
}

// Ket qua phan trang cua GET /vouchers
class SearchResult {
  const SearchResult({required this.items, required this.total});

  final List<VoucherCampaign> items;
  final int total;

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      SearchResult(items: asList(json['items'], VoucherCampaign.fromJson), total: asInt(json['total']));
}
