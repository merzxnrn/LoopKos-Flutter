import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.length;

  /// Resolves a non-empty seller identifier so missing backend `sellerId` values
  /// cannot bypass single-seller cart and checkout guards.
  static String resolveSellerId({
    Object? sellerId,
    Object? sellerName,
    Object? itemId,
  }) {
    final id = (sellerId ?? '').toString().trim();
    if (id.isNotEmpty) return id;
    final name = (sellerName ?? '').toString().trim().toLowerCase();
    if (name.isNotEmpty && name != 'penjual') {
      return 'name:$name';
    }
    final fallbackId = (itemId ?? '').toString().trim();
    return fallbackId.isNotEmpty ? 'unknown:$fallbackId' : 'unknown';
  }

  int get totalPrice {
    return _items.fold(0, (sum, item) {
      final safePrice = math.max(0, item.price);
      final safeDiscount = math.max(0, item.discount);
      return sum + math.max(0, safePrice - safeDiscount);
    });
  }

  bool hasDifferentSeller(String sellerId) {
    if (_items.isEmpty) return false;
    final incoming = sellerId.trim();
    if (incoming.isEmpty) return true;
    return _items.any((item) {
      final existing = item.sellerId.trim();
      return existing.isEmpty || existing != incoming;
    });
  }

  void addItem(CartItem item) {
    if (_items.any((i) => i.id == item.id)) return;
    _items.add(item);
    notifyListeners();
  }

  void replaceWithItem(CartItem item) {
    _items.clear();
    _items.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
