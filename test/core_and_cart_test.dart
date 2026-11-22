import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopkos_flutter/core/constants.dart';
import 'package:loopkos_flutter/core/theme.dart';
import 'package:loopkos_flutter/models/models.dart';
import 'package:loopkos_flutter/providers/cart_provider.dart';

void main() {
  test('AppColors high-contrast text tokens exist and contrast on card', () {
    expect(AppColors.background, const Color(0xFF060B14));
    expect(AppColors.card, const Color(0xFF0E1729));
    expect(AppColors.primaryText, const Color(0xFF60A5FA));
    expect(AppColors.priceGreen, const Color(0xFF34D399));
  });

  test('AppConstants.categoryIconData maps known categories to vector icons', () {
    expect(AppConstants.categoryIconData('furnitur'), Icons.chair_outlined);
    expect(AppConstants.categoryIconData('elektronik'), Icons.bolt_outlined);
    expect(AppConstants.categoryIconData('bundle'), Icons.layers_outlined);
    expect(AppConstants.categoryIconData(null), Icons.inventory_2_outlined);
  });

  test('CartProvider detects different seller and supports replaceWithItem', () {
    final cart = CartProvider();
    final itemA = CartItem(
      id: 'p1',
      name: 'Meja',
      price: 100000,
      category: 'furnitur',
      imageUrls: const [],
      sellerId: 'seller-1',
      sellerName: 'Andi',
      condition: 'Baik',
      location: 'Depok',
    );
    final itemB = CartItem(
      id: 'p2',
      name: 'Lampu',
      price: 50000,
      category: 'elektronik',
      imageUrls: const [],
      sellerId: 'seller-2',
      sellerName: 'Budi',
      condition: 'Baik',
      location: 'Bandung',
    );

    cart.addItem(itemA);
    expect(cart.hasDifferentSeller('seller-1'), isFalse);
    expect(cart.hasDifferentSeller('seller-2'), isTrue);

    cart.replaceWithItem(itemB);
    expect(cart.count, 1);
    expect(cart.items.first.id, 'p2');
    expect(cart.items.first.sellerId, 'seller-2');
  });

  test('CartProvider clamps negative/excessive discounts and guards empty sellerId', () {
    final cart = CartProvider();
    expect(
      CartProvider.resolveSellerId(sellerId: '', sellerName: 'Andi', itemId: 'b1'),
      'name:andi',
    );
    expect(
      CartProvider.resolveSellerId(sellerId: '', sellerName: 'Penjual', itemId: 'b2'),
      'unknown:b2',
    );

    cart.addItem(CartItem(
      id: 'b1',
      name: 'Bundle Over-Discount',
      price: 50000,
      discount: 120000,
      category: 'bundle',
      imageUrls: const [],
      sellerId: 'seller-1',
      sellerName: 'Andi',
      condition: 'Bundle',
      location: 'Depok',
      isBundle: true,
    ));
    cart.addItem(CartItem(
      id: 'p2',
      name: 'Lampu',
      price: 40000,
      discount: -5000,
      category: 'elektronik',
      imageUrls: const [],
      sellerId: 'seller-1',
      sellerName: 'Andi',
      condition: 'Baik',
      location: 'Depok',
    ));

    // Over-discounted bundle floors at 0 (does not reduce p2), negative discount floors at 0.
    expect(cart.totalPrice, 40000);

    // Empty sellerId cannot bypass single-seller check once cart has items.
    expect(cart.hasDifferentSeller(''), isTrue);

    cart.replaceWithItem(CartItem(
      id: 'u1',
      name: 'Unknown Seller Item',
      price: 10000,
      category: 'lainnya',
      imageUrls: const [],
      sellerId: '',
      sellerName: 'Penjual',
      condition: 'Baik',
      location: 'Depok',
    ));
    expect(cart.hasDifferentSeller('seller-1'), isTrue);
    expect(cart.hasDifferentSeller(''), isTrue);
  });
}
