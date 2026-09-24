import { useState } from 'react';
import { StyleSheet, Text, TextInput, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { AuthStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Button } from '@/components/Button';
import { authApi } from '@/services/authApi';
import { useAuthStore } from '@/store/authStore';
import { colors, spacing } from '@/theme';

type Props = NativeStackScreenProps<AuthStackParamList, 'OtpVerify'>;

// FR-AUTH-02/03: xac thuc OTP 6 so, cap access token (15p) + refresh token (60 ngay)
export function OtpVerifyScreen({ route }: Props) {
  const { email } = route.params;
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const setSession = useAuthStore((s) => s.setSession);

  const handleVerify = async () => {
    setError(null);
    setLoading(true);
    try {
      const res = await authApi.verifyOtp(email, otp);
      await setSession(res.user, { accessToken: res.accessToken, refreshToken: res.refreshToken });
      // RootNavigator se tu chuyen sang MainTabNavigator khi user != null (xem App.tsx)
    } catch {
      setError('Ma OTP khong dung hoac da het han.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScreenContainer>
      <View style={styles.hero}>
        <Text style={styles.title}>Nhap ma OTP</Text>
        <Text style={styles.subtitle}>Ma xac thuc da duoc gui toi {email}</Text>
      </View>

      <TextInput
        style={styles.otpInput}
        placeholder="------"
        keyboardType="number-pad"
        maxLength={6}
        value={otp}
        onChangeText={setOtp}
      />

      {error && <Text style={styles.error}>{error}</Text>}

      <Button label="Xac nhan" onPress={handleVerify} loading={loading} disabled={otp.length !== 6} />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  hero: { alignItems: 'center', marginVertical: spacing.xl },
  title: { fontSize: 22, fontWeight: '800', color: colors.textPrimary },
  subtitle: { fontSize: 14, color: colors.textSecondary, marginTop: spacing.xs, textAlign: 'center' },
  otpInput: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    marginBottom: spacing.md,
    backgroundColor: colors.surface,
    fontSize: 24,
    letterSpacing: 8,
    textAlign: 'center',
  },
  error: { color: colors.danger, marginBottom: spacing.md, textAlign: 'center' },
});
