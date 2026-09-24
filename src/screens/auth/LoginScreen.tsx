import { useState } from 'react';
import { StyleSheet, Text, TextInput, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { AuthStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Button } from '@/components/Button';
import { authApi } from '@/services/authApi';
import { colors, spacing } from '@/theme';

type Props = NativeStackScreenProps<AuthStackParamList, 'Login'>;

// FR-AUTH-01/02: khach hang dang nhap bang email + OTP (khong dung mat khau)
export function LoginScreen({ navigation }: Props) {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleContinue = async () => {
    setError(null);
    setLoading(true);
    try {
      await authApi.requestOtp(email);
      navigation.navigate('OtpVerify', { email });
    } catch {
      setError('Khong the gui ma OTP luc nay. Vui long thu lai.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScreenContainer>
      <View style={styles.hero}>
        <Text style={styles.title}>Voucher Platform</Text>
        <Text style={styles.subtitle}>Uu dai da thuong hieu, dung ngay tai cua hang</Text>
      </View>

      <Text style={styles.label}>Email</Text>
      <TextInput
        style={styles.input}
        placeholder="ban@vidu.com"
        autoCapitalize="none"
        keyboardType="email-address"
        value={email}
        onChangeText={setEmail}
      />

      {error && <Text style={styles.error}>{error}</Text>}

      <Button label="Gui ma OTP" onPress={handleContinue} loading={loading} disabled={!email} />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  hero: { alignItems: 'center', marginVertical: spacing.xl },
  title: { fontSize: 24, fontWeight: '800', color: colors.textPrimary },
  subtitle: { fontSize: 14, color: colors.textSecondary, marginTop: spacing.xs, textAlign: 'center' },
  label: { fontSize: 13, color: colors.textSecondary, marginBottom: spacing.xs },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    marginBottom: spacing.md,
    backgroundColor: colors.surface,
  },
  error: { color: colors.danger, marginBottom: spacing.md },
});
