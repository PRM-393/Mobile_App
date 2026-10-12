import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_mobile/widgets/countdown_timer.dart';

// Widget test (Module 11): dong ho QR dem nguoc va goi lam moi ma khi het han (FR-REDEEM-02)
void main() {
  testWidgets('dem nguoc ve 0 thi hien "Da het han" va goi onExpire', (tester) async {
    var now = DateTime(2026, 10, 12, 9, 0, 0);
    var expired = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CountdownTimer(
          expiresAt: DateTime(2026, 10, 12, 9, 0, 3),
          now: () => now,
          onExpire: () => expired++,
        ),
      ),
    ));
    expect(find.text('Còn hiệu lực 3s'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Còn hiệu lực 2s'), findsOneWidget);

    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Đã hết hạn'), findsOneWidget);
    expect(expired, 1);
  });
}
