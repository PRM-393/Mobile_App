import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Card } from './Card';
import { colors, spacing } from '@/theme';
import { formatVND } from '@/utils/currency';
import type { VoucherCampaign } from '@/types/domain';

// The voucher/campaign dung o man hinh Kham pha, Tim kiem, Yeu thich - FR-SEARCH-*
export function VoucherCard({
  campaign,
  distanceLabel,
  onPress,
}: {
  campaign: VoucherCampaign;
  distanceLabel?: string;
  onPress?: () => void;
}) {
  return (
    <Pressable onPress={onPress}>
      <Card style={styles.card}>
        <View style={styles.imagePlaceholder} />
        <Text style={styles.title} numberOfLines={2}>
          {campaign.title}
        </Text>
        <View style={styles.priceRow}>
          <Text style={styles.price}>{formatVND(campaign.salePrice)}</Text>
          {campaign.discountPercent ? (
            <Text style={styles.discount}>-{campaign.discountPercent}%</Text>
          ) : null}
        </View>
        {distanceLabel && <Text style={styles.distance}>{distanceLabel}</Text>}
      </Card>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { width: 180, marginRight: spacing.md },
  imagePlaceholder: {
    height: 100,
    borderRadius: 8,
    backgroundColor: colors.border,
    marginBottom: spacing.sm,
  },
  title: { fontSize: 14, fontWeight: '600', color: colors.textPrimary, minHeight: 36 },
  priceRow: { flexDirection: 'row', alignItems: 'center', marginTop: spacing.xs, gap: spacing.xs },
  price: { color: colors.primary, fontWeight: '700' },
  discount: { color: colors.danger, fontSize: 12, fontWeight: '600' },
  distance: { color: colors.textSecondary, fontSize: 12, marginTop: spacing.xs },
});
