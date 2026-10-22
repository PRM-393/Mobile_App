import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// The voucher/chien dich dung o man Kham pha, Tim kiem - FR-SEARCH-*
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
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: campaign.image == null || campaign.image!.isEmpty
                        ? Container(
                            color: AppColors.border,
                            child: const Icon(
                              Icons.local_offer_outlined,
                              color: AppColors.textSecondary,
                              size: 36,
                            ),
                          )
                        // Module 12: giai ma anh vua kich thuoc the (~240 dp) thay vi do phan giai goc
                        : Image.network(
                            campaign.image!,
                            fit: BoxFit.cover,
                            cacheWidth:
                                (MediaQuery.devicePixelRatioOf(context) * 240)
                                    .round(),
                            errorBuilder: (_, _, _) =>
                                Container(color: AppColors.border),
                          ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: soldOut
                            ? AppColors.textPrimary
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        soldOut
                            ? 'HẾT HÀNG'
                            : '-${campaign.savingPercent ?? 0}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          formatVnd(campaign.salePrice),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        if (campaign.savingPercent != null &&
                            campaign.savingPercent! > 0)
                          Text(
                            '-${campaign.savingPercent}%',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: soldOut
                              ? AppColors.textSecondary
                              : AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            soldOut
                                ? 'Đã bán hết'
                                : 'Đã bán ${campaign.soldQuantity}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (distanceLabel != null)
                      Text(
                        distanceLabel!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
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
