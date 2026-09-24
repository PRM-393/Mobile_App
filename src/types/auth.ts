export type Role = 'GUEST' | 'CUSTOMER' | 'BRAND_OWNER' | 'STORE_STAFF' | 'ADMIN';

export interface AuthUser {
  id: string;
  email: string;
  role: Role;
  fullName?: string;
  phone?: string;
  avatar?: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface LoginResponse extends AuthTokens {
  user: AuthUser;
}
