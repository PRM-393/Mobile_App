// Kieu du lieu cho tung ngan xep dieu huong - dung voi @react-navigation/native-stack

export type AuthStackParamList = {
  Login: undefined;
  OtpVerify: { email: string };
};

export type MainTabParamList = {
  HomeTab: undefined;
  SearchTab: undefined;
  WalletTab: undefined;
  OrdersTab: undefined;
  ProfileTab: undefined;
};

export type RootStackParamList = {
  Main: undefined;
  VoucherDetail: { campaignId: string };
  Checkout: { campaignId: string };
  RedeemQr: { voucherItemId: string };
  RefundRequest: { voucherItemId: string };
  Review: { voucherItemId: string };
  Notifications: undefined;
  Favorites: undefined;
};

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace ReactNavigation {
    interface RootParamList extends RootStackParamList {}
  }
}
