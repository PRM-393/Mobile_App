import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voucher_platform_mobile/models/auth_user.dart';
import 'package:voucher_platform_mobile/providers/auth_provider.dart';
import 'package:voucher_platform_mobile/routes.dart';
import 'package:voucher_platform_mobile/screens/auth/login_screen.dart';
import 'package:voucher_platform_mobile/services/auth_service.dart';
import 'package:voucher_platform_mobile/services/token_storage.dart';

import '../helpers/fake_api.dart';

// Widget test (Module 11): nhap email -> da dang ky thi nhap mat khau, chua dang ky thi tao mat khau; quen mat khau
class _MemoryStorage extends TokenStorage {
  LoginResponse? saved;

  @override
  Future<LoginResponse?> read() async => saved;

  @override
  Future<void> save(LoginResponse session) async => saved = session;

  @override
  Future<void> clear() async => saved = null;
}

Map<String, dynamic> _session(String role) => {
  'accessToken': 'a',
  'refreshToken': 'r',
  'user': {'id': 'u1', 'email': 'ban@vidu.com', 'role': role},
};

Map<String, dynamic> _body(dynamic req) => jsonDecode(req.body as String) as Map<String, dynamic>;

void main() {
  late FakeApi api;
  late AuthProvider auth;

  Future<void> pump(WidgetTester tester, Map<String, FakeResponse Function(dynamic)> routes) async {
    api = FakeApi(routes.map((k, v) => MapEntry(k, (req) => v(req))));
    final client = api.client();
    auth = AuthProvider(api: client, authService: AuthService(client), storage: _MemoryStorage());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.login), child: const Text('mo')),
            ),
          ),
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.tap(find.text('mo'));
    await tester.pumpAndSettle();
  }

  Future<void> enterEmail(WidgetTester tester, String email) async {
    await tester.enterText(find.byKey(const Key('emailField')), email);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
  }

  testWidgets('bo trong email thi bao loi bat buoc nhap', (tester) async {
    await pump(tester, {});
    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('email sai dinh dang thi bao khong hop le', (tester) async {
    await pump(tester, {});
    await enterEmail(tester, 'abc@');
    expect(find.text('Email không hợp lệ'), findsOneWidget);
  });

  testWidgets('email da dang ky: nhap mat khau roi dang nhap, khong gui OTP', (tester) async {
    await pump(tester, {
      'POST /auth/check-email': (_) => const FakeResponse.ok({'registered': true}),
      'POST /auth/login': (_) => FakeResponse.ok(_session('CUSTOMER')),
    });
    await enterEmail(tester, 'ban@vidu.com');
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('confirmPasswordField')), findsNothing);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('passwordField')), '12');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();
    expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('passwordField')), 'matkhau1');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(_body(api.calls('POST', '/auth/login').single), {'email': 'ban@vidu.com', 'password': 'matkhau1'});
    expect(auth.isLoggedIn, isTrue);
    expect(find.text('mo'), findsOneWidget); // quay ve man hinh truoc
  });

  testWidgets('email chua dang ky: tao mat khau + xac nhan la dang ky xong', (tester) async {
    await pump(tester, {
      'POST /auth/check-email': (_) => const FakeResponse.ok({'registered': false}),
      'POST /auth/register': (_) => FakeResponse.ok(_session('CUSTOMER')),
    });
    await enterEmail(tester, 'ban@vidu.com');
    expect(find.text('Tạo tài khoản'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('passwordField')), 'matkhau1');
    await tester.enterText(find.byKey(const Key('confirmPasswordField')), 'matkhau2');
    await tester.tap(find.text('Đăng ký'));
    await tester.pump();
    expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
    expect(api.calls('POST', '/auth/register'), isEmpty);

    await tester.enterText(find.byKey(const Key('confirmPasswordField')), 'matkhau1');
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(_body(api.calls('POST', '/auth/register').single), {'email': 'ban@vidu.com', 'password': 'matkhau1'});
    expect(auth.isLoggedIn, isTrue);
  });

  testWidgets('tai khoan web (nhan vien) bi tu choi tren app', (tester) async {
    await pump(tester, {
      'POST /auth/check-email': (_) => const FakeResponse.ok({'registered': true}),
      'POST /auth/login': (_) => FakeResponse.ok(_session('STORE_STAFF')),
    });
    await enterEmail(tester, 'ban@vidu.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'matkhau1');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(auth.isLoggedIn, isFalse);
    expect(find.textContaining('chỉ dành cho khách hàng'), findsOneWidget);
  });

  testWidgets('doi email quay lai buoc nhap email', (tester) async {
    await pump(tester, {'POST /auth/check-email': (_) => const FakeResponse.ok({'registered': true})});
    await enterEmail(tester, 'ban@vidu.com');
    await tester.tap(find.byKey(const Key('changeEmail')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('passwordField')), findsNothing);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('quen mat khau: gui ma, nhap ma + mat khau moi + xac nhan', (tester) async {
    await pump(tester, {
      'POST /auth/check-email': (_) => const FakeResponse.ok({'registered': true}),
      'POST /auth/password-reset/code-request': (_) => const FakeResponse.ok({'message': 'ok'}),
      'POST /auth/password-reset/code-confirm': (_) => const FakeResponse.ok({'message': 'ok'}),
    });
    await enterEmail(tester, 'ban@vidu.com');
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi mã xác thực'));
    await tester.pumpAndSettle();
    expect(_body(api.calls('POST', '/auth/password-reset/code-request').single), {'email': 'ban@vidu.com'});

    await tester.enterText(find.byKey(const Key('resetCodeField')), '123456');
    await tester.enterText(find.byKey(const Key('newPasswordField')), 'matkhau-moi');
    await tester.enterText(find.byKey(const Key('confirmNewPasswordField')), 'matkhau-moi');
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pump(const Duration(seconds: 1));
    expect(_body(api.calls('POST', '/auth/password-reset/code-confirm').single),
        {'email': 'ban@vidu.com', 'code': '123456', 'password': 'matkhau-moi'});
    await tester.pump(const Duration(minutes: 2)); // dung dong ho dem gui lai
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('passwordField')), findsOneWidget); // ve lai man dang nhap
  });

  test('validateEmail / validatePassword', () {
    expect(validateEmail('ban@vidu.com'), isNull);
    expect(validatePassword('123456'), isNull);
    expect(validatePassword(''), 'Vui lòng nhập mật khẩu');
  });
}
