import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/campaign.dart';
import '../../services/voucher_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance.dart';
import '../../widgets/common.dart';

// F04: active campaign stores only; location is optional and directions use an external map.
class StoreMapScreen extends StatefulWidget {
  const StoreMapScreen({
    super.key,
    this.campaigns = const [],
    this.stores = const [],
    this.latitude,
    this.longitude,
    this.radiusKm,
  });
  final List<VoucherCampaign> campaigns;
  final List<Store> stores;
  final double? latitude, longitude;
  final int? radiusKm;
  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  late Future<List<Store>> _future;
  Store? _selected;
  @override
  void initState() {
    super.initState();
    _future = load();
  }

  Future<List<Store>> load() async {
    final stores = <String, Store>{for (final s in widget.stores) s.id: s};
    final service = context.read<SearchService>();
    // Keep network concurrency bounded; reload is available if any detail request fails.
    for (var i = 0; i < widget.campaigns.length; i += 4) {
      final group = widget.campaigns.skip(i).take(4);
      final details = await Future.wait(
        group.map(
          (c) =>
              service.detail(c.id, lat: widget.latitude, lng: widget.longitude),
        ),
      );
      for (final c in details) {
        for (final s in c.stores) {
          stores[s.id] = s;
        }
      }
    }
    return stores.values
        .where(
          (s) =>
              s.latitude.abs() <= 90 &&
              s.longitude.abs() <= 180 &&
              (widget.radiusKm == null ||
                  widget.latitude == null ||
                  distanceKm(
                        widget.latitude!,
                        widget.longitude!,
                        s.latitude,
                        s.longitude,
                      ) <=
                      widget.radiusKm!),
        )
        .toList();
  }

  Future<void> directions(Store s) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${s.latitude},${s.longitude}',
    });
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Không mở được bản đồ');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không mở được chỉ đường. Vui lòng thử lại.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bản đồ cửa hàng')),
    body: FutureBuilder<List<Store>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingState();
        }
        if (snapshot.hasError) {
          return ErrorState(
            'Không tải được chi nhánh.',
            onRetry: () => setState(() => _future = load()),
          );
        }
        final stores = snapshot.data!;
        if (stores.isEmpty) {
          return const EmptyState(
            'Không có chi nhánh phù hợp. Hãy đổi bộ lọc hoặc tải thêm kết quả.',
            icon: Icons.storefront_outlined,
          );
        }
        final selected = _selected ?? stores.first;
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: InfoBanner(
                'Cửa hàng của các voucher đã tải. Chạm ghim để xem và chỉ đường.',
                icon: Icons.touch_app_outlined,
              ),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    widget.latitude ?? selected.latitude,
                    widget.longitude ?? selected.longitude,
                  ),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.prm393.voucher_platform_mobile',
                  ),
                  MarkerLayer(
                    markers: [
                      if (widget.latitude != null)
                        Marker(
                          point: LatLng(widget.latitude!, widget.longitude!),
                          width: 28,
                          height: 28,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                          ),
                        ),
                      for (final s in stores)
                        Marker(
                          point: LatLng(s.latitude, s.longitude),
                          width: 48,
                          height: 48,
                          child: IconButton(
                            tooltip: s.name,
                            onPressed: () => setState(() => _selected = s),
                            icon: Icon(
                              Icons.location_on,
                              color: selected.id == s.id
                                  ? AppColors.danger
                                  : AppColors.primary,
                              size: selected.id == s.id ? 42 : 34,
                            ),
                          ),
                        ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // The thong tin cua hang dang chon, dang bottom sheet
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lgSheet),
                ),
                boxShadow: appCardShadow,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandAvatar(
                        size: 48,
                        icon: Icons.storefront_outlined,
                      ),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selected.address,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            if (selected.distanceKm != null)
                              Text(
                                formatDistance(selected.distanceKm!),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                        ),
                        onPressed: () => directions(selected),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Chỉ đường'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
