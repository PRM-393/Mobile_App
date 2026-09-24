import { useEffect, useState } from 'react';
import { FlatList, StyleSheet, Text } from 'react-native';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Card } from '@/components/Card';
import { orderApi } from '@/services/voucherApi';
import { formatVND, formatDateTime } from '@/utils/currency';
import { colors, spacing } from '@/theme';
import type { Order } from '@/types/domain';

// FR-ORDER-09: khach hang xem lich su don hang kem trang thai thanh toan
export function OrderHistoryScreen() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    orderApi
      .myOrders()
      .then(setOrders)
      .catch(() => setOrders([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <ScreenContainer scroll={false}>
      <FlatList
        contentContainerStyle={styles.list}
        data={orders}
        keyExtractor={(o) => o.id}
        renderItem={({ item }) => (
          <Card>
            <Text style={styles.amount}>{formatVND(item.totalAmount)}</Text>
            <Text style={styles.meta}>
              So luong: {item.quantity} - {formatDateTime(item.createdAt)}
            </Text>
            <Text style={styles.status}>{item.status}</Text>
          </Card>
        )}
        ListEmptyComponent={!loading ? <Text style={styles.empty}>Chua co don hang nao.</Text> : null}
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  list: { padding: spacing.md, gap: spacing.md },
  amount: { fontWeight: '700', color: colors.textPrimary },
  meta: { color: colors.textSecondary, fontSize: 12 },
  status: { color: colors.primary, fontWeight: '600', marginTop: spacing.xs },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.lg },
});
