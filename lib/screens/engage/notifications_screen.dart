import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/engage.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

// FR-ENGAGE-06: thong bao nhan duoc (phat hanh voucher, sap het han, ket qua hoan tien...)
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<EngageService>().myNotifications();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thông báo')),
        body: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const LoadingState();
            if (snap.hasError) return ErrorState(snap.error.toString());
            final items = snap.data!;
            if (items.isEmpty) return const EmptyState('Chưa có thông báo nào.', icon: Icons.notifications_none);
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final n = items[i];
                return Card(
                  child: ListTile(
                    leading: Icon(n.readAt == null ? Icons.circle_notifications : Icons.notifications_none,
                        color: n.readAt == null ? AppColors.primary : AppColors.textSecondary),
                    title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${n.body}\n${formatDateTime(n.createdAt)}'),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      );
}
