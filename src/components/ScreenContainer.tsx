import type { PropsWithChildren } from 'react';
import { SafeAreaView, ScrollView, StyleSheet } from 'react-native';
import { colors, spacing } from '@/theme';

export function ScreenContainer({
  children,
  scroll = true,
}: PropsWithChildren<{ scroll?: boolean }>) {
  if (!scroll) {
    return <SafeAreaView style={styles.container}>{children}</SafeAreaView>;
  }
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>{children}</ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.md, gap: spacing.md },
});
