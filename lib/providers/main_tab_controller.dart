import 'package:flutter/foundation.dart';

// Tab dang chon o man hinh chinh, cho phep man hinh khac chuyen tab (vd. sau khi tao don -> tab Don hang)
class MainTabController extends ChangeNotifier {
  static const home = 0, search = 1, wallet = 2, orders = 3, profile = 4;

  int _index = home;
  int get index => _index;

  void go(int index) {
    if (_index == index) return;
    _index = index;
    notifyListeners();
  }
}
