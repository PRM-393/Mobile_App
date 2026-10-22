import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/engage.dart';
import '../../providers/main_tab_controller.dart';
import '../../providers/notification_provider.dart';
import '../../routes.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../checkout/payment_result_screen.dart';

// FR-ENGAGE-06: danh sach thong bao (da doc / chua doc); bam thong bao mo dung man hinh
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationProvider>().load());
  }

  // data cua thong bao quyet dinh man hinh can mo
  Future<void> _open(AppNotification n) async {
    final provider = context.read<NotificationProvider>();
    await provider.markRead(n);
    if (!mounted) return;
    final orderId = n.data['orderId'] as String?;
    final campaignId = n.data['campaignId'] as String?;
    if (orderId != null) {
      try {
        final order = await context.read<OrderService>().getOrder(orderId);
        if (!mounted) return;
        await AppRoutes.push(context, AppRoutes.paymentResult, arguments: PaymentResultArgs(order: order));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } else if (n.data['refundId'] != null) {
      await AppRoutes.push(context, AppRoutes.refundList);
    } else if (n.data['voucherItemId'] != null) {
      context.read<MainTabController>().go(MainTabController.wallet);
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (campaignId != null) {
      await AppRoutes.push(context, AppRoutes.voucherDetail, arguments: campaignId);
    }
  }

  IconData _icon(String type) => switch (type) {
        'VOUCHER_ISSUED' => Icons.card_giftcard,
        'VOUCHER_USED' => Icons.qr_code_2,
        'REFUND_RESULT' => Icons.currency_exchange,
        'VOUCHER_EXPIRING' => Icons.timer_outlined,
        'CAMPAIGN_NEW' => Icons.campaign_outlined,
        _ => Icons.notifications_none,
      };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (provider.unread > 0)
            TextButton(onPressed: provider.markAllRead, child: const Text('Đọc tất cả')),
          IconButton(
            tooltip: 'Cài đặt thông báo',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => AppRoutes.push(context, AppRoutes.notificationSettings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: Builder(builder: (context) {
          if (provider.loading && provider.items.isEmpty) return const LoadingState();
          if (provider.error != null) return ErrorState(provider.error!, onRetry: provider.load);
          if (provider.items.isEmpty) {
            return ListView(children: const [EmptyState('Chưa có thông báo nào.', icon: Icons.notifications_none)]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: provider.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final n = provider.items[i];
              return Card(
                key: ValueKey(n.id),
                // Thong bao chua doc: nen primarySoft + chamter teal
                color: n.isRead ? null : AppColors.primarySoft,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(n),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: n.isRead
                                ? AppColors.background
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _icon(n.type),
                            size: 21,
                            color: n.isRead
                                ? AppColors.textSecondary
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: n.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatDateTime(n.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            margin: const EdgeInsets.only(left: AppSpacing.sm, top: 4),
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
