import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/campaign.dart';
import '../services/preferences_service.dart';
import '../services/voucher_services.dart';

// F03/F04: filters, 20-item pagination, latest-query-wins and denied-location fallback.
class SearchProvider extends ChangeNotifier {
  SearchProvider(this._searchService, {this._preferences, this.locate});
  final SearchService _searchService;
  final PreferencesService? _preferences;
  final Future<Position?> Function()? locate;
  String _keyword = '';
  int? _radiusKm;
  Position? _position;
  bool _locationDenied = false, _loading = false, _loadingMore = false;
  String? _error;
  List<VoucherCampaign> _results = const [];
  int _page = 0, _total = 0, _generation = 0;
  bool _disposed = false;
  String? categoryId;
  String sort = 'newest';
  int? minPrice, maxPrice;
  double? minDiscount, maxDiscount;
  String get keyword => _keyword;
  int? get radiusKm => _radiusKm;
  bool get hasLocation => _position != null;
  double? get latitude => _position?.latitude;
  double? get longitude => _position?.longitude;
  bool get locationDenied => _locationDenied;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _results.length < _total;
  int get total => _total;
  String? get error => _error;
  List<VoucherCampaign> get results => _results;
  List<String> get recentKeywords => _preferences?.recentKeywords ?? const [];
  void emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  Future<void> clearRecentKeywords() async {
    await _preferences?.clearRecentKeywords();
    emit();
  }

  Future<void> setKeyword(String value) async {
    _keyword = value.trim();
    await _preferences?.addRecentKeyword(_keyword);
    await search();
  }

  Future<void> setRadius(int? km) async {
    if (km != null && _position == null && !await ensureLocation()) {
      _radiusKm = null;
      if (sort == 'distance_asc') sort = 'newest';
      await search();
      return;
    }
    _radiusKm = km;
    if (km != null) {
      sort = 'distance_asc';
    } else if (sort == 'distance_asc') {
      sort = 'newest';
    }
    await search();
  }

  Future<bool> ensureLocation() async {
    try {
      if (locate != null) {
        _position = await locate!();
      } else {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw StateError('Location disabled');
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw StateError('Location denied');
        }
        _position = await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 15),
        );
      }
      _locationDenied = _position == null;
    } catch (_) {
      _position = null;
      _locationDenied = true;
    }
    emit();
    return _position != null;
  }

  Future<void> search() => _load(false);
  Future<void> loadMore() async {
    if (!_loading && !_loadingMore && hasMore) await _load(true);
  }

  Future<void> _load(bool append) async {
    final generation = append ? _generation : ++_generation;
    if (!append) {
      _results = const [];
      _page = 0;
      _total = 0;
      _loadingMore = false;
    }
    if (append) {
      _loadingMore = true;
    } else {
      _loading = true;
    }
    _error = null;
    emit();
    try {
      final result = await _searchService.search(
        keyword: _keyword.isEmpty ? null : _keyword,
        categoryId: categoryId,
        sort: sort,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minDiscount: minDiscount,
        maxDiscount: maxDiscount,
        lat: _radiusKm != null || sort == 'distance_asc' ? latitude : null,
        lng: _radiusKm != null || sort == 'distance_asc' ? longitude : null,
        radiusKm: _radiusKm,
        locationDenied: _locationDenied,
        page: _page + 1,
      );
      if (_disposed || generation != _generation) return;
      final merged = {
        ...{for (final c in _results) c.id: c},
        ...{for (final c in result.items) c.id: c},
      };
      _results = merged.values.toList();
      _total = result.total;
      _page++;
    } catch (e) {
      if (generation == _generation) _error = e.toString();
    } finally {
      if (generation == _generation) {
        _loading = false;
        _loadingMore = false;
        emit();
      }
    }
  }
}
