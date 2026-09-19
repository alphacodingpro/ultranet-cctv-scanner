import 'package:flutter_test/flutter_test.dart';
import 'package:ultranet_cctv_scanner_mobile/scanner.dart';

void main() {
  test('extracts /24 prefix', () {
    expect(subnetPrefix('192.168.10.45'), '192.168.10');
  });

  test('classifies common CCTV ports', () {
    expect(const Device(ip: '1.1.1.1', ports: [80, 8000]).vendorHint, 'Hikvision-family');
    expect(const Device(ip: '1.1.1.2', ports: [554, 37777]).vendorHint, 'Dahua-family');
  });
}

