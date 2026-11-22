import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:loopkos_flutter/core/theme.dart';
import 'package:loopkos_flutter/models/mock_data.dart';
import 'package:loopkos_flutter/models/models.dart';
import 'package:loopkos_flutter/providers/cart_provider.dart';
import 'package:loopkos_flutter/screens/bundle_screen.dart';
import 'package:loopkos_flutter/screens/product_detail_screen.dart';
import 'package:loopkos_flutter/widgets/ui_kit.dart';

void main() {
  testWidgets('BundleScreen shows Tambah ke Keranjang + Beli Langsung and prompts on different seller', (tester) async {
    final cart = CartProvider();
    cart.addItem(CartItem(
      id: 'other-1',
      name: 'Item Penjual Lain',
      price: 20000,
      category: 'lainnya',
      imageUrls: const [],
      sellerId: 'different-seller',
      sellerName: 'Siti',
      condition: 'Baik',
      location: 'Jogja',
    ));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: BundleScreen(loader: () async => MockData.bundles),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tambah ke Keranjang'), findsWidgets);
    expect(find.text('Beli Langsung'), findsWidgets);

    await tester.tap(find.text('Tambah ke Keranjang').first);
    await tester.pumpAndSettle();
    expect(find.text('Ganti Isi Keranjang?'), findsOneWidget);

    await tester.tap(find.text('Ganti Keranjang'));
    await tester.pumpAndSettle();
    expect(cart.count, 1);
    expect(cart.items.first.id, MockData.bundles.first['id']);
    expect(cart.items.first.isBundle, isTrue);
  });

  testWidgets('BundleScreen shows ShimmerBox while loading and EmptyStateView when empty', (tester) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: BundleScreen(loader: () => completer.future),
      ),
    ));

    await tester.pump();
    expect(find.byType(ShimmerBox), findsWidgets);

    completer.complete(const []);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text('Belum ada bundle tersedia'), findsOneWidget);
  });

  testWidgets('ProductDetailScreen displays sticky bottom CTA and community review label', (tester) async {
    final sample = MockData.products.first;
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: ProductDetailScreen(
          productId: sample['id'].toString(),
          loader: (_) async => sample,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Beli Sekarang'), findsOneWidget);
    expect(find.text('Tanya Penjual'), findsOneWidget);
    expect(find.text('CONTOH ULASAN KOMUNITAS'), findsOneWidget);

    final askBtn = find.ancestor(
      of: find.text('Tanya Penjual'),
      matching: find.byWidgetPredicate((w) => w is OutlinedButton),
    );
    expect(tester.getSize(askBtn).height, greaterThanOrEqualTo(48));

    final buyBtn = find.ancestor(
      of: find.text('Beli Sekarang'),
      matching: find.byWidgetPredicate((w) => w is ElevatedButton),
    );
    expect(tester.getSize(buyBtn).height, greaterThanOrEqualTo(48));
  });

  testWidgets('ProductDetailScreen Tanya Penjual sheet shows Telepon and WhatsApp when phone exists', (tester) async {
    final withPhone = Map<String, dynamic>.from(MockData.products.first);
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: ProductDetailScreen(
          productId: withPhone['id'].toString(),
          loader: (_) async => withPhone,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tanya Penjual'));
    await tester.pumpAndSettle();
    expect(find.text('Hubungi Penjual'), findsOneWidget);
    expect(find.text('Telepon'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
  });

  testWidgets('ProductDetailScreen Tanya Penjual sheet shows fallback note when phone is missing', (tester) async {
    final withoutPhone = Map<String, dynamic>.from(MockData.products.first)
      ..remove('sellerPhone');
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: ProductDetailScreen(
          productId: withoutPhone['id'].toString(),
          loader: (_) async => withoutPhone,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tanya Penjual'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nomor telepon penjual belum tersedia'), findsOneWidget);
  });

  testWidgets('ProductDetailScreen enforces single-seller cart guard on Beli Sekarang', (tester) async {
    final sample = MockData.products.first;
    final cart = CartProvider();
    cart.addItem(CartItem(
      id: 'other-1',
      name: 'Item Lain',
      price: 10000,
      category: 'lainnya',
      imageUrls: const [],
      sellerId: 'other-seller-99',
      sellerName: 'Penjual Lain',
      condition: 'Baik',
      location: 'Bandung',
    ));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        routes: {
          '/checkout': (_) => const Scaffold(body: Text('Checkout')),
        },
        home: ProductDetailScreen(
          productId: sample['id'].toString(),
          loader: (_) async => sample,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beli Sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Ganti Isi Keranjang?'), findsOneWidget);

    await tester.tap(find.text('Ganti Keranjang'));
    await tester.pumpAndSettle();
    expect(cart.count, 1);
    expect(cart.items.first.id, sample['id'].toString());
    expect(find.text('Checkout'), findsOneWidget);
  });

  testWidgets('BundleScreen floors negative/excessive discount at Rp 0 and blocks missing sellerId mixing', (tester) async {
    final cart = CartProvider();
    cart.addItem(CartItem(
      id: 'existing-1',
      name: 'Item Existing',
      price: 30000,
      category: 'lainnya',
      imageUrls: const [],
      sellerId: 'seller-existing',
      sellerName: 'Rina',
      condition: 'Baik',
      location: 'Depok',
    ));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: BundleScreen(
          loader: () async => [
            {
              'id': 'b-over',
              'name': 'Bundle Diskon Besar',
              'totalPrice': 100000,
              'discount': 150000,
              'sellerId': '',
              'sellerName': 'Penjual',
              'location': 'Depok',
              'items': const [],
              'imageUrls': const <String>[],
            },
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Rp 0'), findsOneWidget);

    await tester.tap(find.text('Tambah ke Keranjang'));
    await tester.pumpAndSettle();
    expect(find.text('Ganti Isi Keranjang?'), findsOneWidget);
  });

  testWidgets('ProductDetailScreen bottom bar fits 320px viewport at 1.3x text scale without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sample = Map<String, dynamic>.from(MockData.products.first)
      ..['sellerId'] = ''
      ..['sellerName'] = 'Penjual';

    final cart = CartProvider();
    cart.addItem(CartItem(
      id: 'other-1',
      name: 'Item Lain',
      price: 15000,
      category: 'lainnya',
      imageUrls: const [],
      sellerId: 'seller-real',
      sellerName: 'Budi',
      condition: 'Baik',
      location: 'Depok',
    ));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child!,
        ),
        home: ProductDetailScreen(
          productId: sample['id'].toString(),
          loader: (_) async => sample,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tanya Penjual'), findsOneWidget);
    expect(find.text('Beli Sekarang'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Beli Sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Ganti Isi Keranjang?'), findsOneWidget);
  });
}
