import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/camera_device.dart';

const cameraPorts = <int>[80, 81, 443, 554, 8000, 8080, 8899, 37777];

String subnetPrefix(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4 || parts.any((p) => int.tryParse(p) == null || int.parse(p) > 255)) throw const FormatException('Invalid IPv4 address');
  return '${parts[0]}.${parts[1]}.${parts[2]}';
}

String vendorFromPorts(List<int> ports, [String scopes = '']) {
  final lower = scopes.toLowerCase();
  if (lower.contains('hikvision') || ports.contains(8000)) return 'Hikvision-family';
  if (lower.contains('dahua') || ports.contains(37777)) return 'Dahua-family';
  if (lower.contains('uniview') || lower.contains('unv')) return 'Uniview-family';
  if (ports.contains(554)) return 'RTSP device';
  return 'Unknown';
}

class DiscoveryService {
  DiscoveryService({NetworkInfo? networkInfo}) : _networkInfo = networkInfo ?? NetworkInfo();
  final NetworkInfo _networkInfo;
  bool _cancelled = false;
  void cancel() => _cancelled = true;

  Future<String> currentIp() async {
    final ip = await _networkInfo.getWifiIP();
    if (ip == null) throw StateError('Wi-Fi IPv4 address nahi mila. Site Wi-Fi connect karein.');
    return ip;
  }

  Stream<CameraDevice> scan({String? localIp}) async* {
    _cancelled = false;
    final ip = localIp ?? await currentIp();
    final merged = <String, CameraDevice>{};
    await for (final onvif in discoverOnvif()) {
      if (_cancelled) return;
      merged[onvif.ip] = onvif;
      yield onvif;
    }
    final prefix = subnetPrefix(ip);
    for (var start = 1; start < 255 && !_cancelled; start += 32) {
      final end = min(start + 32, 255);
      final results = await Future.wait([for (var host = start; host < end; host++) _probe('$prefix.$host')]);
      for (final device in results.whereType<CameraDevice>()) {
        final old = merged[device.ip];
        final combined = old == null ? device : device.copyWith(id: old.id, onvifUrl: old.onvifUrl, vendor: old.vendor == 'Unknown' ? device.vendor : old.vendor);
        merged[device.ip] = combined;
        yield combined;
      }
    }
  }

  Future<CameraDevice?> _probe(String ip) async {
    final stopwatch = Stopwatch()..start();
    final open = <int>[];
    for (final port in cameraPorts) {
      if (_cancelled) return null;
      Socket? socket;
      try { socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 180)); open.add(port); }
      on SocketException catch (_) {} on TimeoutException catch (_) {} finally { socket?.destroy(); }
    }
    stopwatch.stop();
    if (open.isEmpty) return null;
    return CameraDevice(id: 'camera-$ip', ip: ip, name: ip, vendor: vendorFromPorts(open), ports: open, lastSeen: DateTime.now(), latencyMs: max(1, stopwatch.elapsedMilliseconds ~/ cameraPorts.length));
  }

  Stream<CameraDevice> discoverOnvif() async* {
    RawDatagramSocket? socket;
    final found = <String>{};
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0, reuseAddress: true);
      final messageId = const Uuid().v4();
      final probe = '''<?xml version="1.0" encoding="UTF-8"?><e:Envelope xmlns:e="http://www.w3.org/2003/05/soap-envelope" xmlns:w="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:dn="http://www.onvif.org/ver10/network/wsdl"><e:Header><w:MessageID>uuid:$messageId</w:MessageID><w:To e:mustUnderstand="true">urn:schemas-xmlsoap-org:ws:2005:04:discovery</w:To><w:Action e:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</w:Action></e:Header><e:Body><d:Probe><d:Types>dn:NetworkVideoTransmitter</d:Types></d:Probe></e:Body></e:Envelope>''';
      socket.send(utf8.encode(probe), InternetAddress('239.255.255.250'), 3702);
      final responses = socket.where((event) => event == RawSocketEvent.read).map((_) => socket!.receive()).where((packet) => packet != null).cast<Datagram>().timeout(const Duration(seconds: 3));
      try {
        await for (final packet in responses) {
          if (_cancelled) return;
          final xml = utf8.decode(packet.data, allowMalformed: true);
          final xaddr = RegExp(r'<(?:\w+:)?XAddrs>([^<]+)</').firstMatch(xml)?.group(1)?.split(' ').first;
          final scopes = RegExp(r'<(?:\w+:)?Scopes[^>]*>([^<]*)</').firstMatch(xml)?.group(1) ?? '';
          final ip = xaddr == null ? packet.address.address : Uri.tryParse(xaddr)?.host ?? packet.address.address;
          if (!found.add(ip)) continue;
          yield CameraDevice(id: 'camera-$ip', ip: ip, name: ip, vendor: vendorFromPorts(const [], scopes), onvifUrl: xaddr, lastSeen: DateTime.now());
        }
      } on TimeoutException catch (_) {}
    } on SocketException catch (_) {} finally { socket?.close(); }
  }
}
