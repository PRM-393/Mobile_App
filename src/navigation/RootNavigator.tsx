import { createNativeStackNavigator } from '@react-navigation/native-stack';
import type { RootStackParamList } from './types';
import { MainTabNavigator } from './MainTabNavigator';
import { VoucherDetailScreen } from '@/screens/voucher/VoucherDetailScreen';
import { CheckoutScreen } from '@/screens/checkout/CheckoutScreen';
import { RedeemQrScreen } from '@/screens/redeem/RedeemQrScreen';
import { RefundRequestScreen } from '@/screens/refund/RefundRequestScreen';
import { ReviewScreen } from '@/screens/favorites/ReviewScreen';
import { NotificationsScreen } from '@/screens/notifications/NotificationsScreen';
import { FavoritesScreen } from '@/screens/favorites/FavoritesScreen';

const Stack = createNativeStackNavigator<RootStackParamList>();

// Stack goc: tab chinh + cac man hinh day tu tab (chi tiet voucher, checkout, redeem QR...)
export function RootNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Main" component={MainTabNavigator} options={{ headerShown: false }} />
      <Stack.Screen
        name="VoucherDetail"
        component={VoucherDetailScreen}
        options={{ title: 'Chi tiet voucher' }}
      />
      <Stack.Screen name="Checkout" component={CheckoutScreen} options={{ title: 'Thanh toan' }} />
      <Stack.Screen
        name="RedeemQr"
        component={RedeemQrScreen}
        options={{ title: 'Su dung voucher', presentation: 'fullScreenModal' }}
      />
      <Stack.Screen
        name="RefundRequest"
        component={RefundRequestScreen}
        options={{ title: 'Yeu cau hoan tien' }}
      />
      <Stack.Screen name="Review" component={ReviewScreen} options={{ title: 'Danh gia' }} />
      <Stack.Screen
        name="Notifications"
        component={NotificationsScreen}
        options={{ title: 'Thong bao' }}
      />
      <Stack.Screen name="Favorites" component={FavoritesScreen} options={{ title: 'Yeu thich' }} />
    </Stack.Navigator>
  );
}
