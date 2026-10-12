import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// The voucher/chien dich dung o man Kham pha, Tim kiem - FR-SEARCH-*
class VoucherCard extends StatelessWidget {
  const VoucherCard({super.key, required this.campaign, this.onTap, this.distanceLabel, this.width});

  final VoucherCampaign campaign;
  final VoidCallback? onTap;
  final String? distanceLabel;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final soldOut = campaign.availableQuantity == 0;
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: campaign.image == null || campaign.image!.isEmpty
                    ? Container(
                        color: AppColors.border,
                        child: const Icon(Icons.local_offer_outlined, color: AppColors.textSecondary, size: 36),
                      )
                    : Image.network(campaign.image!, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(color: AppColors.border)),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(formatVnd(campaign.salePrice),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        if (campaign.discountPercent != null && campaign.discountPercent! > 0)
                          Text('-${campaign.discountPercent!.toStringAsFixed(0)}%',
                              style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (soldOut)
                      const Text('Hết hàng', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    if (distanceLabel != null)
                      Text(distanceLabel!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
