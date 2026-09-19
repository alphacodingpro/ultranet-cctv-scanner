import 'package:flutter_test/flutter_test.dart';
import 'package:ultranet_cctv_scanner_mobile/models/camera_device.dart';
import 'package:ultranet_cctv_scanner_mobile/services/discovery_service.dart';

void main() {
  test('extracts /24 prefix', () {
    expect(subnetPrefix('192.168.10.45'), '192.168.10');
  });

  test('classifies common CCTV ports', () {
    expect(vendorFromPorts([80, 8000]), 'Hikvision-family');
    expect(vendorFromPorts([554, 37777]), 'Dahua-family');
  });

  test('does not serialize credentials', () {
    const device = CameraDevice(id: '1', ip: '192.168.1.20', name: 'Gate', username: 'admin');
    expect(device.toJson().containsKey('password'), isFalse);
  });
}
