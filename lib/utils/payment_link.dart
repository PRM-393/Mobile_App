import 'package:url_launcher/url_launcher.dart';

// Mo trang thanh toan payOS bang trinh duyet. Khong nem loi: don da tao roi, mo khong duoc thi man ket qua
// van co nut mo lai; neu nem loi o man mua hang, khach bam mua lan nua se tao trung don.
Future<bool> openPaymentLink(String? url) async {
  final uri = Uri.tryParse(url ?? '');
  if (uri == null || !uri.hasScheme) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
