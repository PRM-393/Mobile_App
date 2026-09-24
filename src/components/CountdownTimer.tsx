import { useEffect, useState } from 'react';
import { StyleSheet, Text } from 'react-native';
import { colors } from '@/theme';

// Dem nguoc hieu luc token QR (60 giay) - FR-REDEEM-02
export function CountdownTimer({ expiresAt, onExpire }: { expiresAt: string; onExpire?: () => void }) {
  const [remaining, setRemaining] = useState(() => secondsLeft(expiresAt));

  useEffect(() => {
    const interval = setInterval(() => {
      const next = secondsLeft(expiresAt);
      setRemaining(next);
      if (next <= 0) {
        clearInterval(interval);
        onExpire?.();
      }
    }, 1000);
    return () => clearInterval(interval);
  }, [expiresAt, onExpire]);

  return (
    <Text style={[styles.text, remaining <= 10 && styles.warning]}>
      {remaining > 0 ? `Con hieu luc ${remaining}s` : 'Da het han'}
    </Text>
  );
}

function secondsLeft(expiresAt: string): number {
  return Math.max(0, Math.floor((new Date(expiresAt).getTime() - Date.now()) / 1000));
}

const styles = StyleSheet.create({
  text: { fontSize: 16, fontWeight: '700', color: colors.textPrimary, textAlign: 'center' },
  warning: { color: colors.danger },
});
