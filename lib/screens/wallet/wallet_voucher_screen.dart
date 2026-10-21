import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/wallet_provider.dart';
import '../../routes.dart';
import '../../services/api_client.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../engage/review_screen.dart';
import 'wallet_screen.dart';

// Chi tiet voucher da mua (FR-REDEEM-01): tao ma su dung, chi nhanh ap dung, lan su dung,
// hoan tien kem han chot hoac ly do khong du dieu kien (FR-REFUND-04/07), danh gia (BR-10).
// Mat mang: van hien thong tin co trong vi da luu, an nut tao ma (LIM-07).
class WalletVoucherScreen extends StatefulWidget {
  const WalletVoucherScreen({super.key, required this.voucher});

  // Thong tin co san tu vi (hien ngay, ke ca khi mat mang)
  final VoucherItem voucher;

  @override
  State<WalletVoucherScreen> createState() => _WalletVoucherScreenState();
}

class _WalletVoucherScreenState extends State<WalletVoucherScreen> {
  WalletVoucherDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await context.read<OrderService>().walletDetail(widget.voucher.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _offline = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _offline = e.isNetworkError;
          _error = e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Quay lai tu man hoan tien / tao ma / danh gia: tai lai chi tiet va vi
  Future<void> _open(String route, Object arguments) async {
    await AppRoutes.push(context, route, arguments: arguments);
    if (!mounted) return;
    context.read<WalletProvider>().load();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final v = _detail?.voucher ?? widget.voucher;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết voucher')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (_offline) ...[
              OfflineBanner(cachedAt: context.read<WalletProvider>().cachedAt),
              const SizedBox(height: AppSpacing.sm),
            ] else if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ],
            _Header(voucher: v),
            const SizedBox(height: AppSpacing.md),
            _UseSection(voucher: v, offline: _offline, onUse: () => _open(AppRoutes.redeemQr, v)),
            if (_loading && _detail == null) const LoadingState(),
            if (_detail?.redemption != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SectionCard(
                title: 'Đã sử dụng',
                child: Text(
                  'Lúc ${formatDateTime(_detail!.redemption!.redeemedAt)}'
                  '${_detail!.redemption!.storeName == null ? '' : ' tại ${_detail!.redemption!.storeName}'}',
                ),
              ),
            ],
            if (_detail != null && _detail!.stores.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SectionCard(
                title: 'Chi nhánh áp dụng',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in _detail!.stores)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.store_outlined),
                        title: Text(s.name),
                        subtitle: Text([s.address, if (s.openingHours != null) s.openingHours!].join('\n')),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _RefundSection(
              voucher: v,
              requests: _detail?.refundRequests ?? const [],
              offline: _offline,
              onRequest: () => _open(AppRoutes.refundRequest, v),
              onTrack: () => AppRoutes.push(context, AppRoutes.refundList),
            ),
            if (v.effectiveStatus == 'USED') ...[
              const SizedBox(height: AppSpacing.sm),
              SectionCard(
                title: 'Đánh giá',
                child: v.canReview
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _open(AppRoutes.review, ReviewArgs.fromVoucher(v)),
                          icon: const Icon(Icons.star_outline),
                          label: const Text('Viết đánh giá'),
                        ),
                      )
                    : Text(v.hasReviewed ? 'Bạn đã đánh giá chiến dịch này.' : 'Chưa thể đánh giá.'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.voucher});

  final VoucherItem voucher;

  @override
  Widget build(BuildContext context) {
    final c = voucher.campaign;
    const muted = TextStyle(color: AppColors.textSecondary);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(c?.title ?? 'Voucher', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                StatusChip(voucher.effectiveStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (c != null) Text('Giá trị: ${formatVnd(c.faceValue)}', style: muted),
            Text('Mã tra cứu: ${voucher.code}', style: muted),
            Text('Ngày mua: ${formatDateTime(voucher.issuedAt)}', style: muted),
            Text('Hạn sử dụng: ${formatDateTime(voucher.expireAt)}', style: muted),
          ],
        ),
      ),
    );
  }
}

class _UseSection extends StatelessWidget {
  const _UseSection({required this.voucher, required this.offline, required this.onUse});

  final VoucherItem voucher;
  final bool offline;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    if (!voucher.canRedeem) {
      final reason = switch (voucher.effectiveStatus) {
        'REFUND_PENDING' => 'Voucher đang chờ hoàn tiền nên tạm thời không sử dụng được.',
        'USED' => 'Voucher đã được sử dụng.',
        'REFUNDED' => 'Voucher đã được hoàn tiền.',
        _ => 'Voucher đã hết hạn sử dụng.',
      };
      return Text(reason, key: const Key('use-disabled-reason'), style: const TextStyle(color: AppColors.textSecondary));
    }
    if (offline) {
      return const Text(
        'Cần kết nối mạng để tạo mã QR / OTP sử dụng voucher.',
        key: Key('use-offline-reason'),
        style: TextStyle(color: AppColors.danger),
      );
    }
    return PrimaryButton(label: 'Sử dụng ngay', onPressed: onUse);
  }
}

// FR-REFUND-04/07: hien han chot hoan; khong du dieu kien thi khoa nut va noi ly do
class _RefundSection extends StatelessWidget {
  const _RefundSection({
    required this.voucher,
    required this.requests,
    required this.offline,
    required this.onRequest,
    required this.onTrack,
  });

  final VoucherItem voucher;
  final List<RefundRequest> requests;
  final bool offline;
  final VoidCallback onRequest;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final eligibility = voucher.refund;
    final deadline = eligibility?.refundableUntil ?? voucher.refundableUntil;
    final canRefund = eligibility?.canRefund ?? false;
    return SectionCard(
      title: 'Hoàn tiền',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deadline != null)
            Text('Hạn chót yêu cầu hoàn tiền: ${formatDateTime(deadline)}', key: const Key('refund-deadline')),
          const Text(
            'Áp dụng cho voucher chưa sử dụng, trong 7 ngày kể từ khi mua và còn ít nhất 3 ngày trước hạn sử dụng (BR-05).',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('refund-button'),
              onPressed: canRefund && !offline ? onRequest : null,
              icon: const Icon(Icons.currency_exchange),
              label: const Text('Yêu cầu hoàn tiền'),
            ),
          ),
          if (!canRefund && eligibility?.reason != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(eligibility!.reason!, key: const Key('refund-blocked-reason'), style: const TextStyle(color: AppColors.danger)),
            )
          else if (canRefund && offline)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Text('Cần kết nối mạng để gửi yêu cầu hoàn tiền.', style: TextStyle(color: AppColors.danger)),
            ),
          for (final r in requests.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(r.statusLabel),
              subtitle: Text([
                'Gửi lúc ${formatDateTime(r.createdAt)}',
                if (r.rejectReason != null) r.rejectReason!,
              ].join('\n')),
            ),
          if (requests.isNotEmpty)
            TextButton(onPressed: onTrack, child: const Text('Theo dõi tất cả yêu cầu hoàn tiền')),
        ],
      ),
    );
  }
}
