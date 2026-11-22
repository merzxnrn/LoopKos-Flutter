import 'package:flutter_test/flutter_test.dart';
import 'package:loopkos_flutter/core/constants.dart';

void main() {
  test('AppConstants formats Rupiah and WhatsApp numbers correctly', () {
    expect(AppConstants.formatRp(250000), 'Rp 250.000');
    expect(AppConstants.formatPhoneForWa('0812-3456-7890'), '6281234567890');
    expect(AppConstants.formatPhoneForWa('6281234567890'), '6281234567890');
  });
}
