import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:loopkos_flutter/core/theme.dart';
import 'package:loopkos_flutter/models/mock_data.dart';
import 'package:loopkos_flutter/models/models.dart';
import 'package:loopkos_flutter/providers/cart_provider.dart';
import 'package:loopkos_flutter/screens/home_screen.dart';
import 'package:loopkos_flutter/screens/login_screen.dart';
import 'package:loopkos_flutter/widgets/ui_kit.dart';

void main() {
  testWidgets(
      'LoginScreen defaults to Masuk tab, validates empty inputs, and opens Lupa password sheet',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const LoginScreen(),
    ));

    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Selamat Datang Kembali'), findsOneWidget);

    await tester.tap(find.text('Masuk ke Akun'));
    await tester.pump();
    expect(find.text('Email wajib diisi'), findsOneWidget);

    await tester.tap(find.text('Lupa password?'));
    await tester.pumpAndSettle();
    expect(find.text('Bantuan Reset Password'), findsOneWidget);
  });

  testWidgets(
      'LoginScreen switches to Daftar tab, validates register fields, and opens Syarat & Ketentuan sheet',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const LoginScreen(),
    ));

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Buat Akun LoopKos'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);

    await tester.ensureVisible(find.text('Buat Akun'));
    await tester.tap(find.text('Buat Akun'));
    await tester.pump();
    await tester.ensureVisible(find.text('Nama lengkap wajib diisi'));
    expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password minimal 8 karakter'), findsOneWidget);

    await tester.ensureVisible(find.text('Syarat & Ketentuan'));
    await tester.tap(find.text('Syarat & Ketentuan'));
    await tester.pumpAndSettle();
    expect(find.text('Syarat & Ketentuan LoopKos'), findsOneWidget);
  });

  testWidgets(
      'HomeScreen renders catalog above the fold, clears search, and has >=48dp cart buttons',
      (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: HomeScreen(
          loader: ({category, search}) async {
            var list = List<Map<String, dynamic>>.from(MockData.products);
            if (category != null) {
              list = list.where((p) => p['category'] == category).toList();
            }
            if (search != null && search.isNotEmpty) {
              list = list
                  .where((p) => p['name']
                      .toString()
                      .toLowerCase()
                      .contains(search.toLowerCase()))
                  .toList();
            }
            return list;
          },
        ),
      ),
    ));

    await tester.pumpAndSettle();
    expect(find.text('Produk Tersedia'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tidak-ada-barang-xyz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Reset Filter'), findsOneWidget);

    await tester.tap(find.text('Reset Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Produk Tersedia'), findsOneWidget);

    final firstCartBtn = find.byTooltip('Tambah ke keranjang').first;
    final size = tester.getSize(firstCartBtn);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'HomeScreen shows ShimmerBox while loading and enforces single-seller cart guard',
      (tester) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    final cart = CartProvider();
    cart.addItem(CartItem(
      id: 'existing-1',
      name: 'Meja Lipat',
      price: 100000,
      category: 'furnitur',
      imageUrls: const [],
      sellerId: 'other-seller',
      sellerName: 'Penjual Lain',
      condition: 'Baik',
      location: 'Kost Melati',
    ));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: HomeScreen(
          loader: ({category, search}) => completer.future,
        ),
      ),
    ));

    await tester.pump();
    expect(find.byType(ShimmerBox), findsWidgets);

    completer.complete(List<Map<String, dynamic>>.from(MockData.products));
    await tester.pumpAndSettle();

    final firstCartBtn = find.byTooltip('Tambah ke keranjang').first;
    await tester.ensureVisible(firstCartBtn);
    await tester.tap(firstCartBtn);
    await tester.pumpAndSettle();

    expect(find.text('Ganti Isi Keranjang?'), findsOneWidget);
    await tester.tap(find.text('Ganti Keranjang'));
    await tester.pumpAndSettle();

    expect(cart.count, 1);
    expect(cart.items.first.id, MockData.products.first['id']);
  });
}
