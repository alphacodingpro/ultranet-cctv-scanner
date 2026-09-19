import 'dart:async';
import 'dart:io';

const cameraPorts = <int>[80, 443, 554, 8000, 8080, 8899, 37777];

class Device {
  const Device({required this.ip, required this.ports});

  final String ip;
  final List<int> ports;

  String get vendorHint {
    if (ports.contains(37777)) return 'Dahua-family';
    if (ports.contains(8000)) return 'Hikvision-family';
    if (ports.contains(554)) return 'RTSP device';
    return 'Unknown';
  }

  String get type => ports.contains(554) || ports.contains(8000) || ports.contains(37777)
      ? 'Possible camera / recorder'
      : 'Network device';
}

String subnetPrefix(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4 || parts.any((part) => int.tryParse(part) == null)) {
    throw const FormatException('Invalid IPv4 address');
  }
  return '${parts[0]}.${parts[1]}.${parts[2]}';
}

Future<Device?> probeHost(String ip, {Duration timeout = const Duration(milliseconds: 220)}) async {
  final open = <int>[];
  for (final port in cameraPorts) {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: timeout);
      open.add(port);
    } on SocketException {
      // Closed/unreachable ports are expected during discovery.
    } on TimeoutException {
      // A silent host is not considered discovered.
    } finally {
      socket?.destroy();
    }
  }
  return open.isEmpty ? null : Device(ip: ip, ports: open);
}

Stream<Device> scan24(String localIp, {int batchSize = 32}) async* {
  final prefix = subnetPrefix(localIp);
  for (var start = 1; start < 255; start += batchSize) {
    final end = (start + batchSize).clamp(1, 255);
    final batch = <Future<Device?>>[];
    for (var host = start; host < end; host++) {
      batch.add(probeHost('$prefix.$host'));
    }
    final results = await Future.wait(batch);
    for (final device in results) {
      if (device != null) yield device;
    }
  }
}

