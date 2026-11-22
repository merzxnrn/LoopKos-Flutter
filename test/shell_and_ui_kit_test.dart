import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:loopkos_flutter/core/theme.dart';
import 'package:loopkos_flutter/providers/cart_provider.dart';
import 'package:loopkos_flutter/screens/my_listings_screen.dart';
import 'package:loopkos_flutter/screens/payment_details_screen.dart';
import 'package:loopkos_flutter/widgets/app_background.dart';
import 'package:loopkos_flutter/widgets/loopkos_header.dart';
import 'package:loopkos_flutter/widgets/main_shell.dart';
import 'package:loopkos_flutter/widgets/ui_kit.dart';

void main() {
  testWidgets('ErrorStateView renders message and invokes retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: Scaffold(
        body: ErrorStateView(
          message: 'Gagal memuat data',
          onRetry: () => retried = true,
        ),
      ),
    ));

    expect(find.text('Gagal memuat data'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    expect(retried, isTrue);
  });

  testWidgets('LoopKosHeader shows back button when showBack is true and 48dp cart target', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: const Scaffold(
          appBar: LoopKosHeader(title: 'Checkout', showBack: true, currentRoute: '/checkout'),
          body: SizedBox(),
        ),
      ),
    ));

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    final backSize = tester.getSize(find.byTooltip('Kembali'));
    expect(backSize.width, greaterThanOrEqualTo(48));
    expect(backSize.height, greaterThanOrEqualTo(48));
    final cartSize = tester.getSize(find.byTooltip('Keranjang'));
    expect(cartSize.width, greaterThanOrEqualTo(48));
    expect(cartSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets('MainShell switches between 5 tabs and preserves NavigationBar labels', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: const MainShell(
          pages: [
            Center(child: Text('Tab Beranda')),
            Center(child: Text('Tab Bundle')),
            Center(child: Text('Tab Jual')),
            Center(child: Text('Tab Transaksi')),
            Center(child: Text('Tab Profil')),
          ],
        ),
      ),
    ));

    expect(find.text('Tab Beranda'), findsOneWidget);
    await tester.tap(find.text('Bundle'));
    await tester.pumpAndSettle();
    expect(find.text('Tab Bundle'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Tab Profil'), findsOneWidget);
  });

  testWidgets('MainShell.switchTab changes active tab from descendant context', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: MainShell(
          pages: [
            Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => MainShell.switchTab(ctx, 3),
                  child: const Text('Ke Transaksi'),
                ),
              ),
            ),
            const Center(child: Text('Tab Bundle')),
            const Center(child: Text('Tab Jual')),
            const Center(child: Text('Tab Transaksi')),
            const Center(child: Text('Tab Profil')),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('Ke Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Tab Transaksi'), findsOneWidget);
  });

  testWidgets('AppCard, StatusBadge, EmptyStateView, and confirmReplaceCartDialog work cleanly', (tester) async {
    var tapped = false;
    var actionCalled = false;
    bool? dialogResult;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            expect(watchAuthOrNull(context), isNull);
            expect(readAuthOrNull(context), isNull);
            return SingleChildScrollView(
              child: Column(
                children: [
                  AppCard(
                    onTap: () => tapped = true,
                    child: const StatusBadge(
                      label: 'Aktif',
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  EmptyStateView(
                    icon: Icons.inbox_outlined,
                    title: 'Belum ada data',
                    subtitle: 'Tambahkan barang pertama kamu',
                    actionLabel: 'Jual Sekarang',
                    onAction: () => actionCalled = true,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      dialogResult = await confirmReplaceCartDialog(
                        context,
                        currentSeller: 'Andi',
                        newSeller: 'Budi',
                      );
                    },
                    child: const Text('Buka Dialog'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ));

    expect(find.text('Aktif'), findsOneWidget);
    await tester.tap(find.text('Aktif'));
    expect(tapped, isTrue);

    await tester.tap(find.text('Jual Sekarang'));
    expect(actionCalled, isTrue);

    await tester.tap(find.text('Buka Dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Ganti Isi Keranjang?'), findsOneWidget);
    await tester.tap(find.text('Ganti Keranjang'));
    await tester.pumpAndSettle();
    expect(dialogResult, isTrue);
  });

  testWidgets('ShimmerBox animates and disposes cleanly', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const Scaffold(
        body: Center(child: ShimmerBox(width: 120, height: 24)),
      ),
    ));

    expect(find.byType(ShimmerBox), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSize(find.byType(ShimmerBox)), const Size(120, 24));
  });

  testWidgets('MainShell.switchTab from pushed MyListingsScreen and PaymentDetailsScreen keeps root AuthGate wrapper intact', (tester) async {
    final authMarkerKey = GlobalKey();
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme(),
        home: KeyedSubtree(
          key: authMarkerKey,
          child: MainShell(
            initialIndex: 4,
            pages: [
              const Center(child: Text('Tab Beranda')),
              const Center(child: Text('Tab Bundle')),
              const Center(child: Text('Tab Jual')),
              const Center(child: Text('Tab Transaksi')),
              Builder(
                builder: (ctx) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) => MyListingsScreen(
                              loader: () async => (
                                products: const <Map<String, dynamic>>[],
                                sellerTxs: const <Map<String, dynamic>>[],
                              ),
                            ),
                          ),
                        ),
                        child: const Text('Buka Toko Saya'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) => PaymentDetailsScreen(
                              transactionId: 'tx-nav-1',
                              loader: (_) async => {
                                'id': 'tx-nav-1',
                                'status': 'payment_uploaded',
                                'paymentProofUrl': 'https://example.com/proof.png',
                                'totalPrice': 100000,
                                'sellerName': 'Rina',
                                'items': [
                                  {'name': 'Meja', 'price': 100000},
                                ],
                              },
                            ),
                          ),
                        ),
                        child: const Text('Buka Detail Pembayaran'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    // Push MyListingsScreen and tap "Tambah" -> should pop to root MainShell tab 2.
    await tester.tap(find.text('Buka Toko Saya'));
    await tester.pumpAndSettle();
    expect(find.byType(MyListingsScreen), findsOneWidget);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    expect(find.byType(MyListingsScreen), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byKey(authMarkerKey), findsOneWidget);
    expect(find.text('Tab Jual'), findsOneWidget);

    // Switch back to Profil tab, push PaymentDetailsScreen, and tap "Lihat Riwayat Transaksi".
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka Detail Pembayaran'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentDetailsScreen), findsOneWidget);

    final historyBtn = find.text('Lihat Riwayat Transaksi');
    await tester.ensureVisible(historyBtn);
    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    expect(find.byType(PaymentDetailsScreen), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byKey(authMarkerKey), findsOneWidget);
    expect(find.text('Tab Transaksi'), findsOneWidget);
  });

  testWidgets('launchExternalUri shows SnackBar on false return and thrown exception', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => launchExternalUri(
                    context,
                    Uri.parse('https://example.com'),
                    external: true,
                    failureMessage: 'Gagal membuka tautan (false).',
                    launcher: (_, {required mode}) async => false,
                  ),
                  child: const Text('Return False'),
                ),
                ElevatedButton(
                  onPressed: () => launchExternalUri(
                    context,
                    Uri.parse('tel:08123456789'),
                    failureMessage: 'Gagal membuka tautan (error).',
                    launcher: (_, {required mode}) async => throw Exception('no handler'),
                  ),
                  child: const Text('Throw Error'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Return False'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal membuka tautan (false).'), findsOneWidget);

    await tester.tap(find.text('Throw Error'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal membuka tautan (error).'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppBackground renders assets/images/app_bg.png once when nested', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AppBackground(
            child: Center(child: Text('Konten')),
          ),
        ),
      ),
    ));

    expect(find.text('Konten'), findsOneWidget);
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(1));
    expect(images.single.image, const AssetImage('assets/images/app_bg.png'));
    expect(images.single.fit, BoxFit.cover);
  });
}
