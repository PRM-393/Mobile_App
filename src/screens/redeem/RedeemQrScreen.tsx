import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useRoute, type RouteProp } from '@react-navigation/native';
import type { RootStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { CountdownTimer } from '@/components/CountdownTimer';
import { Button } from '@/components/Button';
import { redeemApi } from '@/services/voucherApi';
import { colors, spacing } from '@/theme';
import type { RedeemTokenResponse } from '@/types/domain';

type Route = RouteProp<RootStackParamList, 'RedeemQr'>;

// FR-REDEEM-02/03: hien QR dong (60s) + ma OTP tuong ung, tu dong lam moi khi het han
export function RedeemQrScreen() {
  const { params } = useRoute<Route>();
  const [token, setToken] = useState<RedeemTokenResponse | null>(null);
  const [loading, setLoading] = useState(false);

  const fetchToken = async () => {
    setLoading(true);
    try {
      const res = await redeemApi.requestToken(params.voucherItemId);
      setToken(res);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchToken();
  }, [params.voucherItemId]);

  return (
    <ScreenContainer>
      <View style={styles.qrBox}>
        {/* TODO: render QR that tu token.qrPayload, vi du dung thu vien react-native-qrcode-svg */}
        <Text style={styles.qrPlaceholder}>[ QR CODE ]</Text>
      </View>

      {token && (
        <>
          <CountdownTimer expiresAt={token.expiresAt} onExpire={fetchToken} />
          <Text style={styles.otpLabel}>Ma OTP thay the (neu nhan vien khong quet duoc QR)</Text>
          <Text style={styles.otp}>{token.otpCode}</Text>
        </>
      )}

      <Button label="Lam moi ma" onPress={fetchToken} loading={loading} variant="secondary" />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  qrBox: {
    height: 240,
    borderRadius: 16,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  qrPlaceholder: { color: colors.textSecondary },
  otpLabel: { textAlign: 'center', color: colors.textSecondary, marginTop: spacing.md },
  otp: { textAlign: 'center', fontSize: 28, fontWeight: '800', letterSpacing: 8, color: colors.textPrimary },
});
