import '../utils/format.dart';
import 'json_utils.dart';

// Doi tuong nghiep vu khop voi entity BE (SRS muc 7)

class Category {
  const Category({required this.id, required this.name, this.icon});

  final String id;
  final String name;
  final String? icon;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String?,
  );
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
};

class VoucherCampaign {
  const VoucherCampaign({
    required this.id,
    required this.brandId,
    this.brandName,
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
    this.limitPerUser,
    this.stores = const [],
    this.distanceKm,
    this.refundDescription,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.reviews = const [],
  });

  final String id;
  final String brandId;
  // F06: ten thuong hieu (API chi tiet tra kem brand), null o danh sach
  final String? brandName;
  final String title;
  final String? image;
  final String? description;
  final String? terms;
  final String voucherType;
  final double salePrice;
  final double faceValue;
  // FR-CAMP-12: DISCOUNT dùng discountType + discountValue; PREPAID dùng mệnh giá.
  final String? discountType;
  final double? discountValue;
  final double? maxDiscount;
  final int totalQuantity;
  final int soldQuantity;
  final int reservedQuantity;
  final int? limitPerUser;
  final DateTime saleStartAt;
  final DateTime saleEndAt;
  final DateTime voucherExpireAt;
  final String status;
  final List<Store> stores;
  final double? distanceKm;
  final String? refundDescription;
  final double averageRating;
  final int reviewCount;
  final List<Map<String, dynamic>> reviews;

  bool get isDiscount => voucherType == 'DISCOUNT';

  // Ma giam gia khong co "gia goc": khach tra tien de lay ma, gia tri la muc giam khi dung tai cua hang.
  // Gach ngang faceValue se khien ma "Giam 30%" trong nhu giam 85%.
  String? get discountLabel {
    if (!isDiscount || discountValue == null) return null;
    if (discountType == 'PERCENT') {
      final cap = maxDiscount != null && maxDiscount! > 0 ? ', tối đa ${formatVnd(maxDiscount!)}' : '';
      return 'Giảm ${discountValue!.round()}%$cap';
    }
    return 'Giảm ${formatVnd(discountValue!)}';
  }

  // Gia tri quy ra tien cua mot voucher, dung cho tong gia tri trong vi (ma giam % tinh theo muc giam toi da)
  double get walletValue {
    if (!isDiscount) return faceValue;
    return (discountType == 'PERCENT' ? maxDiscount : discountValue) ?? 0;
  }

  // Ton kho kha dung = tong - da ban - dang giu cho (FR-CAMP-11)
  // Phan tram tiet kiem hien tren the voucher: giam theo % thi lay discountValue, con lai so gia ban voi gia tri
  int? get savingPercent {
    if (isDiscount) return discountType == 'PERCENT' ? discountValue?.round() : null;
    if (faceValue <= 0 || salePrice >= faceValue) return null;
    return ((faceValue - salePrice) / faceValue * 100).round();
  }

  int get availableQuantity =>
      (totalQuantity - soldQuantity - reservedQuantity).clamp(0, totalQuantity);

  // BR-01: moi lan mua khong qua gioi han moi tai khoan (mac dinh 5) va ton kho con lai
  int get maxPerOrder {
    final limit = limitPerUser ?? 5;
    return availableQuantity < limit ? availableQuantity : limit;
  }

  bool isOnSaleAt(DateTime now) =>
      availableQuantity > 0 && status == 'PUBLISHED' && !now.isBefore(saleStartAt) && now.isBefore(saleEndAt);

  // Ly do khong mua duoc, hien dung tinh huong thay vi gop chung "het hang / ngung ban"
  String unavailableLabelAt(DateTime now) {
    if (status == 'SOLD_OUT' || availableQuantity == 0) return 'Hết hàng';
    if (status == 'PUBLISHED' && now.isBefore(saleStartAt)) return 'Chưa mở bán';
    return 'Ngừng bán';
  }

  factory VoucherCampaign.fromJson(Map<String, dynamic> json) =>
      VoucherCampaign(
        id: json['id'] as String,
        brandId: json['brandId'] as String? ?? '',
        brandName: json['brand'] is Map
            ? (json['brand'] as Map)['name'] as String?
            : null,
        title: json['title'] as String? ?? '',
        image: json['image'] as String?,
        description: json['description'] as String?,
        terms: json['terms'] as String?,
        voucherType: json['voucherType'] == 'DISCOUNT' ? 'DISCOUNT' : 'PREPAID',
        salePrice: asDouble(json['salePrice']),
        faceValue: asDouble(json['faceValue']),
        discountType: json['discountType'] as String?,
        discountValue: asDoubleOrNull(json['discountValue']),
        maxDiscount: asDoubleOrNull(json['maxDiscount']),
        totalQuantity: asInt(json['totalQuantity']),
        soldQuantity: asInt(json['soldQuantity']),
        reservedQuantity: asInt(json['reservedQuantity']),
        limitPerUser: json['limitPerUser'] == null
            ? null
            : asInt(json['limitPerUser']),
        saleStartAt: asDate(json['saleStartAt']),
        saleEndAt: asDate(json['saleEndAt']),
        voucherExpireAt: asDate(json['voucherExpireAt']),
        status: json['status'] as String? ?? 'PUBLISHED',
        stores: asList(json['stores'], Store.fromJson),
        distanceKm: asDoubleOrNull(json['distanceKm']),
        refundDescription:
            (json['refundPolicy'] as Map?)?['description'] as String?,
        averageRating: asDouble(json['averageRating']),
        reviewCount: asInt(json['reviewCount']),
        reviews: (json['reviews'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}

// Ket qua phan trang cua GET /vouchers
class SearchResult {
  const SearchResult({required this.items, required this.total});

  final List<VoucherCampaign> items;
  final int total;

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    items: asList(json['items'], VoucherCampaign.fromJson),
    total: asInt(json['total']),
  );
}
