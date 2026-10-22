import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

// The voucher/chien dich dung o man Kham pha, Tim kiem - FR-SEARCH-*
// Hai bien the: dang doc (danh sach) va dang cot (bang ngang cuon, khi truyen `width`)
class VoucherCard extends StatelessWidget {
  const VoucherCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.distanceLabel,
    this.width,
  });

  final VoucherCampaign campaign;
  final VoidCallback? onTap;
  final String? distanceLabel;
  final double? width;

  bool get _soldOut => campaign.availableQuantity == 0;

  // Dong phu: han su dung + khoang cach (neu co)
  String get _metaLabel {
    final parts = <String>['HSD ${formatDate(campaign.voucherExpireAt)}'];
    if (distanceLabel != null && distanceLabel!.isNotEmpty) {
      parts.add(distanceLabel!);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: width == null ? _buildRow(context) : _buildColumn(context),
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }

  // Bien the danh sach doc: logo thuong hieu ben trai, thong tin ben phai
  Widget _buildRow(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandAvatar(imageUrl: campaign.image, size: 64),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(),
              const SizedBox(height: 6),
              _priceRow(),
              const SizedBox(height: 6),
              _metaRow(),
            ],
          ),
        ),
      ],
    ),
  );

  // Bien the the ngang: anh bia tren, thong tin duoi
  Widget _buildColumn(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: campaign.image == null || campaign.image!.isEmpty
                ? Container(
                    color: AppColors.primarySoft,
                    child: const Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  )
                // Module 12: giai ma anh vua kich thuoc the (~240 dp) thay vi do phan giai goc
                : Image.network(
                    campaign.image!,
                    fit: BoxFit.cover,
                    cacheWidth: (MediaQuery.devicePixelRatioOf(context) * 240)
                        .round(),
                    errorBuilder: (_, _, _) =>
                        Container(color: AppColors.primarySoft),
                  ),
          ),
          Positioned(left: 10, top: 10, child: _savingBadge()),
        ],
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(),
            const SizedBox(height: 6),
            _priceRow(showBadge: false),
            const SizedBox(height: 6),
            _metaRow(),
          ],
        ),
      ),
    ],
  );

  Widget _title() => Text(
    campaign.title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 15,
      height: 1.3,
      color: AppColors.textPrimary,
    ),
  );

  // Gia ban dam mau teal, gia goc gach ngang, badge % giam mau amber
  Widget _priceRow({bool showBadge = true}) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        formatVnd(campaign.salePrice),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
      if (campaign.faceValue > campaign.salePrice)
        Text(
          formatVnd(campaign.faceValue),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      if (showBadge) _savingBadge(),
    ],
  );

  Widget _savingBadge() {
    if (_soldOut) {
      return const StatusPill('HẾT HÀNG', tone: StatusTone.neutral);
    }
    final percent = campaign.savingPercent;
    if (percent == null || percent <= 0) {
      return StatusPill(
        voucherTypeLabels[campaign.voucherType] ?? 'Ưu đãi',
        tone: StatusTone.primary,
      );
    }
    return StatusPill('-$percent%', tone: StatusTone.warning);
  }

  Widget _metaRow() => Row(
    children: [
      const Icon(
        Icons.event_available_outlined,
        size: 13,
        color: AppColors.textSecondary,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          _metaLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
      if (!_soldOut && campaign.soldQuantity > 0) ...[
        const Icon(
          Icons.local_fire_department_rounded,
          size: 13,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 2),
        Text(
          'Đã bán ${campaign.soldQuantity}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    ],
  );
}
