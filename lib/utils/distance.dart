import 'dart:math';

// Tinh khoang cach giua toa do khach hang va chi nhanh (cong thuc Haversine)
// Phuc vu tinh nang "gan toi" - FR-SEARCH-05/06
const _earthRadiusKm = 6371.0;

double _toRad(double deg) => deg * pi / 180;

double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return _earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// Cac muc ban kinh loc theo FR-SEARCH-05: 1km, 3km, 5km, 10km
const radiusOptionsKm = [1, 3, 5, 10];

String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}
