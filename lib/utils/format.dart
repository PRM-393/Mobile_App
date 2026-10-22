import 'package:intl/intl.dart';

final _vnd = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);
final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

// Dinh dang tien te VND, khong co phan thap phan - CON-06, NFR-USA-04
String formatVnd(num amount) => _vnd.format(amount);

// Du lieu luu UTC, hien thi theo mui gio Asia/Ho_Chi_Minh (UTC+7, khong co gio mua he) - CON-05
String formatDateTime(DateTime value) =>
    _dateTime.format(value.toUtc().add(const Duration(hours: 7)));

final _dateOnly = DateFormat('dd/MM/yyyy');

// Chi ngay (dung cho han su dung voucher tren the) - theo mui gio UTC+7
String formatDate(DateTime value) =>
    _dateOnly.format(value.toUtc().add(const Duration(hours: 7)));
