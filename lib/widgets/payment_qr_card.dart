import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'countdown_timer.dart';

// Anh QR nen trang: anh trong suot co the khong quet duoc khi chon tu thu vien trong app ngan hang
Future<Uint8List> paymentQrPng(String data) async {
  const size = 800.0;
  const padding = 48.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(Colors.white, BlendMode.src);
  canvas.translate(padding, padding);
  QrPainter(data: data, version: QrVersions.auto, gapless: true).paint(canvas, const Size.square(size - 2 * padding));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

// Luu vao thu vien anh de khach chi co mot dien thoai van chon anh nay trong app ngan hang
Future<void> savePaymentQr(String data, String name) async {
  if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
    throw Exception('Chưa được cấp quyền lưu ảnh.');
  }
  await Gal.putImageBytes(await paymentQrPng(data), name: name);
}

// Ma VietQR cua payOS hien ngay tren man thanh toan, kem so tien va thoi gian con lai
class PaymentQrCard extends StatelessWidget {
  const PaymentQrCard({super.key, required this.data, required this.amount, this.expiresAt, this.onExpire});

  final String data;
  final double amount;
  final DateTime? expiresAt;
  final VoidCallback? onExpire;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Text(
                'Quét mã bằng ứng dụng ngân hàng',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                label: 'Mã QR thanh toán',
                image: true,
                child: QrImageView(
                  key: const Key('payment-qr'),
                  data: data,
                  size: 260,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                formatVnd(amount),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
              ),
              if (expiresAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                CountdownTimer(expiresAt: expiresAt!, onExpire: onExpire),
              ],
            ],
          ),
        ),
      );
}
