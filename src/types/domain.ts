// Kieu du lieu doi tuong nghiep vu, khop voi entity BE (SRS muc 7)

export type CampaignStatus = 'DRAFT' | 'PENDING' | 'APPROVED' | 'PUBLISHED' | 'PAUSED' | 'ENDED';
export type VoucherType = 'DISCOUNT_CODE' | 'PREPAID_VALUE' | 'COMBO';
export type VoucherItemStatus = 'ACTIVE' | 'USED' | 'REFUNDED' | 'EXPIRED';
export type OrderStatus = 'PENDING' | 'PAID' | 'CANCELLED' | 'FULFILLED' | 'REFUNDED_OVERSOLD';
export type RefundStatus = 'REQUESTED' | 'PROCESSING' | 'REJECTED' | 'MANUAL_PENDING' | 'COMPLETED';

export interface Category {
  id: string;
  name: string;
  icon?: string;
}

export interface Store {
  id: string;
  brandId: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  distanceKm?: number;
}

export interface VoucherCampaign {
  id: string;
  brandId: string;
  title: string;
  image?: string;
  description?: string;
  terms?: string;
  voucherType: VoucherType;
  salePrice: number;
  faceValue: number;
  discountPercent?: number;
  totalQuantity: number;
  soldQuantity: number;
  reservedQuantity: number;
  saleStartAt: string;
  saleEndAt: string;
  voucherExpireAt: string;
  status: CampaignStatus;
}

export interface Order {
  id: string;
  campaignId: string;
  quantity: number;
  totalAmount: number;
  status: OrderStatus;
  createdAt: string;
}

export interface VoucherItem {
  id: string;
  orderId: string;
  campaignId: string;
  code: string;
  status: VoucherItemStatus;
  issuedAt: string;
  usedAt?: string;
  expireAt: string;
}

export interface RedeemTokenResponse {
  qrPayload: string;
  otpCode: string;
  expiresAt: string;
  ttlSeconds: number;
}

export interface RefundRequest {
  id: string;
  voucherItemId: string;
  status: RefundStatus;
  reason?: string;
  rejectReason?: string;
  createdAt: string;
}
