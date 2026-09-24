import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Button } from '@/components/Button';
import { orderApi } from '@/services/voucherApi';
import { colors, spacing } from '@/theme';

type Route = RouteProp<RootStackParamList, 'Checkout'>;

// UC-01: tao don hang, giu ton kho 15 phut, chuyen sang cong thanh toan sandbox - FR-ORDER-01..04
export function CheckoutScreen() {
  const { params } = useRoute<Route>();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const [quantity, setQuantity] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handlePay = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await orderApi.create(params.campaignId, quantity);
      // TODO: mo WebView toi res.paymentUrl (cong thanh toan sandbox), lang nghe ket qua qua deep link
      // sau khi webhook BE xac nhan thanh toan thanh cong, dieu huong ve man hinh Vi voucher.
      // eslint-disable-next-line no-console
      console.log('paymentUrl', res.paymentUrl);
      navigation.navigate('Main');
    } catch {
      setError('Khong the tao don hang. Co the da het ton kho, vui long thu lai.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScreenContainer>
      <Text style={styles.label}>So luong</Text>
      <View style={styles.stepper}>
        <Text style={styles.stepperBtn} onPress={() => setQuantity((q) => Math.max(1, q - 1))}>
          -
        </Text>
        <Text style={styles.quantity}>{quantity}</Text>
        <Text style={styles.stepperBtn} onPress={() => setQuantity((q) => q + 1)}>
          +
        </Text>
      </View>

      <Text style={styles.notice}>
        Don hang se duoc giu cho trong 15 phut. Neu khong hoan tat thanh toan, don se tu dong huy va
        tra lai ton kho (FR-ORDER-03).
      </Text>

      {error && <Text style={styles.error}>{error}</Text>}

      <Button label="Tien hanh thanh toan" onPress={handlePay} loading={loading} />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  label: { color: colors.textSecondary, marginBottom: spacing.xs },
  stepper: { flexDirection: 'row', alignItems: 'center', gap: spacing.lg },
  stepperBtn: {
    fontSize: 20,
    fontWeight: '800',
    width: 40,
    height: 40,
    textAlign: 'center',
    lineHeight: 40,
    backgroundColor: colors.border,
    borderRadius: 8,
    color: colors.textPrimary,
  },
  quantity: { fontSize: 20, fontWeight: '700', color: colors.textPrimary },
  notice: { color: colors.textSecondary, fontSize: 12 },
  error: { color: colors.danger },
});
