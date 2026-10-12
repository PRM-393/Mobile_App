import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/voucher_services.dart';

// Vi voucher chia theo tab trang thai (FR-REDEEM-01)
class WalletProvider extends ChangeNotifier {
  WalletProvider(this._orderService);

  final OrderService _orderService;

  static const tabs = ['ACTIVE', 'USED', 'EXPIRED', 'REFUNDED'];

  List<VoucherItem> _items = const [];
  String _tab = 'ACTIVE';
  bool _loading = false;
  String? _error;

  String get tab => _tab;
  bool get loading => _loading;
  String? get error => _error;
  List<VoucherItem> get visibleItems => _items.where((i) => i.effectiveStatus == _tab).toList();

  void selectTab(String tab) {
    _tab = tab;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _orderService.myWallet();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
