import { useState } from 'react';
import { StyleSheet, Text, TextInput } from 'react-native';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { RootStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Button } from '@/components/Button';
import { refundApi } from '@/services/voucherApi';
import { colors, spacing } from '@/theme';

type Route = RouteProp<RootStackParamList, 'RefundRequest'>;

// UC-03: gui yeu cau hoan tien, he thong tu dong xet duyet theo BR-05
export function RefundRequestScreen() {
  const { params } = useRoute<Route>();
  const navigation = useNavigation();
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<string | null>(null);

  const submit = async () => {
    setLoading(true);
    try {
      const res = await refundApi.request(params.voucherItemId, reason);
      setResult(
        res.status === 'COMPLETED'
          ? 'Hoan tien thanh cong.'
          : res.status === 'REJECTED'
            ? `Khong du dieu kien: ${res.rejectReason}`
            : 'Yeu cau dang duoc xu ly.',
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScreenContainer>
      <Text style={styles.notice}>
        Chi ap dung cho voucher chua su dung, trong vong 7 ngay ke tu ngay mua va con it nhat 3 ngay
        truoc han su dung (BR-05).
      </Text>
      <TextInput
        style={styles.input}
        placeholder="Ly do hoan tien (khong bat buoc)"
        value={reason}
        onChangeText={setReason}
        multiline
      />
      {result ? (
        <>
          <Text style={styles.result}>{result}</Text>
          <Button label="Dong" onPress={() => navigation.goBack()} variant="secondary" />
        </>
      ) : (
        <Button label="Gui yeu cau" onPress={submit} loading={loading} />
      )}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  notice: { color: colors.textSecondary, fontSize: 13 },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    minHeight: 80,
    backgroundColor: colors.surface,
    textAlignVertical: 'top',
  },
  result: { fontWeight: '600', color: colors.textPrimary },
});
