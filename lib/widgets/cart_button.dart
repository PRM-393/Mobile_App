import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../routes.dart';

// Bieu tuong gio hang kem so luong tren thanh tieu de: tu moi man hinh thay ngay voucher da chon
class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider?, int>((c) => c?.totalQuantity ?? 0);
    return IconButton(
      key: const Key('cart-button'),
      tooltip: 'Giỏ hàng',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
      onPressed: () {
        ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
        Navigator.pushNamed(context, AppRoutes.cart);
      },
    );
  }
}
