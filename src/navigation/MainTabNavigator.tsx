import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import type { MainTabParamList } from './types';
import { colors } from '@/theme';
import { HomeScreen } from '@/screens/home/HomeScreen';
import { SearchScreen } from '@/screens/search/SearchScreen';
import { WalletScreen } from '@/screens/wallet/WalletScreen';
import { OrderHistoryScreen } from '@/screens/orders/OrderHistoryScreen';
import { ProfileScreen } from '@/screens/profile/ProfileScreen';

const Tab = createBottomTabNavigator<MainTabParamList>();

// Tab chinh cua ung dung khach hang: Kham pha, Tim kiem, Vi voucher, Don hang, Ca nhan
export function MainTabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textSecondary,
      }}
    >
      <Tab.Screen name="HomeTab" component={HomeScreen} options={{ title: 'Kham pha' }} />
      <Tab.Screen name="SearchTab" component={SearchScreen} options={{ title: 'Tim kiem' }} />
      <Tab.Screen name="WalletTab" component={WalletScreen} options={{ title: 'Vi voucher' }} />
      <Tab.Screen name="OrdersTab" component={OrderHistoryScreen} options={{ title: 'Don hang' }} />
      <Tab.Screen name="ProfileTab" component={ProfileScreen} options={{ title: 'Ca nhan' }} />
    </Tab.Navigator>
  );
}
