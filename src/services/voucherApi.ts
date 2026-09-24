import { apiClient } from './apiClient';
import type { Category, Order, RedeemTokenResponse, RefundRequest, VoucherCampaign, VoucherItem } from '@/types/domain';

// FR-SEARCH-*
export const searchApi = {
  categories: () => apiClient.get<Category[]>('/categories').then((r) => r.data),
  search: (params: Record<string, unknown>) =>
    apiClient.get<{ items: VoucherCampaign[]; total: number }>('/vouchers', { params }).then((r) => r.data),
  detail: (id: string) => apiClient.get<VoucherCampaign>(`/vouchers/${id}`).then((r) => r.data),
};

// FR-ORDER-*
export const orderApi = {
  create: (campaignId: string, quantity: number) =>
    apiClient.post('/orders', { campaignId, quantity }).then((r) => r.data),
  myOrders: () => apiClient.get<Order[]>('/orders/me').then((r) => r.data),
};

// FR-REDEEM-*
export const redeemApi = {
  requestToken: (voucherItemId: string) =>
    apiClient.post<RedeemTokenResponse>('/redeem/token', { voucherItemId }).then((r) => r.data),
};

// FR-REFUND-*
export const refundApi = {
  request: (voucherItemId: string, reason?: string) =>
    apiClient.post<RefundRequest>('/refunds', { voucherItemId, reason }).then((r) => r.data),
  myRequests: () => apiClient.get<RefundRequest[]>('/refunds/me').then((r) => r.data),
};

// FR-ENGAGE-*
export const engageApi = {
  toggleFavorite: (targetType: 'BRAND' | 'CAMPAIGN', targetId: string) =>
    apiClient.post('/favorites', { targetType, targetId }).then((r) => r.data),
  myFavorites: () => apiClient.get('/favorites/me').then((r) => r.data),
  createReview: (voucherItemId: string, rating: number, comment?: string) =>
    apiClient.post('/reviews', { voucherItemId, rating, comment }).then((r) => r.data),
  myNotifications: () => apiClient.get('/notifications/me').then((r) => r.data),
  registerDeviceToken: (token: string, platform: 'android' | 'ios') =>
    apiClient.post('/notifications/device-token', { token, platform }).then((r) => r.data),
};

// TODO(voucher wallet): endpoint tra ve VoucherItem cua toi chia theo tab (dang hieu luc / da dung /
// het han / da hoan) chua co trong BE scaffold; can bo sung GET /wallet o module redeem hoac order.
export const walletApi = {
  myVouchers: () => apiClient.get<VoucherItem[]>('/wallet').then((r) => r.data),
};
