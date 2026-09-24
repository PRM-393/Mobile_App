import { create } from 'zustand';

interface CartState {
  campaignId: string | null;
  quantity: number;
  setItem: (campaignId: string, quantity: number) => void;
  clear: () => void;
}

// Gio hang don gian: mot chien dich tai mot thoi diem (checkout truc tiep tu man hinh chi tiet)
export const useCartStore = create<CartState>((set) => ({
  campaignId: null,
  quantity: 1,
  setItem: (campaignId, quantity) => set({ campaignId, quantity }),
  clear: () => set({ campaignId: null, quantity: 1 }),
}));
