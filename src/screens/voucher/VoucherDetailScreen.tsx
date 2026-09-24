import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Button } from '@/components/Button';
import { Card } from '@/components/Card';
import { searchApi } from '@/services/voucherApi';
import { formatVND, formatDateTime } from '@/utils/currency';
import { colors, spacing } from '@/theme';
import type { VoucherCampaign } from '@/types/domain';

type Route = RouteProp<RootStackParamList, 'VoucherDetail'>;

// FR-SEARCH-07: chi tiet voucher - gia, gia tri, dieu kien ap dung, han su dung, chi nhanh ap dung
export function VoucherDetailScreen() {
  const { params } = useRoute<Route>();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const [campaign, setCampaign] = useState<VoucherCampaign | null>(null);

  useEffect(() => {
    searchApi.detail(params.campaignId).then(setCampaign).catch(() => setCampaign(null));
  }, [params.campaignId]);

  if (!campaign) {
    return (
      <ScreenContainer>
        <Text>Dang tai...</Text>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer>
      <View style={styles.imagePlaceholder} />
      <Text style={styles.title}>{campaign.title}</Text>
      <Text style={styles.price}>{formatVND(campaign.salePrice)}</Text>
      <Text style={styles.faceValue}>Gia tri: {formatVND(campaign.faceValue)}</Text>

      <Card>
        <Text style={styles.sectionTitle}>Dieu kien ap dung</Text>
        <Text style={styles.body}>{campaign.description || 'Dang cap nhat.'}</Text>
      </Card>

      <Card>
        <Text style={styles.sectionTitle}>Han su dung</Text>
        <Text style={styles.body}>{formatDateTime(campaign.voucherExpireAt)}</Text>
      </Card>

      <Card>
        <Text style={styles.sectionTitle}>Chinh sach hoan tien</Text>
        <Text style={styles.body}>
          Duoc hoan tien trong 7 ngay ke tu ngay mua neu chua su dung va con it nhat 3 ngay truoc han
          su dung.
        </Text>
      </Card>

      {/* TODO: hien danh sach chi nhanh ap dung kem khoang cach (FR-SEARCH-07) */}

      <Button label="Mua ngay" onPress={() => navigation.navigate('Checkout', { campaignId: campaign.id })} />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  imagePlaceholder: { height: 180, borderRadius: 12, backgroundColor: colors.border },
  title: { fontSize: 20, fontWeight: '800', color: colors.textPrimary },
  price: { fontSize: 22, fontWeight: '800', color: colors.primary },
  faceValue: { color: colors.textSecondary },
  sectionTitle: { fontWeight: '700', marginBottom: spacing.xs, color: colors.textPrimary },
  body: { color: colors.textSecondary },
});
