import { useState } from 'react';
import { StyleSheet, Text, TextInput, View } from 'react-native';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { RootStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Button } from '@/components/Button';
import { engageApi } from '@/services/voucherApi';
import { colors, spacing } from '@/theme';

type Route = RouteProp<RootStackParamList, 'Review'>;

// FR-ENGAGE-02/03: danh gia 1-5 sao, chi cho voucher da su dung, moi voucher mot lan
export function ReviewScreen() {
  const { params } = useRoute<Route>();
  const navigation = useNavigation();
  const [rating, setRating] = useState(5);
  const [comment, setComment] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async () => {
    setLoading(true);
    try {
      await engageApi.createReview(params.voucherItemId, rating, comment);
      navigation.goBack();
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScreenContainer>
      <Text style={styles.label}>Danh gia cua ban</Text>
      <View style={styles.stars}>
        {[1, 2, 3, 4, 5].map((n) => (
          <Text key={n} style={styles.star} onPress={() => setRating(n)}>
            {n <= rating ? '★' : '☆'}
          </Text>
        ))}
      </View>
      <TextInput
        style={styles.input}
        placeholder="Chia se trai nghiem cua ban..."
        value={comment}
        onChangeText={setComment}
        multiline
      />
      <Button label="Gui danh gia" onPress={submit} loading={loading} />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  label: { color: colors.textSecondary },
  stars: { flexDirection: 'row', gap: spacing.sm },
  star: { fontSize: 32, color: colors.secondary },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    minHeight: 100,
    backgroundColor: colors.surface,
    textAlignVertical: 'top',
  },
});
