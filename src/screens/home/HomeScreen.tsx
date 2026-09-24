import { useEffect, useState } from 'react';
import { FlatList, StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { VoucherCard } from '@/components/VoucherCard';
import { searchApi } from '@/services/voucherApi';
import { colors, spacing } from '@/theme';
import type { Category, VoucherCampaign } from '@/types/domain';

// FR-SEARCH-01/04: man hinh Kham pha - danh muc + voucher moi nhat/ban chay
export function HomeScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const [categories, setCategories] = useState<Category[]>([]);
  const [featured, setFeatured] = useState<VoucherCampaign[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([searchApi.categories(), searchApi.search({ sort: 'newest', pageSize: 10 })])
      .then(([cats, result]) => {
        setCategories(cats);
        setFeatured(result.items);
      })
      .catch(() => {
        setCategories([]);
        setFeatured([]);
      })
      .finally(() => setLoading(false));
  }, []);

  return (
    <ScreenContainer>
      <Text style={styles.heading}>Danh muc</Text>
      <FlatList
        horizontal
        data={categories}
        keyExtractor={(c) => c.id}
        showsHorizontalScrollIndicator={false}
        renderItem={({ item }) => (
          <View style={styles.categoryChip}>
            <Text style={styles.categoryLabel}>{item.name}</Text>
          </View>
        )}
        ListEmptyComponent={!loading ? <Text style={styles.empty}>Chua co danh muc</Text> : null}
      />

      <Text style={styles.heading}>Voucher moi</Text>
      <FlatList
        horizontal
        data={featured}
        keyExtractor={(c) => c.id}
        showsHorizontalScrollIndicator={false}
        renderItem={({ item }) => (
          <VoucherCard
            campaign={item}
            onPress={() => navigation.navigate('VoucherDetail', { campaignId: item.id })}
          />
        )}
        ListEmptyComponent={!loading ? <Text style={styles.empty}>Chua co voucher nao</Text> : null}
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  heading: { fontSize: 16, fontWeight: '700', color: colors.textPrimary, marginTop: spacing.sm },
  categoryChip: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 999,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    marginRight: spacing.sm,
  },
  categoryLabel: { color: colors.textPrimary, fontWeight: '600' },
  empty: { color: colors.textSecondary, paddingVertical: spacing.md },
});
