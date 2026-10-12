// Cot numeric/bigint cua PostgreSQL duoc TypeORM tra ve dang chuoi, nen phai nhan ca num lan String
double asDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  return fallback;
}

double? asDoubleOrNull(Object? value) => value == null ? null : asDouble(value);

DateTime asDate(Object? value) =>
    value is String ? DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0);

DateTime? asDateOrNull(Object? value) => value is String ? DateTime.tryParse(value) : null;

List<T> asList<T>(Object? value, T Function(Map<String, dynamic>) fromJson) =>
    value is List ? value.whereType<Map<String, dynamic>>().map(fromJson).toList() : <T>[];
