import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

// F16: bat / tat tung nhom thong bao (NotificationSetting). May chu bo qua nhom da tat (FR-ENGAGE-07).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<NotificationProvider>().loadSettings();
  }

  Future<void> _toggle(String type, bool enabled) async {
    try {
      await context.read<NotificationProvider>().toggleSetting(type, enabled);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<NotificationProvider>().settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingState();
          if (snap.hasError) return ErrorState(snap.error.toString());
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text('Chọn những thông báo bạn muốn nhận.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              for (final s in settings)
                SwitchListTile(
                  key: ValueKey('setting-${s.type}'),
                  title: Text(s.label),
                  value: s.enabled,
                  onChanged: (v) => _toggle(s.type, v),
                ),
            ],
          );
        },
      ),
    );
  }
}
