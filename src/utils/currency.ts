// Dinh dang tien te VND, khong co phan thap phan - CON-06, NFR-USA-04
export function formatVND(amount: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0,
  }).format(amount);
}

// Hien thi theo mui gio Asia/Ho_Chi_Minh, du lieu luu tru la UTC - CON-05
export function formatDateTime(iso: string): string {
  return new Intl.DateTimeFormat('vi-VN', {
    timeZone: 'Asia/Ho_Chi_Minh',
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(iso));
}
