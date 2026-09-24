import { useEffect, useState } from 'react';
import { FlatList, StyleSheet, Text } from 'react-native';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Card } from '@/components/Card';
import { engageApi } from '@/services/voucherApi';
import { colors, spacing } from '@/theme';

// FR-ENGAGE-01: danh sach thuong hieu / voucher da danh dau yeu thich
export function FavoritesScreen() {
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    engageApi
      .myFavorites()
      .then(setItems)
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <ScreenContainer scroll={false}>
      <FlatList
        contentContainerStyle={styles.list}
        data={items}
        keyExtractor={(i) => i.id}
        renderItem={({ item }) => (
          <Card>
            <Text style={styles.label}>{item.targetType === 'BRAND' ? 'Thuong hieu' : 'Voucher'}</Text>
            <Text style={styles.id}>{item.targetId}</Text>
          </Card>
        )}
        ListEmptyComponent={!loading ? <Text style={styles.empty}>Chua co muc yeu thich nao.</Text> : null}
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  list: { padding: spacing.md, gap: spacing.md },
  label: { fontWeight: '600', color: colors.textPrimary },
  id: { color: colors.textSecondary, fontSize: 12 },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.lg },
});
