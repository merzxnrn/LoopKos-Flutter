import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:loopkos_flutter/core/theme.dart';
import 'package:loopkos_flutter/models/models.dart';
import 'package:loopkos_flutter/providers/cart_provider.dart';
import 'package:loopkos_flutter/screens/checkout_screen.dart';
import 'package:loopkos_flutter/screens/my_listings_screen.dart';
import 'package:loopkos_flutter/screens/payment_details_screen.dart';
import 'package:loopkos_flutter/screens/profile_screen.dart';
import 'package:loopkos_flutter/screens/transactions_screen.dart';
import 'package:loopkos_flutter/widgets/ui_kit.dart';

void main() {
  testWidgets('CheckoutScreen shows sticky total CTA and back header', (tester) async {
    final cart = CartProvider();
    cart.addItem(CartItem(
      id: 'p1',
      name: 'Rak Buku',
      price: 120000,
      category: 'furnitur',
      imageUrls: const [],
      sellerId: 's1',
      sellerName: 'Rina',
      condition: 'Baik',
      location: 'Depok',
    ));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(theme: AppTheme.darkTheme(), home: const CheckoutScreen()),
    ));

    expect(find.text('Konfirmasi Pesanan'), findsOneWidget);
    expect(find.text('Rp 120.000'), findsWidgets);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('CheckoutScreen shows EmptyStateView when cart is empty', (tester) async {
    final cart = CartProvider();

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(theme: AppTheme.darkTheme(), home: const CheckoutScreen()),
    ));

    expect(find.byType(EmptyStateView), findsOneWidget);
    expect(find.text('Mulai Belanja'), findsOneWidget);
  });

  testWidgets('CheckoutScreen blocks submit when cart has mixed sellers', (tester) async {
    final cart = CartProvider();
    cart.addItem(CartItem(
      id: 'p1',
      name: 'Rak Buku',
      price: 120000,
      category: 'furnitur',
      imageUrls: const [],
      sellerId: 's1',
      sellerName: 'Rina',
      condition: 'Baik',
      location: 'Depok',
    ));
    cart.addItem(CartItem(
      id: 'p2',
      name: 'Lampu Meja',
      price: 45000,
      category: 'elektronik',
      imageUrls: const [],
      sellerId: 's2',
      sellerName: 'Budi',
      condition: 'Baik',
      location: 'Depok',
    ));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(theme: AppTheme.darkTheme(), home: const CheckoutScreen()),
    ));

    expect(find.textContaining('lebih dari satu penjual'), findsOneWidget);
    final btn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Konfirmasi Pesanan'),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('PaymentDetailsScreen shows ShimmerBox, ErrorStateView, and 4-step progress', (tester) async {
    final completer = Completer<Map<String, dynamic>?>();

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: PaymentDetailsScreen(
        transactionId: 'tx-101',
        loader: (_) => completer.future,
      ),
    ));

    await tester.pump();
    expect(find.byType(ShimmerBox), findsWidgets);

    completer.complete({
      'id': 'tx-101',
      'status': 'pending_payment',
      'totalPrice': 150000,
      'sellerName': 'Rina',
      'sellerBankName': 'BCA',
      'sellerBankAccount': '1234567890',
      'items': [
        {'name': 'Meja Kos', 'price': 150000},
      ],
    });
    await tester.pumpAndSettle();

    expect(find.text('Detail Pembayaran'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsWidgets);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('Verifikasi'), findsOneWidget);
  });

  testWidgets('PaymentDetailsScreen shows ErrorStateView on loader failure', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: PaymentDetailsScreen(
        transactionId: 'tx-err',
        loader: (_) async => throw Exception('network error'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorStateView), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });

  testWidgets('TransactionsScreen shows Bayar button on pending_payment and disposes reject dialog safely', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: TransactionsScreen(
        loader: ({required role}) async => role == 'buyer'
            ? [
                {
                  'id': 'tx-101',
                  'status': 'pending_payment',
                  'totalPrice': 150000,
                  'items': [
                    {'name': 'Meja Kos', 'price': 150000},
                  ],
                },
              ]
            : [
                {
                  'id': 'tx-202',
                  'status': 'payment_uploaded',
                  'totalPrice': 90000,
                  'items': [
                    {'name': 'Kipas Angin', 'price': 90000},
                  ],
                },
              ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Menunggu Pembayaran'), findsOneWidget);
    expect(find.text('Bayar / Info Rekening'), findsOneWidget);

    await tester.tap(find.text('Pesanan Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Nominal kurang');
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Tolak Pembayaran'), findsNothing);
  });

  testWidgets('TransactionsScreen shows ShimmerBox while loading and ErrorStateView on failure', (tester) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: TransactionsScreen(
        loader: ({required role}) => completer.future,
      ),
    ));

    await tester.pump();
    expect(find.byType(ShimmerBox), findsWidgets);

    completer.completeError(Exception('boom'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorStateView), findsOneWidget);
  });

  testWidgets('MyListingsScreen formats revenue accurately and handles loader errors', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: MyListingsScreen(
        loader: () async => (
          products: [
            {
              'id': 'prod-1',
              'name': 'Lemari Lipat',
              'price': 250000,
              'category': 'furnitur',
              'condition': 'Baik',
              'stock': 1,
              'imageUrls': <String>[],
            },
          ],
          sellerTxs: [
            {
              'id': 'tx-1',
              'status': 'completed',
              'totalPrice': 1250500,
            },
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Toko Saya'), findsOneWidget);
    expect(find.text('Rp 1.250.500'), findsOneWidget);
    expect(find.text('Lemari Lipat'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: MyListingsScreen(
        loader: () async => throw Exception('failed'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorStateView), findsOneWidget);
  });

  testWidgets('ProfileScreen omits dead Favorit metric and asks confirmation before logout', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const ProfileScreen(),
    ));

    expect(find.text('Favorit'), findsNothing);
    expect(find.textContaining('Estimasi'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Keluar'), 200);
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari Akun?'), findsOneWidget);
  });

  testWidgets('CheckoutScreen blocks submit when cart mixes empty sellerId items', (tester) async {
    final cart = CartProvider();
    cart.addItem(CartItem(
      id: 'p1',
      name: 'Barang A',
      price: 50000,
      category: 'lainnya',
      imageUrls: const [],
      sellerId: '',
      sellerName: 'Penjual',
      condition: 'Baik',
      location: 'Depok',
    ));
    cart.addItem(CartItem(
      id: 'p2',
      name: 'Barang B',
      price: 60000,
      category: 'lainnya',
      imageUrls: const [],
      sellerId: '',
      sellerName: 'Penjual',
      condition: 'Baik',
      location: 'Depok',
    ));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(theme: AppTheme.darkTheme(), home: const CheckoutScreen()),
    ));

    expect(find.textContaining('lebih dari satu penjual'), findsOneWidget);
    final btn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Konfirmasi Pesanan'),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('TransactionsScreen proof dialog fits short 480x320 landscape viewport without overflow', (tester) async {
    tester.view.physicalSize = const Size(480, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: TransactionsScreen(
        loader: ({required role}) async => role == 'buyer'
            ? const []
            : [
                {
                  'id': 'tx-proof-1',
                  'status': 'payment_uploaded',
                  'totalPrice': 125000,
                  'paymentProofUrl': 'https://example.com/proof.png',
                  'items': [
                    {'name': 'Meja Belajar', 'price': 125000},
                  ],
                },
              ],
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pesanan Masuk'));
    await tester.pumpAndSettle();

    final proofBtn = find.text('Lihat Bukti Transfer');
    await tester.ensureVisible(proofBtn);
    await tester.tap(proofBtn);
    await tester.pumpAndSettle();

    expect(find.text('Bukti Transfer'), findsOneWidget);
    expect(find.text('Buka di Browser'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
