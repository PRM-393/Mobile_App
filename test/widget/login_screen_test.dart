import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voucher_platform_mobile/providers/auth_provider.dart';
import 'package:voucher_platform_mobile/screens/auth/login_screen.dart';
import 'package:voucher_platform_mobile/services/api_client.dart';
import 'package:voucher_platform_mobile/services/auth_service.dart';
import 'package:voucher_platform_mobile/services/token_storage.dart';

// Widget test (Module 11): form dang nhap kiem tra email truoc khi goi API
void main() {
  Widget buildApp() {
    final api = ApiClient(baseUrl: 'http://localhost:0/api');
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(api: api, authService: AuthService(api), storage: TokenStorage()),
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('bo trong email thi bao loi bat buoc nhap', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Gửi mã OTP'));
    await tester.pump();
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
  });

  testWidgets('email sai dinh dang thi bao khong hop le', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byKey(const Key('emailField')), 'abc@');
    await tester.tap(find.text('Gửi mã OTP'));
    await tester.pump();
    expect(find.text('Email không hợp lệ'), findsOneWidget);
  });

  test('validateEmail chap nhan email hop le', () {
    expect(validateEmail('ban@vidu.com'), isNull);
  });
}
