import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/main_tab_controller.dart';
import '../providers/wallet_provider.dart';
import '../routes.dart';
import '../screens/checkout/payment_result_screen.dart';
import '../services/voucher_services.dart';

// Mo dung man hinh theo du lieu cua thong bao. Dung chung cho danh sach thong bao trong app
// va khi khach bam thong bao tren thanh trang thai.
Future<void> openNotificationTarget(BuildContext context, String type, Map<String, dynamic> data) async {
  final orderId = data['orderId'] as String?;
  final campaignId = data['campaignId'] as String?;
  if (orderId != null) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final order = await context.read<OrderService>().getOrder(orderId);
      if (!context.mounted) return;
      await AppRoutes.push(context, AppRoutes.paymentResult, arguments: PaymentResultArgs(order: order));
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  } else if (data['refundId'] != null) {
    await AppRoutes.push(context, AppRoutes.refundList);
  } else if (data['voucherItemId'] != null) {
    context.read<WalletProvider?>()?.selectTab(type == 'VOUCHER_USED' ? 'USED' : 'ACTIVE');
    context.read<MainTabController>().go(MainTabController.wallet);
    Navigator.of(context).popUntil((route) => route.isFirst);
  } else if (campaignId != null) {
    await AppRoutes.push(context, AppRoutes.voucherDetail, arguments: campaignId);
  }
}

// Bam thong bao tren thanh trang thai: payload la JSON {type, ...data}; thieu / hong thi chi mo app
Future<void> openNotificationPayload(String? payload) async {
  final context = AppRoutes.navigatorKey.currentContext;
  if (payload == null || context == null) return;
  try {
    final json = Map<String, dynamic>.from(jsonDecode(payload) as Map);
    await openNotificationTarget(context, json['type'] as String? ?? '', json);
  } on FormatException {
    // khong phai JSON
  }
}
