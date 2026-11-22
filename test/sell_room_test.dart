import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopkos_flutter/core/theme.dart';
import 'package:loopkos_flutter/screens/sell_room_screen.dart';

void main() {
  testWidgets('SellRoomScreen shows Step 1 helper hint when photo is missing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const SellRoomScreen(),
    ));

    expect(find.text('Upload Foto Barang'), findsOneWidget);
    expect(find.textContaining('Minimal 1 foto'), findsOneWidget);
    final nextBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Lanjut ke Step 2'));
    expect(nextBtn.onPressed, isNull);
  });

  testWidgets('SellRoomScreen bundle item rows preserve text when removing sibling rows', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const SellRoomScreen(initialStepForTest: 2),
    ));

    await tester.tap(find.text('Bundle Sekaligus'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('bundle_item_name_0')), 'Meja Belajar');
    await tester.enterText(find.byKey(const ValueKey('bundle_item_price_0')), '150000');

    await tester.tap(find.text('Tambah Item'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('bundle_item_name_1')), 'Kursi Lipat');
    await tester.enterText(find.byKey(const ValueKey('bundle_item_price_1')), '100000');
    await tester.pumpAndSettle();

    expect(find.text('Total Nilai Item: Rp 250.000'), findsOneWidget);

    final delete0 = find.byKey(const ValueKey('bundle_item_delete_0'));
    await tester.ensureVisible(delete0);
    await tester.pumpAndSettle();
    await tester.tap(delete0);
    await tester.pumpAndSettle();

    expect(find.text('Kursi Lipat'), findsOneWidget);
    expect(find.text('Meja Belajar'), findsNothing);
    expect(find.text('Total Nilai Item: Rp 100.000'), findsOneWidget);
  });

  testWidgets('SellRoomScreen bundle item rows preserve selected category when removing row 0', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const SellRoomScreen(initialStepForTest: 2),
    ));

    await tester.tap(find.text('Bundle Sekaligus'));
    await tester.pumpAndSettle();

    // Select category for row 0: 'Furnitur & Kamar'
    await tester.tap(find.byKey(const ValueKey('bundle_item_category_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Furnitur & Kamar').last);
    await tester.pumpAndSettle();

    // Add row 1
    await tester.tap(find.text('Tambah Item'));
    await tester.pumpAndSettle();

    // Select category for row 1: 'Elektronik & Gadget'
    final category1 = find.byKey(const ValueKey('bundle_item_category_1'));
    await tester.ensureVisible(category1);
    await tester.pumpAndSettle();
    await tester.tap(category1);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elektronik & Gadget').last);
    await tester.pumpAndSettle();

    // Remove row 0
    final delete0 = find.byKey(const ValueKey('bundle_item_delete_0'));
    await tester.ensureVisible(delete0);
    await tester.pumpAndSettle();
    await tester.tap(delete0);
    await tester.pumpAndSettle();

    // The remaining row should retain 'Elektronik & Gadget' and NOT 'Furnitur & Kamar'
    expect(find.text('Elektronik & Gadget'), findsOneWidget);
    expect(find.text('Furnitur & Kamar'), findsNothing);
  });

  test('SellRoomScreen.clampBundleDiscount clamps negative and excessive discounts', () {
    expect(SellRoomScreen.clampBundleDiscount(-5000, 100000), 0);
    expect(SellRoomScreen.clampBundleDiscount(25000, 100000), 25000);
    expect(SellRoomScreen.clampBundleDiscount(150000, 100000), 100000);
    expect(SellRoomScreen.clampBundleDiscount(50000, 0), 0);
  });

  testWidgets('SellRoomScreen Step 2 clamps negative/excessive discount preview and avoids squeezing Harga at 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const SellRoomScreen(initialStepForTest: 2),
    ));

    await tester.tap(find.text('Bundle Sekaligus'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah Item'));
    await tester.pumpAndSettle();

    // Harga field should not be squeezed into ~40-60dp on a 320px screen.
    final priceWidth = tester.getSize(find.byKey(const ValueKey('bundle_item_price_0'))).width;
    expect(priceWidth, greaterThanOrEqualTo(200));

    final deleteSize = tester.getSize(find.byKey(const ValueKey('bundle_item_delete_0')));
    expect(deleteSize.width, greaterThanOrEqualTo(48));
    expect(deleteSize.height, greaterThanOrEqualTo(48));

    await tester.enterText(find.byKey(const ValueKey('bundle_item_price_0')), '100000');
    await tester.pumpAndSettle();

    final discountField = find.widgetWithText(TextField, 'Diskon Bundle (Rp)');
    await tester.ensureVisible(discountField);
    await tester.enterText(discountField, '-5000');
    await tester.pumpAndSettle();
    expect(find.text('Harga Jual Bundle: Rp 100.000'), findsOneWidget);

    await tester.enterText(discountField, '250000');
    await tester.pumpAndSettle();
    expect(find.text('Harga Jual Bundle: Rp 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
