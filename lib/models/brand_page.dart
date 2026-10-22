import 'campaign.dart';
import 'json_utils.dart';

// F06 / FR-BRAND-07: trang thuong hieu cong khai (GET /brands/:id/public)
class BrandPage {
  const BrandPage({
    required this.id,
    required this.name,
    this.logo,
    this.description,
    this.contactInfo,
    this.stores = const [],
    this.campaigns = const [],
    this.reviewCount = 0,
    this.averageRating,
    this.followerCount = 0,
  });

  final String id;
  final String name;
  final String? logo;
  final String? description;
  final String? contactInfo;
  final List<Store> stores;
  final List<VoucherCampaign> campaigns;
  final int reviewCount;
  final double? averageRating;
  final int followerCount;

  BrandPage withFollowers(int count) => BrandPage(
        id: id,
        name: name,
        logo: logo,
        description: description,
        contactInfo: contactInfo,
        stores: stores,
        campaigns: campaigns,
        reviewCount: reviewCount,
        averageRating: averageRating,
        followerCount: count,
      );

  factory BrandPage.fromJson(Map<String, dynamic> json) => BrandPage(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        logo: json['logo'] as String?,
        description: json['description'] as String?,
        contactInfo: json['contactInfo'] as String?,
        stores: asList(json['stores'], Store.fromJson),
        campaigns: asList(json['campaigns'], VoucherCampaign.fromJson),
        reviewCount: asInt(json['reviewCount']),
        averageRating: json['averageRating'] == null ? null : asDouble(json['averageRating']),
        followerCount: asInt(json['followerCount']),
      );
}
