import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/voucher_services.dart';

// Vi voucher chia theo tab trang thai (FR-REDEEM-01)
class WalletProvider extends ChangeNotifier {
  WalletProvider(this._orderService);

  final OrderService _orderService;

  static const tabs = ['ACTIVE', 'USED', 'EXPIRED', 'REFUNDED'];

  List<VoucherItem> _items = const [];
  List<VoucherItem> _visible = const [];
  String _tab = 'ACTIVE';
  bool _loading = false;
  String? _error;

  String get tab => _tab;
  bool get loading => _loading;
  String? get error => _error;

  // Danh sach da loc duoc giu lai (cung mot doi tuong) cho toi khi du lieu / tab doi,
  // de Selector o man hinh chi rebuild khi that su thay doi (Module 12)
  List<VoucherItem> get visibleItems => _visible;

  void selectTab(String tab) {
    if (tab == _tab) return;
    _tab = tab;
    _refilter();
    notifyListeners();
  }

  void _refilter() => _visible = _items
      .where((i) => i.effectiveStatus == _tab)
      .toList(growable: false);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _orderService.myWallet();
      _refilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

}
