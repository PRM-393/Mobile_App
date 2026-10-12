import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/campaign.dart';
import '../services/voucher_services.dart';

// Tim kiem theo tu khoa + "gan toi" voi xin quyen vi tri (FR-SEARCH-02/03/05/06)
class SearchProvider extends ChangeNotifier {
  SearchProvider(this._searchService);

  final SearchService _searchService;

  String _keyword = '';
  int? _radiusKm;
  Position? _position;
  bool _locationDenied = false;
  bool _loading = false;
  String? _error;
  List<VoucherCampaign> _results = const [];

  String get keyword => _keyword;
  int? get radiusKm => _radiusKm;
  bool get hasLocation => _position != null;
  bool get locationDenied => _locationDenied;
  bool get loading => _loading;
  String? get error => _error;
  List<VoucherCampaign> get results => _results;

  Future<void> setKeyword(String value) async {
    _keyword = value.trim();
    await search();
  }

  // Chon ban kinh; lan dau se xin quyen vi tri
  Future<void> setRadius(int? km) async {
    if (km != null && _position == null) {
      final granted = await _ensureLocation();
      if (!granted) {
        _radiusKm = null;
        notifyListeners();
        await search();
        return;
      }
    }
    _radiusKm = km;
    await search();
  }

  // FR-SEARCH-06: tu choi quyen vi tri -> hien danh sach mac dinh kem thong bao ly do
  Future<bool> _ensureLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationDenied = true;
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _locationDenied = true;
        return false;
      }
      _position = await Geolocator.getCurrentPosition();
      _locationDenied = false;
      return true;
    } catch (_) {
      _locationDenied = true;
      return false;
    }
  }

  Future<void> search() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final useNearMe = _radiusKm != null && _position != null;
      final result = await _searchService.search(
        keyword: _keyword.isEmpty ? null : _keyword,
        lat: useNearMe ? _position!.latitude : null,
        lng: useNearMe ? _position!.longitude : null,
        radiusKm: useNearMe ? _radiusKm : null,
      );
      _results = result.items;
    } catch (e) {
      _results = const [];
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
