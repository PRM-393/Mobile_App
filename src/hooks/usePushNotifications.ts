import { useEffect } from 'react';
import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { engageApi } from '@/services/voucherApi';
import { useAuthStore } from '@/store/authStore';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

// FR-ENGAGE-06/07: dang ky device token voi BE de nhan thong bao day qua Firebase Cloud Messaging.
// TODO: cau hinh Firebase (google-services.json / GoogleService-Info.plist) truoc khi build native
// va thay expo-notifications getExpoPushTokenAsync bang FCM token that neu can tich hop truc tiep.
export function usePushNotifications() {
  const user = useAuthStore((s) => s.user);

  useEffect(() => {
    if (!user) return;

    (async () => {
      const { status: existingStatus } = await Notifications.getPermissionsAsync();
      let finalStatus = existingStatus;
      if (existingStatus !== 'granted') {
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
      }
      if (finalStatus !== 'granted') return;

      try {
        const tokenResponse = await Notifications.getExpoPushTokenAsync();
        await engageApi.registerDeviceToken(tokenResponse.data, Platform.OS === 'ios' ? 'ios' : 'android');
      } catch {
        // TODO: xu ly loi lay push token (vd. chay tren simulator khong ho tro)
      }
    })();
  }, [user]);
}
