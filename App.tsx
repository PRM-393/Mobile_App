import { useEffect } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { StatusBar } from 'expo-status-bar';
import { AuthNavigator } from '@/navigation/AuthNavigator';
import { RootNavigator } from '@/navigation/RootNavigator';
import { useAuthStore } from '@/store/authStore';
import { usePushNotifications } from '@/hooks/usePushNotifications';
import { colors } from '@/theme';

function Gate() {
  const { user, isHydrated, hydrate } = useAuthStore();

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  usePushNotifications();

  if (!isHydrated) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator color={colors.primary} size="large" />
      </View>
    );
  }

  return user ? <RootNavigator /> : <AuthNavigator />;
}

export default function App() {
  return (
    <NavigationContainer>
      <StatusBar style="dark" />
      <Gate />
    </NavigationContainer>
  );
}
