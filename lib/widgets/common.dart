import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Trang thai rong / loi / dang tai dung chung cho cac danh sach (Module 8: loading - empty - error)
// Theo design system: icon lon trong vong tron mo, 1 dong mo ta, button hanh dong (tuy chon)
class EmptyState extends StatelessWidget {
  const EmptyState(
    this.message, {
    super.key,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: 220,
            child: FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState(this.message, {super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColors.dangerSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            size: 40,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.45),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ],
    ),
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.xl),
    child: Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  );
}

// Nut chinh co trang thai dang xu ly
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.danger = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: danger
        ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
        : null,
    child: loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
  );
}

// Khoi noi dung trong card trang: tieu de dam + phan noi dung
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    ),
  );
}

// Tieu de cua mot nhom noi dung tren nen man hinh (vd "Ưu đãi nổi bật")
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
      if (actionLabel != null && onAction != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

// Nhan trang thai dang vien thuoc (don hang, voucher trong vi, hoan tien)
enum StatusTone { primary, success, warning, danger, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = StatusTone.neutral, this.icon});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  Color get _bg => switch (tone) {
    StatusTone.primary => AppColors.primarySoft,
    StatusTone.success => AppColors.successSoft,
    StatusTone.warning => AppColors.secondarySoft,
    StatusTone.danger => AppColors.dangerSoft,
    StatusTone.neutral => AppColors.background,
  };

  Color get _fg => switch (tone) {
    StatusTone.primary => AppColors.primaryDark,
    StatusTone.success => AppColors.success,
    StatusTone.warning => const Color(0xFF9A5B00),
    StatusTone.danger => AppColors.danger,
    StatusTone.neutral => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: _fg),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: _fg,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

// The tong quan nen gradient teal (dung o Vi voucher, Ca nhan)
class GradientHeaderCard extends StatelessWidget {
  const GradientHeaderCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      gradient: appHeaderGradient,
      borderRadius: BorderRadius.circular(AppRadius.card),
      boxShadow: appCardShadow,
    ),
    child: child,
  );
}

// Hop thong tin nen nhat kem icon (luu y, chinh sach hoan tien...)
class InfoBanner extends StatelessWidget {
  const InfoBanner(
    this.message, {
    super.key,
    this.icon = Icons.info_outline,
    this.tone = StatusTone.primary,
  });

  final String message;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final pill = StatusPill('', tone: tone);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: pill._bg,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: pill._fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.4, color: pill._fg),
            ),
          ),
        ],
      ),
    );
  }
}

// Mot dong "nhan: gia tri" trong the chi tiet (don hang, thanh toan)
class DetailRow extends StatelessWidget {
  const DetailRow(
    this.label,
    this.value, {
    super.key,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 15 : 13,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: emphasize ? 18 : 13,
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
            color: valueColor ??
                (emphasize ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}

// Thanh hanh dong co dinh duoi man hinh (Mua ngay, Xac nhan thanh toan)
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm + 4,
      AppSpacing.md,
      MediaQuery.paddingOf(context).bottom + AppSpacing.sm + 4,
    ),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: child,
  );
}

// O chua logo thuong hieu bo goc, co fallback khi khong co anh
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({super.key, this.imageUrl, this.size = 56, this.icon});

  final String? imageUrl;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 3.5);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: radius),
      child: Icon(
        icon ?? Icons.local_offer_outlined,
        color: AppColors.primary,
        size: size * 0.45,
      ),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Module 12: giai ma anh vua kich thuoc hien thi
        cacheWidth: (MediaQuery.devicePixelRatioOf(context) * size).round(),
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}
