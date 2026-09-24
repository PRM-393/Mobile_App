import { StyleSheet, Text, View } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/navigation/types';
import { ScreenContainer } from '@/components/ScreenContainer';
import { Card } from '@/components/Card';
import { Button } from '@/components/Button';
import { useAuthStore } from '@/store/authStore';
import { authApi } from '@/services/authApi';
import { colors, spacing } from '@/theme';

// FR-AUTH-05: khach hang xem/cap nhat ho so ca nhan; cung la diem vao Yeu thich, Thong bao
export function ProfileScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const { user, clearSession } = useAuthStore();

  const handleLogout = async () => {
    try {
      await authApi.logout();
    } catch {
      // bo qua loi mang, van xoa phien cuc bo
    }
    await clearSession();
  };

  return (
    <ScreenContainer>
      <Card style={styles.profileCard}>
        <View style={styles.avatar} />
        <Text style={styles.name}>{user?.fullName || 'Khach hang'}</Text>
        <Text style={styles.email}>{user?.email}</Text>
      </Card>

      <Card>
        <Text style={styles.menuItem} onPress={() => navigation.navigate('Favorites')}>
          Yeu thich
        </Text>
        <Text style={styles.menuItem} onPress={() => navigation.navigate('Notifications')}>
          Thong bao
        </Text>
        <Text style={styles.menuItem}>Chinh sua ho so (TODO)</Text>
      </Card>

      <Button label="Dang xuat" variant="danger" onPress={handleLogout} />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  profileCard: { alignItems: 'center', gap: spacing.xs },
  avatar: { width: 72, height: 72, borderRadius: 36, backgroundColor: colors.border },
  name: { fontWeight: '700', fontSize: 16, color: colors.textPrimary },
  email: { color: colors.textSecondary },
  menuItem: {
    paddingVertical: spacing.sm,
    color: colors.textPrimary,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
});
