import 'package:flutter/foundation.dart';
import 'models/camera_device.dart';
import 'services/discovery_service.dart';
import 'services/storage_service.dart';

class AppState extends ChangeNotifier {
  AppState({DiscoveryService? discovery, StorageService? storage}) : discovery = discovery ?? DiscoveryService(), storage = storage ?? StorageService();
  final DiscoveryService discovery;
  final StorageService storage;
  final List<CameraDevice> devices = [];
  bool scanning = false;
  String status = 'Site Wi-Fi connect karke Scan dabayein.';
  Future<void> initialize() async { devices..clear()..addAll(await storage.loadDevices()); notifyListeners(); }
  Future<void> scan() async {
    if (scanning) return;
    scanning = true; status = 'Network scan ho raha hai…'; notifyListeners();
    try {
      await for (final result in discovery.scan()) {
        final index = devices.indexWhere((d) => d.ip == result.ip);
        if (index < 0) { devices.add(result); } else {
          final old = devices[index];
          devices[index] = result.copyWith(id: old.id, name: old.name, rtspUrl: old.rtspUrl, username: old.username, model: old.model);
        }
        status = '${devices.length} device(s) mile'; notifyListeners();
      }
      await storage.saveDevices(devices); status = 'Scan complete — ${devices.length} device(s).';
    } catch (error) { status = error.toString().replaceFirst('Bad state: ', ''); }
    finally { scanning = false; notifyListeners(); }
  }
  void cancelScan() { discovery.cancel(); status = 'Scan cancel kiya gaya.'; notifyListeners(); }
  Future<void> upsert(CameraDevice device, {String? password}) async {
    final index = devices.indexWhere((d) => d.id == device.id || d.ip == device.ip);
    if (index < 0) {
      devices.add(device);
    } else {
      devices[index] = device;
    }
    if (password != null && password.isNotEmpty) await storage.savePassword(device.id, password);
    await storage.saveDevices(devices); notifyListeners();
  }
  Future<void> remove(CameraDevice device) async { devices.removeWhere((d) => d.id == device.id); await storage.deletePassword(device.id); await storage.saveDevices(devices); notifyListeners(); }
}
