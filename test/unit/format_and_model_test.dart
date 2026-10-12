import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_mobile/models/campaign.dart';
import 'package:voucher_platform_mobile/models/order.dart';
import 'package:voucher_platform_mobile/utils/distance.dart';
import 'package:voucher_platform_mobile/utils/format.dart';

// Unit test cho logic thuan Dart (Module 11): dinh dang, khoang cach, parse model
void main() {
  group('formatVnd', () {
    test('dinh dang VND co dau phan cach hang nghin, khong co phan thap phan', () {
      expect(formatVnd(50000), contains('50.000'));
      expect(formatVnd(50000), contains('₫'));
      expect(formatVnd(1234567.6), contains('1.234.568'));
    });
  });

  group('formatDateTime', () {
    test('chuyen UTC sang gio Viet Nam (UTC+7)', () {
      expect(formatDateTime(DateTime.utc(2026, 10, 12, 17, 30)), '13/10/2026 00:30');
    });
  });

  group('distance', () {
    test('Haversine: Ho Guom -> Nha tho Lon Ha Noi khoang 0.4 km', () {
      final km = distanceKm(21.0288, 105.8522, 21.0287, 105.8489);
      expect(km, closeTo(0.34, 0.05));
    });

    test('formatDistance doi sang met khi duoi 1 km', () {
      expect(formatDistance(0.45), '450 m');
      expect(formatDistance(3.26), '3.3 km');
    });
  });

  group('VoucherCampaign.fromJson', () {
    test('nhan so dang chuoi tu TypeORM va tinh ton kho kha dung', () {
      final c = VoucherCampaign.fromJson({
        'id': 'c1',
        'brandId': 'b1',
        'title': 'Giam 50k',
        'voucherType': 'PREPAID_VALUE',
        'salePrice': '80000',
        'faceValue': '100000',
        'discountPercent': '20.00',
        'totalQuantity': 10,
        'soldQuantity': 6,
        'reservedQuantity': 3,
        'saleStartAt': '2026-10-01T00:00:00.000Z',
        'saleEndAt': '2026-10-31T00:00:00.000Z',
        'voucherExpireAt': '2026-11-30T00:00:00.000Z',
        'status': 'PUBLISHED',
      });
      expect(c.salePrice, 80000);
      expect(c.discountPercent, 20);
      expect(c.availableQuantity, 1);
    });
  });

  group('VoucherItem.effectiveStatus', () {
    VoucherItem item(String status, DateTime expireAt) => VoucherItem.fromJson({
          'id': 'v1',
          'orderId': 'o1',
          'campaignId': 'c1',
          'code': 'ABC123',
          'status': status,
          'issuedAt': '2026-10-01T00:00:00.000Z',
          'expireAt': expireAt.toIso8601String(),
        });

    test('ACTIVE nhung qua han thi hien la EXPIRED, khong cho tac vu nen', () {
      expect(item('ACTIVE', DateTime.now().subtract(const Duration(days: 1))).effectiveStatus, 'EXPIRED');
      expect(item('ACTIVE', DateTime.now().add(const Duration(days: 1))).effectiveStatus, 'ACTIVE');
      expect(item('USED', DateTime.now().subtract(const Duration(days: 1))).effectiveStatus, 'USED');
    });
  });
}
