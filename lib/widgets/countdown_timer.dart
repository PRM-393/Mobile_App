import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Dem nguoc hieu luc token QR (60 giay) - FR-REDEEM-02; goi onExpire khi het han de lam moi ma
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.expiresAt, this.onExpire, this.now = DateTime.now});

  final DateTime expiresAt;
  final VoidCallback? onExpire;
  final DateTime Function() now;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late int _remaining;

  int _secondsLeft() {
    final s = widget.expiresAt.difference(widget.now()).inSeconds;
    return s < 0 ? 0 : s;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) _start();
  }

  void _start() {
    _timer?.cancel();
    _remaining = _secondsLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _secondsLeft();
      setState(() => _remaining = next);
      if (next <= 0) {
        timer.cancel();
        widget.onExpire?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        _remaining > 0 ? 'Còn hiệu lực ${_remaining}s' : 'Đã hết hạn',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _remaining <= 10 ? AppColors.danger : AppColors.textPrimary,
        ),
      );
}
