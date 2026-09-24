# Voucher Platform Mobile (Customer App)

Ung dung di dong danh cho **khach hang**, xay dung bang **React Native + Expo (managed workflow)
+ TypeScript**. Day la du an duoc uu tien nhat trong 3 repo ("du an tap trung vao mobile" theo
SRS), nen scaffold nay dau tu day du nhat vao cau truc dieu huong va man hinh.

## Cai dat va chay

```bash
npm install
cp .env.example .env      # EXPO_PUBLIC_API_BASE_URL tro ve NestJS API
npm run typecheck          # tsc --noEmit, khong loi
npm run start               # expo start -> quet QR bang Expo Go, hoac nhan 'a' / 'i' cho may ao
```

Chay `expo start` doi hoi may co ket noi mang va (tuy chon) tai khoan Expo; khong bat buoc trong
moi truong phat trien nay — `npm install` va `npm run typecheck` la hai lenh duoc dung de xac
nhan scaffold hop le.

## Vi sao Expo (managed workflow)

- Scaffold nhanh, cau hinh it, build duoc ca Android (uu tien - CON-01) va iOS tu cung mot codebase.
- `expo-secure-store`, `expo-location`, `expo-notifications` co san san dang, khop voi cac yeu cau
  luu token an toan, xin quyen vi tri ("gan toi" - FR-SEARCH-06) va push notification (FR-ENGAGE-06)
  ma khong can tu cau hinh native module.
- Neu ve sau can native module ngoai pham vi Expo SDK, co the `expo prebuild` de chuyen sang bare
  workflow ma khong phai viet lai ung dung.

## Cau truc thu muc

```
App.tsx                      # entry: NavigationContainer, hydrate phien dang nhap, gate Auth/Main
src/
  navigation/
    types.ts                  # kieu cho AuthStack, MainTab, RootStack
    AuthNavigator.tsx           # Login -> OtpVerify (FR-AUTH-01/02)
    MainTabNavigator.tsx         # 5 tab: Kham pha, Tim kiem, Vi voucher, Don hang, Ca nhan
    RootNavigator.tsx             # tab chinh + man hinh day: VoucherDetail, Checkout, RedeemQr,
                                    # RefundRequest, Review, Notifications, Favorites
  screens/
    auth/          LoginScreen, OtpVerifyScreen
    home/           HomeScreen (danh muc + voucher moi - FR-SEARCH-01/04)
    search/          SearchScreen (tu khoa, "gan toi" voi expo-location - FR-SEARCH-02/03/05/06)
    voucher/          VoucherDetailScreen (FR-SEARCH-07)
    checkout/          CheckoutScreen (tao don, giu ton kho 15p - FR-ORDER-01..04)
    wallet/             WalletScreen (vi voucher chia tab - FR-REDEEM-01)
    redeem/              RedeemQrScreen (QR dong 60s + OTP, dem nguoc - FR-REDEEM-02/03)
    orders/               OrderHistoryScreen (FR-ORDER-09)
    refund/                RefundRequestScreen (UC-03, BR-05)
    favorites/              FavoritesScreen, ReviewScreen (FR-ENGAGE-01/02/03)
    notifications/            NotificationsScreen (FR-ENGAGE-06)
    profile/                   ProfileScreen
  components/          Button, Card, VoucherCard, CountdownTimer, ScreenContainer
  services/
    apiClient.ts         # axios: gan Bearer token, tu refresh khi 401
    secureStorage.ts       # luu access/refresh token + user bang expo-secure-store (Keychain/Keystore)
    authApi.ts, voucherApi.ts
  store/                 # Zustand: authStore (phien dang nhap), cartStore
  hooks/
    usePushNotifications.ts # xin quyen, lay Expo push token, dang ky voi BE (FR-ENGAGE-06/07)
  utils/
    currency.ts            # formatVND, formatDateTime (Asia/Ho_Chi_Minh)
    distance.ts              # Haversine + RADIUS_OPTIONS_KM cho "gan toi" (FR-SEARCH-05/06)
  theme/                    # mau sac, khoang cach dung chung
  types/                     # AuthUser, VoucherCampaign, Order, VoucherItem, RefundRequest...
```

## Quyet dinh ky thuat

- **State**: Zustand (nhe hon Redux Toolkit cho pham vi 7 tuan); `authStore` tu dong hydrate tu
  `expo-secure-store` khi mo app de giu dang nhap qua cac phien.
- **Luu token**: `expo-secure-store` (Keychain tren iOS, Keystore tren Android) thay vi AsyncStorage
  vi luu du lieu nhay cam (JWT).
- **Redeem QR**: `RedeemQrScreen` goi `POST /redeem/token` de lay `qrPayload` + `otpCode`, dem
  nguoc 60 giay bang `CountdownTimer` va tu dong lam moi khi het han (FR-REDEEM-02, BR-06). Viec
  render QR thanh hinh anh that (vd. `react-native-qrcode-svg`) va quet QR o phia nhan vien cua
  hang (web) la `// TODO` ro rang trong code.
- **Vi tri "gan toi"**: `expo-location` xin quyen `WhenInUse`; neu bi tu choi, ung dung hien danh
  sach mac dinh kem thong bao (FR-SEARCH-06) thay vi chan man hinh.

## TODO nghiep vu chinh con lai (xem comment trong code)

- Render QR that tu `qrPayload` (`RedeemQrScreen`).
- Endpoint `GET /wallet` tra ve VoucherItem cua khach theo tab chua co trong BE scaffold — can bo
  sung o BE (`walletApi` trong `voucherApi.ts` da co san phia client, dang tro toi `/wallet`).
- Mo WebView toi `paymentUrl` va xu ly deep link ket qua thanh toan trong `CheckoutScreen`.
- Cau hinh Firebase that (google-services.json) truoc khi build native cho push notification.
- Man hinh chinh sua ho so (`ProfileScreen`) con la placeholder.
