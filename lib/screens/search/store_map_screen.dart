import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/campaign.dart';
import '../../services/voucher_services.dart';
import '../../utils/distance.dart';

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
    appBar: AppBar(title: const Text('Bản đồ chi nhánh')),
    body: FutureBuilder<List<Store>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Không tải được chi nhánh.'),
                TextButton(
                  onPressed: () => setState(() => _future = load()),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final stores = snapshot.data!;
        if (stores.isEmpty) {
          return const Center(
            child: Text(
              'Không có chi nhánh phù hợp. Hãy đổi bộ lọc hoặc tải thêm kết quả.',
            ),
          );
        }
        final selected = _selected ?? stores.first;
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Chi nhánh của các voucher đã tải. Chạm ghim để xem và chỉ đường.',
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
                                  ? Colors.red
                                  : Colors.teal,
                              size: 36,
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
            SafeArea(
              child: ListTile(
                title: Text(selected.name),
                subtitle: Text(selected.address),
                trailing: IconButton(
                  tooltip: 'Chỉ đường',
                  onPressed: () => directions(selected),
                  icon: const Icon(Icons.directions),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
