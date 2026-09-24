import { useCallback, useEffect, useState } from 'react';
import { FlatList, StyleSheet, Text, TextInput, View } from 'react-native';
import * as Location from 'expo-location';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { VoucherCard } from '@/components/VoucherCard';
import { searchApi } from '@/services/voucherApi';
import { RADIUS_OPTIONS_KM, formatDistance } from '@/utils/distance';
import { colors, spacing } from '@/theme';
import type { VoucherCampaign } from '@/types/domain';

// FR-SEARCH-02/03/05/06: tim kiem theo tu khoa, loc gia, "gan toi" voi xin quyen vi tri
export function SearchScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const [keyword, setKeyword] = useState('');
  const [radiusKm, setRadiusKm] = useState<number | null>(null);
  const [coords, setCoords] = useState<{ lat: number; lng: number } | null>(null);
  const [locationDenied, setLocationDenied] = useState(false);
  const [results, setResults] = useState<VoucherCampaign[]>([]);
  const [loading, setLoading] = useState(false);

  const runSearch = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = { keyword: keyword || undefined };
      if (coords && radiusKm) {
        params.lat = coords.lat;
        params.lng = coords.lng;
        params.radiusKm = radiusKm;
      }
      const result = await searchApi.search(params);
      setResults(result.items);
    } catch {
      setResults([]);
    } finally {
      setLoading(false);
    }
  }, [keyword, coords, radiusKm]);

  useEffect(() => {
    runSearch();
  }, [runSearch]);

  // FR-SEARCH-06: neu khach tu choi quyen truy cap vi tri, hien danh sach mac dinh kem thong bao ly do
  const enableNearMe = async () => {
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') {
      setLocationDenied(true);
      return;
    }
    const position = await Location.getCurrentPositionAsync({});
    setCoords({ lat: position.coords.latitude, lng: position.coords.longitude });
    setRadiusKm(3);
  };

  return (
    <ScreenContainer>
      <TextInput
        style={styles.input}
        placeholder="Tim voucher hoac thuong hieu..."
        value={keyword}
        onChangeText={setKeyword}
        onSubmitEditing={runSearch}
      />

      <View style={styles.radiusRow}>
        {RADIUS_OPTIONS_KM.map((km) => (
          <Text
            key={km}
            style={[styles.radiusChip, radiusKm === km && styles.radiusChipActive]}
            onPress={() => {
              setRadiusKm(km);
              if (!coords) enableNearMe();
            }}
          >
            {km} km
          </Text>
        ))}
      </View>

      {locationDenied && (
        <Text style={styles.notice}>
          Khong the truy cap vi tri. Dang hien danh sach mac dinh, khong the loc theo khoang cach.
        </Text>
      )}

      <FlatList
        data={results}
        keyExtractor={(c) => c.id}
        numColumns={2}
        columnWrapperStyle={styles.row}
        renderItem={({ item }) => (
          <VoucherCard
            campaign={item}
            distanceLabel={coords ? formatDistance(radiusKm ?? 0) : undefined}
            onPress={() => navigation.navigate('VoucherDetail', { campaignId: item.id })}
          />
        )}
        ListEmptyComponent={!loading ? <Text style={styles.empty}>Khong tim thay voucher phu hop</Text> : null}
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
  },
  radiusRow: { flexDirection: 'row', gap: spacing.sm },
  radiusChip: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 999,
    paddingVertical: spacing.xs,
    paddingHorizontal: spacing.md,
    color: colors.textPrimary,
    overflow: 'hidden',
  },
  radiusChipActive: { backgroundColor: colors.primary, color: colors.white, borderColor: colors.primary },
  notice: { color: colors.textSecondary, fontSize: 12 },
  row: { gap: spacing.md },
  empty: { color: colors.textSecondary, textAlign: 'center', marginTop: spacing.lg },
});
