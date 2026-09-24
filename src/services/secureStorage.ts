import * as SecureStore from 'expo-secure-store';

// Luu JWT access/refresh token an toan tren thiet bi (Keychain/Keystore) - NFR-SEC
const ACCESS_TOKEN_KEY = 'voucher_platform_access_token';
const REFRESH_TOKEN_KEY = 'voucher_platform_refresh_token';
const USER_KEY = 'voucher_platform_user';

export const secureStorage = {
  async saveTokens(accessToken: string, refreshToken: string) {
    await SecureStore.setItemAsync(ACCESS_TOKEN_KEY, accessToken);
    await SecureStore.setItemAsync(REFRESH_TOKEN_KEY, refreshToken);
  },
  async getAccessToken() {
    return SecureStore.getItemAsync(ACCESS_TOKEN_KEY);
  },
  async getRefreshToken() {
    return SecureStore.getItemAsync(REFRESH_TOKEN_KEY);
  },
  async saveUser(user: unknown) {
    await SecureStore.setItemAsync(USER_KEY, JSON.stringify(user));
  },
  async getUser<T>(): Promise<T | null> {
    const raw = await SecureStore.getItemAsync(USER_KEY);
    return raw ? (JSON.parse(raw) as T) : null;
  },
  async clear() {
    await SecureStore.deleteItemAsync(ACCESS_TOKEN_KEY);
    await SecureStore.deleteItemAsync(REFRESH_TOKEN_KEY);
    await SecureStore.deleteItemAsync(USER_KEY);
  },
};
