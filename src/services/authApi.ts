import { apiClient } from './apiClient';
import type { LoginResponse } from '@/types/auth';

// FR-AUTH-01/02: dang ky bang email, dang nhap bang OTP
export const authApi = {
  register: (email: string, fullName?: string) =>
    apiClient.post('/auth/register', { email, fullName }).then((r) => r.data),

  requestOtp: (email: string) => apiClient.post('/auth/otp/request', { email }).then((r) => r.data),

  verifyOtp: (email: string, otp: string) =>
    apiClient.post<LoginResponse>('/auth/otp/verify', { email, otp }).then((r) => r.data),

  logout: () => apiClient.post('/auth/logout'),
};
