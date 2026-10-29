import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:voucher_platform_mobile/providers/auth_provider.dart';
import 'package:voucher_platform_mobile/providers/favorite_provider.dart';
import 'package:voucher_platform_mobile/screens/brand/brand_screen.dart';
import 'package:voucher_platform_mobile/screens/engage/favorites_screen.dart';
import 'package:voucher_platform_mobile/screens/profile/profile_edit_screen.dart';
import 'package:voucher_platform_mobile/screens/profile/profile_screen.dart';
import 'package:voucher_platform_mobile/services/auth_service.dart';
import 'package:voucher_platform_mobile/services/profile_service.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';

import '../helpers/fake_api.dart';

// F06 trang thuong hieu + theo doi, F17 sua ho so, yeu thich hien ten that (Module 7, 11)
const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

Map<String, dynamic> _brand({int followers = 3}) => {
      'id': 'b1',
      'name': 'Highlands Coffee',
      'description': 'Cà phê Việt',
      'stores': [
        {'id': 's1', 'brandId': 'b1', 'name': 'Highlands Lê Lợi', 'address': '135 Lê Lợi', 'latitude': 10.77, 'longitude': 106.7},
      ],
      'campaigns': [
        {
          'id': 'c1', 'brandId': 'b1', 'title': 'Voucher 100K', 'voucherType': 'PREPAID', 'salePrice': 80000, 'faceValue': 100000,
          'totalQuantity': 10, 'soldQuantity': 1, 'reservedQuantity': 0, 'status': 'PUBLISHED',
          'saleStartAt': '2026-10-01T00:00:00.000Z', 'saleEndAt': '2099-01-01T00:00:00.000Z', 'voucherExpireAt': '2099-02-01T00:00:00.000Z',
        },
      ],
      'reviewCount': 2,
      'averageRating': 4.5,
      'followerCount': followers,
    };

Future<FakeApi> _pump(WidgetTester tester, Widget screen, Map<String, FakeResponse Function(dynamic)> routes) async {
  final api = FakeApi(routes.map((k, v) => MapEntry(k, (req) => v(req))));
  final client = api.client();
  final auth = AuthProvider(api: client, authService: AuthService(client), storage: LoggedInTokenStorage());
  await auth.hydrate();
  // F06: yeu thich / theo doi dung chung mot FavoriteProvider nhu trong main.dart
  final engage = EngageService(client);
  final favorites = FavoriteProvider(engage);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      Provider.value(value: SearchService(client)),
      Provider.value(value: engage),
      ChangeNotifierProvider.value(value: favorites),
      Provider.value(value: ProfileService(client)),
    ],
    child: MaterialApp(home: screen),
  ));
  await tester.pumpAndSettle();
  return api;
}

void main() {
  group('F06 trang thuong hieu', () {
    testWidgets('hien thong tin, diem danh gia, chien dich, chi nhanh; bam Theo doi goi API', (tester) async {
      var following = false;
      final api = await _pump(tester, const BrandScreen(brandId: 'b1'), {
        'GET /brands/b1/public': (_) => FakeResponse.ok(_brand()),
        'GET /favorites/me': (_) => FakeResponse.ok(following ? [{'id': 'f1', 'targetType': 'BRAND', 'targetId': 'b1'}] : []),
        'POST /favorites': (_) {
          following = !following;
          return FakeResponse.ok({'favorited': following});
        },
      });

      expect(find.text('Highlands Coffee'), findsOneWidget);
      expect(find.textContaining('★ 4.5 (2 đánh giá)'), findsOneWidget);
      expect(find.textContaining('3 người theo dõi'), findsOneWidget);
      expect(find.text('Voucher 100K'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Highlands Lê Lợi'), 300);
      expect(find.text('Highlands Lê Lợi'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Theo dõi'), -300);

      await tester.tap(find.text('Theo dõi'));
      await tester.pumpAndSettle();
      expect(find.text('Đang theo dõi'), findsOneWidget);
      expect(find.textContaining('4 người theo dõi'), findsOneWidget);
      final body = jsonDecode(api.calls('POST', '/favorites').single.body) as Map;
      expect(body, {'targetType': 'BRAND', 'targetId': 'b1'});
    });
  });

  // Man "Yeu thich" tach lam 2 tab: theo doi thuong hieu va yeu thich voucher (FR-ENGAGE-01)
  testWidgets('Yeu thich hien ten that, tach tab thuong hieu va voucher', (tester) async {
    await _pump(tester, const FavoritesScreen(), {
      'GET /favorites/me': (_) => const FakeResponse.ok([
            {'id': 'f1', 'targetType': 'BRAND', 'targetId': 'b1', 'title': 'Highlands Coffee'},
            {'id': 'f2', 'targetType': 'CAMPAIGN', 'targetId': 'c1', 'title': 'Voucher 100K', 'brandName': 'Highlands Coffee', 'salePrice': 80000},
          ]),
    });

    // Tab dau: thuong hieu dang theo doi
    expect(find.text('Thương hiệu (1)'), findsOneWidget);
    expect(find.text('Voucher (1)'), findsOneWidget);
    expect(find.text('Highlands Coffee'), findsOneWidget);
    expect(find.text('Thương hiệu đang theo dõi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tab-campaigns')));
    await tester.pumpAndSettle();
    expect(find.text('Voucher 100K'), findsOneWidget);
    expect(find.textContaining('Highlands Coffee · 80.000'), findsOneWidget);
    // Ma noi bo khong duoc lo ra giao dien
    expect(find.textContaining('c1'), findsNothing);
  });

  testWidgets('Bo theo doi ngay tren danh sach, co hoan tac (FR-ENGAGE-01)', (tester) async {
    var favorites = [
      {'id': 'f1', 'targetType': 'BRAND', 'targetId': 'b1', 'title': 'Highlands Coffee'},
    ];
    final api = await _pump(tester, const FavoritesScreen(), {
      'GET /favorites/me': (_) => FakeResponse.ok(favorites),
      'POST /favorites': (_) {
        favorites = const [];
        return const FakeResponse.ok({'favorited': false});
      },
    });

    expect(find.text('Highlands Coffee'), findsOneWidget);
    await tester.tap(find.byKey(const Key('remove-f1')));
    await tester.pumpAndSettle();

    expect(find.text('Highlands Coffee'), findsNothing);
    expect(find.text('Thương hiệu (0)'), findsOneWidget);
    expect(find.textContaining('Đã bỏ theo dõi'), findsOneWidget);
    expect(find.text('Hoàn tác'), findsOneWidget);
    final body = jsonDecode(api.calls('POST', '/favorites').single.body) as Map;
    expect(body, {'targetType': 'BRAND', 'targetId': 'b1'});
  });

  testWidgets('Chua theo doi thuong hieu nao thi noi ro lam gi tiep theo', (tester) async {
    await _pump(tester, const FavoritesScreen(), {
      'GET /favorites/me': (_) => const FakeResponse.ok([]),
    });

    expect(find.text('Chưa theo dõi thương hiệu nào'), findsOneWidget);
    expect(find.textContaining('nhận thông báo khi có ưu đãi mới'), findsOneWidget);
  });

  group('F17 ho so: lam tuoi tu may chu', _profileRefreshTests);

  group('F17 sua ho so', () {
    test('validator ho ten, so dien thoai, anh dai dien', () {
      expect(validateFullName(' '), 'Vui lòng nhập họ tên');
      expect(validateFullName('A'), 'Họ tên tối thiểu 2 ký tự');
      expect(validateFullName('Nguyễn Văn A'), isNull);
      expect(validatePhone(''), isNull);
      expect(validatePhone('12345'), isNotNull);
      expect(validatePhone('0901234567'), isNull);
      expect(validatePhone('+84901234567'), isNull);
      final png = Uint8List.fromList(base64Decode(_png));
      expect(validateAvatar(Uint8List.fromList(utf8.encode('GIF89a......'))), 'Ảnh đại diện chỉ nhận JPG hoặc PNG');
      expect(validateAvatar(Uint8List(maxAvatarBytes + 10)..setAll(0, png)), 'Ảnh đại diện tối đa 2 MB');
      expect(validateAvatar(png), isNull);
      expect(imageMime(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0])), 'image/jpeg');
    });

    testWidgets('form bao loi, chon anh va luu gui dung du lieu', (tester) async {
      Map<String, dynamic>? sent;
      final api = await _pump(
        tester,
        ProfileEditScreen(picker: () async => XFile.fromData(Uint8List.fromList(base64Decode(_png)), name: 'avatar.png')),
        {
          'PATCH /users/me': (req) {
            sent = jsonDecode(req.body) as Map<String, dynamic>;
            return FakeResponse.ok({'id': 'u1', 'email': 'khach@voucher.local', 'role': 'CUSTOMER', ...sent!});
          },
        },
      );

      await tester.enterText(find.byKey(const Key('full-name')), '');
      await tester.enterText(find.byKey(const Key('phone')), '123');
      await tester.ensureVisible(find.byKey(const Key('save-profile')));
      await tester.tap(find.byKey(const Key('save-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
      expect(find.text('Số điện thoại gồm 10 số, bắt đầu bằng 0 hoặc +84'), findsOneWidget);
      expect(api.calls('PATCH', '/users/me'), isEmpty);

      await tester.enterText(find.byKey(const Key('full-name')), 'Nguyễn Văn A');
      await tester.enterText(find.byKey(const Key('phone')), '0901234567');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('pick-avatar')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('Ảnh JPG hoặc PNG, tối đa 2 MB'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('save-profile')));
      await tester.tap(find.byKey(const Key('save-profile')));
      await tester.pumpAndSettle();

      expect(sent!['fullName'], 'Nguyễn Văn A');
      expect(sent!['phone'], '0901234567');
      expect(sent!['avatar'], 'data:image/png;base64,$_png');
    });
  });
}

// F17 / FR-AUTH-05: man "Ca nhan" truoc day chi doc ho so tu phien da luu tren may, nen sua ho so o
// thiet bi khac thi may nay van hien du lieu cu. Nay doc lai GET /users/me moi lan mo man.
void _profileRefreshTests() {
  testWidgets('mo man Ca nhan thi doc lai ho so tu may chu va hien du lieu moi', (tester) async {
    final api = await _pump(tester, const ProfileScreen(), {
      'GET /users/me': (_) => const FakeResponse.ok({
            'id': 'u1',
            'email': 'khach@voucher.local',
            'role': 'CUSTOMER',
            'fullName': 'Nguyễn Văn A',
            'phone': '0901234567',
          }),
    });

    expect(api.calls('GET', '/users/me'), hasLength(1));
    // Ten trong phien da luu la "Khach"; sau khi doc lai phai hien ten moi
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('0901234567'), findsOneWidget);
    expect(find.text('Khách'), findsNothing);
  });

  testWidgets('may chu loi thi van hien ho so da luu, khong lam trong man hinh', (tester) async {
    await _pump(tester, const ProfileScreen(), {
      'GET /users/me': (_) => const FakeResponse.error(500, 'Lỗi máy chủ'),
    });

    expect(find.text('Khách'), findsOneWidget);
    // Van o nhanh "da dang nhap": menu ca nhan hien binh thuong
    expect(find.text('Yêu thích'), findsOneWidget);
  });
}
