import * as SecureStore from 'expo-secure-store';

// Luu JWT access/refresh token an toan tren thiet bi (Keychain/Keystore) - NFR-SEC
const ACCESS_TOKEN_KEY = 'voucher_platform_access_token';
const REFRESH_TOKEN_KEY = 'voucher_platform_refresh_token';

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
  async clear() {
    await SecureStore.deleteItemAsync(ACCESS_TOKEN_KEY);
    await SecureStore.deleteItemAsync(REFRESH_TOKEN_KEY);
  },
};
