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
| Vị trí | `geolocator` (tìm voucher gần đây, FR-SEARCH) |
| QR | `qr_flutter` (hiện mã QR động 60 giây) |
| Thông báo | `flutter_local_notifications` |
| Định dạng | `intl` (tiền VND, giờ UTC+7) |

## Chạy dự án

Yêu cầu: Flutter SDK 3.x, Android Studio (emulator) hoặc thiết bị thật, máy chủ `Web_BE` đang chạy.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

- `10.0.2.2` là địa chỉ máy host khi chạy trên Android emulator (mặc định nếu không truyền).
- Thiết bị thật: dùng IP LAN của máy chạy BE, ví dụ `http://192.168.1.10:3000/api`.
- Không hard-code địa chỉ máy chủ trong mã nguồn (NFR-MNT-02).

Kiểm tra trước khi tạo PR:

```bash
flutter analyze
flutter test
```

Bản phát hành: `flutter build apk --release --dart-define=API_BASE_URL=<địa chỉ máy chủ>`.

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
6. Comment ghi mã yêu cầu SRS (ví dụ `FR-REDEEM-02`) để truy vết.

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
