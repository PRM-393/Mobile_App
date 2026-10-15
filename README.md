# Mobile_App – Ứng dụng khách hàng (Flutter)

Ứng dụng di động cho **Khách hàng** của Nền tảng bán và sử dụng voucher đa thương hiệu (môn PRM393).
Viết bằng **Flutter (Dart)** theo học liệu môn học. Tài liệu đặc tả: `Document/SRS-Voucher-Platform.docx` (v1.1).

| Thành phần | Công nghệ |
|---|---|
| Ngôn ngữ / framework | Dart 3, Flutter 3 (Material 3) |
| Quản lý trạng thái | `provider` (ChangeNotifier, MultiProvider) |
| Điều hướng | Named routes + `onGenerateRoute` (Navigator 1.0), chặn màn cần đăng nhập |
| Gọi API | `http` qua một `ApiClient` dùng chung, tự làm mới token khi 401 |
| Lưu phiên | `flutter_secure_storage` (Keystore / Keychain) |
| Dữ liệu nhỏ trên máy | `shared_preferences` (từ khóa tìm kiếm gần đây, ảnh chụp trạng thái ví) – Module 9 |
| Vị trí | `geolocator` (tìm voucher gần đây, FR-SEARCH) |
| QR | `qr_flutter` (hiện mã QR động 60 giây) |
| Thông báo | `flutter_local_notifications`: bắn sau tạo đơn, voucher về ví, đã dùng, hoàn tiền (LO7) |
| Định dạng | `intl` (tiền VND, giờ UTC+7) |

## Chạy dự án

Yêu cầu: Flutter SDK 3.47.x, Android Studio (emulator) hoặc điện thoại Android. **Không cần chạy BE hay cài CSDL**:
app mặc định gọi BE đã deploy trên Render (`lib/config/env.dart`).

```bash
flutter pub get
flutter run
```

- Lần gọi đầu có thể mất 30–60 giây vì Render gói free đang "ngủ".
- Khách hàng đăng nhập bằng email + OTP. Tài khoản mẫu: `khach@voucher.local` (đã có 1 voucher còn hiệu lực).
- Chạy với BE trên máy mình: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api` (10.0.2.2 là máy host khi dùng
  emulator; điện thoại thật dùng IP LAN, ví dụ `http://192.168.1.10:3000/api`).
- Không hard-code địa chỉ máy chủ trong mã nguồn (NFR-MNT-02); đổi BE production thì sửa `Env.defaultBackend`.

Kiểm tra trước khi tạo PR:

```bash
flutter analyze
flutter test
```

## Xuất APK (Release)

- **Tự động trên GitHub Actions:** mỗi lần push lên `main`, workflow `CI` chạy test rồi build Release APK. Tải ở tab
  **Actions** → lần chạy mới nhất → mục **Artifacts** → `voucher-platform-apk`. Có thể bấm **Run workflow** để build lại.
- **Bản nộp / demo:** tạo tag dạng `v1.0.0` rồi push (`git tag v1.0.0 && git push origin v1.0.0`). Workflow tạo
  **GitHub Release** kèm file APK để tải về cài trên máy thật.
- **Build trên máy:** `flutter build apk --release`, file ra ở `build/app/outputs/flutter-apk/app-release.apk`.
- APK đang ký bằng khóa debug của Flutter, đủ để cài thử và nộp đồ án. Muốn đưa lên Google Play thì phải tạo keystore riêng.

## Cấu trúc thư mục

```
lib/
  main.dart              # khởi tạo service, khôi phục phiên, đăng ký MultiProvider
  routes.dart            # AppRoutes: tên route, onGenerateRoute, chặn route cần đăng nhập
  config/env.dart        # API_BASE_URL đọc từ --dart-define
  theme/app_theme.dart   # màu, khoảng cách, ThemeData dùng chung
  models/                # lớp dữ liệu + fromJson (campaign, order, engage, auth_user)
  services/              # ApiClient, TokenStorage, AuthService, các service nghiệp vụ, NotificationService
  providers/             # AuthProvider, SearchProvider, WalletProvider, MainTabController
  screens/               # mỗi nhóm tính năng một thư mục
  widgets/               # widget tái sử dụng (VoucherCard, CountdownTimer, ...)
  utils/                 # định dạng tiền / ngày giờ, tính khoảng cách
test/
  unit/                  # test hàm thuần và model
  widget/                # test widget (form đăng nhập, đếm ngược QR)
```

Quy ước bắt buộc:

1. **Widget không gọi `http` trực tiếp.** Luồng luôn là `Screen → Provider/Service → ApiClient`.
2. Trạng thái dùng chung giữa nhiều màn (đăng nhập, ví, tìm kiếm) đặt trong Provider; trạng thái cục bộ của một form dùng `StatefulWidget`.
3. Thêm màn mới: tạo trong `screens/<nhóm>/`, khai báo tên ở `AppRoutes`, thêm vào `protected` nếu cần đăng nhập. Mở màn bằng `AppRoutes.push(context, AppRoutes.xxx, arguments: ...)`.
4. Model đọc số bằng `asInt` / `asDouble` trong `models/json_utils.dart` vì PostgreSQL trả cột numeric dạng chuỗi.
5. Tiền hiển thị bằng `formatVnd`, thời gian bằng `formatDateTime` (UTC+7). Thông báo lỗi tiếng Việt, lấy từ `ApiException.message`.
6. Hiệu năng (Module 12): danh sách dùng `ListView.builder` / `GridView.builder`; màn đọc provider bằng `Selector` thay vì `context.watch` cả provider; mỗi dòng có `ValueKey(id)`; ảnh mạng đặt `cacheWidth`. Mẫu: `screens/wallet/wallet_screen.dart`.
7. Comment ghi mã yêu cầu SRS (ví dụ `FR-REDEEM-02`) để truy vết.

## Màn hình và yêu cầu

| Màn hình | Route | Yêu cầu SRS |
|---|---|---|
| Khung chính (Khám phá, Tìm kiếm, Ví, Tài khoản) | `/` | FR-SEARCH-01..06, FR-ORDER-06 |
| Đăng nhập email → OTP | `/login`, `/otp` | FR-AUTH-01..03, BR-23 |
| Chi tiết chiến dịch | `/voucher` | FR-SEARCH-04 |
| Thanh toán | `/checkout` | FR-ORDER-01..05, BR-01 |
| Mã QR + OTP sử dụng voucher | `/redeem` | FR-REDEEM-01..04 |
| Yêu cầu hoàn tiền / danh sách | `/refund`, `/refunds` | FR-REFUND-* |
| Đánh giá | `/review` | FR-ENGAGE-02..05 |
| Thông báo, Yêu thích | `/notifications`, `/favorites` | FR-ENGAGE-* |

Các màn trong `protected` sẽ chuyển sang màn đăng nhập nếu người dùng là Khách (Guest).

## API máy chủ đang dùng

`/auth/*`, `/categories`, `/vouchers`, `/vouchers/:id`, `/orders`, `/orders/me`, `/wallet`,
`/redeem/token`, `/refunds`, `/refunds/me`, `/reviews`, `/favorites`, `/favorites/me`,
`/notifications/me`, `/notifications/device-token`. Xem Swagger của BE tại `http://localhost:3000/docs`.

## Phân công

Theo `Document/Phan-cong-cong-viec-Voucher.xlsx` (sheet "Tính năng", mã F01–F18). Mỗi người làm trọn tính năng của mình qua cả API, app và web.
Tạo nhánh `feature/Fxx-ten-ngan` từ `main`, mở PR và cần ít nhất một người review.
