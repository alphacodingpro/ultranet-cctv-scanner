import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../app_state.dart';
import '../models/camera_device.dart';

class CameraFormPage extends StatefulWidget {
  const CameraFormPage({super.key, required this.state, this.device});
  final AppState state;
  final CameraDevice? device;
  @override State<CameraFormPage> createState() => _CameraFormPageState();
}

class _CameraFormPageState extends State<CameraFormPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, ip, model, username, password, rtsp;
  late String vendor;
  @override void initState() {
    super.initState(); final d = widget.device;
    name = TextEditingController(text: d?.name ?? ''); ip = TextEditingController(text: d?.ip ?? '');
    model = TextEditingController(text: d?.model ?? ''); username = TextEditingController(text: d?.username ?? 'admin');
    password = TextEditingController(); rtsp = TextEditingController(text: d?.rtspUrl ?? ''); vendor = d?.vendor ?? 'Unknown';
    if (d != null) widget.state.storage.password(d.id).then((v) { if (mounted) password.text = v; });
  }
  @override void dispose() { for (final c in [name, ip, model, username, password, rtsp]) { c.dispose(); } super.dispose(); }
  void preset() {
    final host = ip.text.trim();
    rtsp.text = switch (vendor) {
      'Hikvision-family' => 'rtsp://$host:554/Streaming/Channels/101',
      'Dahua-family' => 'rtsp://$host:554/cam/realmonitor?channel=1&subtype=0',
      'Uniview-family' => 'rtsp://$host:554/media/video1',
      _ => 'rtsp://$host:554/',
    };
  }
  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final old = widget.device;
    final device = CameraDevice(id: old?.id ?? const Uuid().v4(), ip: ip.text.trim(), name: name.text.trim().isEmpty ? ip.text.trim() : name.text.trim(), vendor: vendor, model: model.text.trim(), ports: old?.ports ?? const [554], onvifUrl: old?.onvifUrl, rtspUrl: rtsp.text.trim(), username: username.text.trim(), lastSeen: old?.lastSeen, latencyMs: old?.latencyMs);
    await widget.state.upsert(device, password: password.text); if (mounted) Navigator.pop(context, device);
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.device == null ? 'Add Camera' : 'Camera Setup')),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Camera name')),
      TextFormField(controller: ip, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'IP address'), validator: (v) => v == null || v.trim().split('.').length != 4 ? 'Valid IPv4 address dein' : null),
      DropdownButtonFormField(initialValue: vendor, decoration: const InputDecoration(labelText: 'Brand/family'), items: const ['Unknown','Hikvision-family','Dahua-family','Uniview-family','RTSP device'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => vendor = v!)),
      TextFormField(controller: model, decoration: const InputDecoration(labelText: 'Model (optional)')),
      TextFormField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
      TextFormField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password (encrypted on device)')),
      Row(children: [Expanded(child: TextFormField(controller: rtsp, decoration: const InputDecoration(labelText: 'RTSP URL'), validator: (v) => v == null || !v.startsWith('rtsp://') ? 'RTSP URL rtsp:// se start honi chahiye' : null)), IconButton(onPressed: preset, tooltip: 'Use brand preset', icon: const Icon(Icons.auto_fix_high))]),
      const SizedBox(height: 20), FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('Save Camera')),
    ])),
  );
}
