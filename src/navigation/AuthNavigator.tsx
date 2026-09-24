import { createNativeStackNavigator } from '@react-navigation/native-stack';
import type { AuthStackParamList } from './types';
import { LoginScreen } from '@/screens/auth/LoginScreen';
import { OtpVerifyScreen } from '@/screens/auth/OtpVerifyScreen';

const Stack = createNativeStackNavigator<AuthStackParamList>();

// FR-AUTH-01/02: dang ky/dang nhap bang email + OTP
export function AuthNavigator() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Login" component={LoginScreen} />
      <Stack.Screen name="OtpVerify" component={OtpVerifyScreen} />
    </Stack.Navigator>
  );
}
