import { useEffect, useState } from 'react';
import { FlatList, StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Card } from '@/components/Card';
import { Button } from '@/components/Button';
import { walletApi } from '@/services/voucherApi';
import { formatDateTime } from '@/utils/currency';
import { colors, spacing } from '@/theme';
import type { VoucherItem, VoucherItemStatus } from '@/types/domain';

const TABS: { key: VoucherItemStatus; label: string }[] = [
  { key: 'ACTIVE', label: 'Dang hieu luc' },
  { key: 'USED', label: 'Da dung' },
  { key: 'EXPIRED', label: 'Het han' },
  { key: 'REFUNDED', label: 'Da hoan' },
];

// FR-REDEEM-01: vi voucher chia theo tab
export function WalletScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const [tab, setTab] = useState<VoucherItemStatus>('ACTIVE');
  const [items, setItems] = useState<VoucherItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    walletApi
      .myVouchers()
      .then(setItems)
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  }, []);

  const filtered = items.filter((i) => i.status === tab);

  return (
    <ScreenContainer scroll={false}>
      <View style={styles.tabs}>
        {TABS.map((t) => (
          <Text
            key={t.key}
            style={[styles.tab, tab === t.key && styles.tabActive]}
            onPress={() => setTab(t.key)}
          >
            {t.label}
          </Text>
        ))}
      </View>

      <FlatList
        contentContainerStyle={styles.list}
        data={filtered}
        keyExtractor={(i) => i.id}
        renderItem={({ item }) => (
          <Card style={styles.item}>
            <Text style={styles.code}>{item.code}</Text>
            <Text style={styles.expire}>Han su dung: {formatDateTime(item.expireAt)}</Text>
            {item.status === 'ACTIVE' && (
              <Button
                label="Su dung ngay"
                onPress={() => navigation.navigate('RedeemQr', { voucherItemId: item.id })}
              />
            )}
          </Card>
        )}
        ListEmptyComponent={
          !loading ? <Text style={styles.empty}>Khong co voucher nao trong muc nay.</Text> : null
        }
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  tabs: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, padding: spacing.md },
  tab: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 999,
    paddingVertical: spacing.xs,
    paddingHorizontal: spacing.md,
    color: colors.textPrimary,
    overflow: 'hidden',
  },
  tabActive: { backgroundColor: colors.primary, color: colors.white, borderColor: colors.primary },
  list: { padding: spacing.md, gap: spacing.md },
  item: { gap: spacing.sm },
  code: { fontWeight: '700', color: colors.textPrimary },
  expire: { color: colors.textSecondary, fontSize: 12 },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.lg },
});
