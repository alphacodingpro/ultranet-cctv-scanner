import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camera_device.dart';

class StorageService {
  static const _devicesKey = 'saved_devices_v1';
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  Future<List<CameraDevice>> loadDevices() async {
    final raw = (await SharedPreferences.getInstance()).getString(_devicesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => CameraDevice.fromJson(Map<String, Object?>.from(e as Map))).toList();
  }
  Future<void> saveDevices(List<CameraDevice> devices) async => (await SharedPreferences.getInstance()).setString(_devicesKey, jsonEncode(devices.map((e) => e.toJson()).toList()));
  Future<void> savePassword(String id, String password) => _secure.write(key: 'camera_password_$id', value: password);
  Future<String> password(String id) async => await _secure.read(key: 'camera_password_$id') ?? '';
  Future<void> deletePassword(String id) => _secure.delete(key: 'camera_password_$id');
}
