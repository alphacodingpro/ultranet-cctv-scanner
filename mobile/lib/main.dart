import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'scanner.dart';

void main() => runApp(const UltraNetScannerApp());

class UltraNetScannerApp extends StatelessWidget {
  const UltraNetScannerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'UltraNet CCTV Scanner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff16a34a), brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: const ScannerPage(),
      );
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final devices = <Device>[];
  bool scanning = false;
  String status = 'Connect to an authorized site Wi-Fi network.';

  Future<void> startScan() async {
    if (scanning) return;
    setState(() {
      scanning = true;
      devices.clear();
      status = 'Reading current Wi-Fi network…';
    });
    try {
      final ip = await NetworkInfo().getWifiIP();
      if (ip == null) throw Exception('Wi-Fi IPv4 address not available. Connect to site Wi-Fi first.');
      setState(() => status = 'Scanning ${subnetPrefix(ip)}.0/24…');
      await for (final device in scan24(ip)) {
        if (!mounted) return;
        setState(() => devices.add(device));
      }
      setState(() => status = 'Complete — ${devices.length} responsive device(s) found.');
    } catch (error) {
      setState(() => status = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('UltraNet CCTV Scanner')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(status),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: scanning ? null : startScan,
              icon: scanning
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.radar),
              label: Text(scanning ? 'Scanning…' : 'Scan Network'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.videocam_outlined),
                      title: Text(device.ip),
                      subtitle: Text('${device.vendorHint} · ports ${device.ports.join(', ')}'),
                      trailing: Text(device.type, textAlign: TextAlign.end),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      );

