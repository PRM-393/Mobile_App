import { useEffect, useState } from 'react';
import { FlatList, StyleSheet, Text } from 'react-native';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Card } from '@/components/Card';
import { engageApi } from '@/services/voucherApi';
import { formatDateTime } from '@/utils/currency';
import { colors, spacing } from '@/theme';

interface NotificationItem {
  id: string;
  title: string;
  body: string;
  createdAt: string;
}

// FR-ENGAGE-06: danh sach thong bao day nhan duoc (phat hanh, sap het han, ket qua hoan tien...)
export function NotificationsScreen() {
  const [items, setItems] = useState<NotificationItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    engageApi
      .myNotifications()
      .then((data) => setItems(data as NotificationItem[]))
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
            <Text style={styles.title}>{item.title}</Text>
            <Text style={styles.body}>{item.body}</Text>
            <Text style={styles.time}>{formatDateTime(item.createdAt)}</Text>
          </Card>
        )}
        ListEmptyComponent={!loading ? <Text style={styles.empty}>Chua co thong bao nao.</Text> : null}
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  list: { padding: spacing.md, gap: spacing.md },
  title: { fontWeight: '700', color: colors.textPrimary },
  body: { color: colors.textSecondary, marginTop: spacing.xs },
  time: { color: colors.textSecondary, fontSize: 11, marginTop: spacing.xs },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.lg },
});
