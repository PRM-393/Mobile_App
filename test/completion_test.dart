import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:voucher_platform_mobile/providers/search_provider.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';
import 'package:voucher_platform_mobile/services/voucher_services.dart';
import 'package:voucher_platform_mobile/screens/home/home_screen.dart';
import 'package:voucher_platform_mobile/screens/search/search_screen.dart';
import 'package:voucher_platform_mobile/models/campaign.dart';
import 'package:voucher_platform_mobile/screens/search/store_map_screen.dart';

Map<String, dynamic> campaign(String id) => {
  'id': id,
  'title': 'Voucher $id',
  'voucherType': 'PREPAID',
  'faceValue': 100000,
  'salePrice': 80000,
  'totalQuantity': 100,
  'soldQuantity': 10,
  'reservedQuantity': 2,
  'status': 'PUBLISHED',
  'saleStartAt': '2026-01-01T00:00:00Z',
  'saleEndAt': '2027-01-01T00:00:00Z',
  'voucherExpireAt': '2027-02-01T00:00:00Z',
};
http.Response json(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  test('F03 filters, page size 20, append and deduplicate', () async {
    final requests = <http.Request>[];
    final api = ApiClient(
      baseUrl: 'http://test/api',
      httpClient: MockClient((r) async {
        requests.add(r);
        final page = int.parse(r.url.queryParameters['page']!);
        return json({
          'items': List.generate(20, (i) => campaign('${(page - 1) * 20 + i}')),
          'total': 40,
        });
      }),
    );
    final provider = SearchProvider(SearchService(api));
    provider.minPrice = 100;
    provider.maxPrice = 100000;
    provider.minDiscount = 10;
    provider.maxDiscount = 50;
    provider.sort = 'price_asc';
    await provider.search();
    await provider.loadMore();
    expect(provider.results.length, 40);
    expect(provider.hasMore, false);
    expect(requests.first.url.queryParameters, containsPair('pageSize', '20'));
    expect(
      requests.first.url.queryParameters,
      containsPair('minDiscount', '10.0'),
    );
    expect(requests.last.url.queryParameters, containsPair('page', '2'));
  });
  test('F04 denied permission falls back without radius or crash', () async {
    late Uri uri;
    final api = ApiClient(
      baseUrl: 'http://test/api',
      httpClient: MockClient((r) async {
        uri = r.url;
        return json({'items': [], 'total': 0});
      }),
    );
    final provider = SearchProvider(
      SearchService(api),
      locate: () async => null,
    );
    await provider.setRadius(3);
    expect(provider.locationDenied, true);
    expect(provider.radiusKm, null);
    expect(uri.queryParameters['locationDenied'], 'true');
    expect(uri.queryParameters.containsKey('lat'), false);
  });
  test('F03 late search response cannot overwrite latest query', () async {
    final first = Completer<http.Response>();
    final api = ApiClient(
      baseUrl: 'http://test/api',
      httpClient: MockClient((r) async {
        if (r.url.queryParameters['keyword'] == 'old') return first.future;
        return json({
          'items': [campaign('new')],
          'total': 1,
        });
      }),
    );
    final provider = SearchProvider(SearchService(api));
    final pending = provider.setKeyword('old');
    await Future<void>.delayed(Duration.zero);
    await provider.setKeyword('new');
    first.complete(
      json({
        'items': [campaign('old')],
        'total': 1,
      }),
    );
    await pending;
    expect(provider.results.single.id, 'new');
  });
  test('F05 reads reviews, dynamic policy and distance', () {
    final c = VoucherCampaign.fromJson({
      ...campaign('x'),
      'distanceKm': 1.2,
      'reviewCount': 2,
      'averageRating': 4.5,
      'reviews': [
        {'rating': 5, 'comment': 'Tốt'},
      ],
      'refundPolicy': {'description': 'Chính sách từ máy chủ'},
    });
    expect(c.distanceKm, 1.2);
    expect(c.reviewCount, 2);
    expect(c.refundDescription, 'Chính sách từ máy chủ');
    expect(c.reviews.single['rating'], 5);
  });
  for (final width in [320.0, 375.0, 768.0]) {
    testWidgets('F03 Home and Search no overflow at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final requests = <Uri>[];
      final api = ApiClient(
        baseUrl: 'http://test/api',
        httpClient: MockClient((r) async {
          requests.add(r.url);
          return json(
            r.url.path.endsWith('/categories')
                ? [
                    {'id': 'c', 'name': 'Ăn uống'},
                  ]
                : {
                    'items': [campaign('1')],
                    'total': 1,
                  },
          );
        }),
      );
      final service = SearchService(api);
      final provider = SearchProvider(service);
      Widget app(Widget child) => MultiProvider(
        providers: [
          Provider.value(value: service),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(home: child),
      );
      await tester.pumpWidget(app(const HomeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bán chạy'));
      await tester.pumpAndSettle();
      expect(
        requests.any((u) => u.queryParameters['sort'] == 'best_seller'),
        true,
      );
      expect(tester.takeException(), null);
      await tester.pumpWidget(app(const SearchScreen()));
      await tester.pumpAndSettle();
      expect(find.text('1 kết quả'), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.tap(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('Lọc và sắp xếp'), findsOneWidget);
      expect(tester.takeException(), null);
    });
  }
  testWidgets('F04 empty map has clear fallback without loading tiles', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'http://test/api',
      httpClient: MockClient((_) async => json({})),
    );
    await tester.pumpWidget(
      Provider.value(
        value: SearchService(api),
        child: const MaterialApp(home: StoreMapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Không có chi nhánh phù hợp'), findsOneWidget);
  });
}
