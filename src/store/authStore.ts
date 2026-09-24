import { create } from 'zustand';
import { secureStorage } from '@/services/secureStorage';
import type { AuthTokens, AuthUser } from '@/types/auth';

interface AuthState {
  user: AuthUser | null;
  accessToken: string | null;
  refreshToken: string | null;
  isHydrated: boolean;
  hydrate: () => Promise<void>;
  setSession: (user: AuthUser, tokens: AuthTokens) => Promise<void>;
  clearSession: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  accessToken: null,
  refreshToken: null,
  isHydrated: false,

  // Doc token + user da luu trong SecureStore khi app khoi dong (giu dang nhap qua cac phien)
  hydrate: async () => {
    const [accessToken, refreshToken, user] = await Promise.all([
      secureStorage.getAccessToken(),
      secureStorage.getRefreshToken(),
      secureStorage.getUser<AuthUser>(),
    ]);
    set({ accessToken, refreshToken, user, isHydrated: true });
  },

  setSession: async (user, tokens) => {
    await secureStorage.saveTokens(tokens.accessToken, tokens.refreshToken);
    await secureStorage.saveUser(user);
    set({ user, accessToken: tokens.accessToken, refreshToken: tokens.refreshToken });
  },

  clearSession: async () => {
    await secureStorage.clear();
    set({ user: null, accessToken: null, refreshToken: null });
  },
}));
