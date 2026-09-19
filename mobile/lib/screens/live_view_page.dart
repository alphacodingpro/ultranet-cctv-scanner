import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../app_state.dart';
import '../models/camera_device.dart';

Future<String> authenticatedUrl(AppState state, CameraDevice device) async {
  final base = Uri.parse(device.rtspUrl!); final pass = await state.storage.password(device.id);
  if (device.username.isEmpty || pass.isEmpty) return device.rtspUrl!;
  final authority = '${Uri.encodeComponent(device.username)}:${Uri.encodeComponent(pass)}@${base.host}${base.hasPort ? ':${base.port}' : ''}';
  return '${base.scheme}://$authority${base.path}${base.hasQuery ? '?${base.query}' : ''}';
}

class LiveViewPage extends StatefulWidget {
  const LiveViewPage({super.key, required this.state, required this.device});
  final AppState state; final CameraDevice device;
  @override State<LiveViewPage> createState() => _LiveViewPageState();
}
class _LiveViewPageState extends State<LiveViewPage> {
  VlcPlayerController? controller; String? error;
  @override void initState() { super.initState(); _start(); }
  Future<void> _start() async {
    try { final url = await authenticatedUrl(widget.state, widget.device); if (!mounted) return; setState(() => controller = VlcPlayerController.network(url, hwAcc: HwAcc.auto, autoPlay: true, options: VlcPlayerOptions())); }
    catch (e) { if (mounted) setState(() => error = '$e'); }
  }
  @override void dispose() { controller?.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.device.name)), body: Center(child: error != null ? Text(error!) : controller == null ? const CircularProgressIndicator() : Column(mainAxisSize: MainAxisSize.min, children: [VlcPlayer(controller: controller!, aspectRatio: 16/9, placeholder: const Center(child: CircularProgressIndicator())), const SizedBox(height: 12), Text('${widget.device.ip} · ${widget.device.vendor}'), Wrap(children: [IconButton(onPressed: controller!.play, icon: const Icon(Icons.play_arrow)), IconButton(onPressed: controller!.pause, icon: const Icon(Icons.pause)), IconButton(onPressed: () => controller!.setVolume(0), icon: const Icon(Icons.volume_off)), IconButton(onPressed: () => controller!.setVolume(100), icon: const Icon(Icons.volume_up))])])));
}

class LiveGridPage extends StatelessWidget {
  const LiveGridPage({super.key, required this.state}); final AppState state;
  @override Widget build(BuildContext context) {
    final streams = state.devices.where((d) => d.hasStream).toList();
    return Scaffold(appBar: AppBar(title: const Text('Multi-camera Live')), body: streams.isEmpty ? const Center(child: Text('Pehle cameras ke RTSP URLs configure karein.')) : GridView.builder(padding: const EdgeInsets.all(8), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: streams.length == 1 ? 1 : 2, childAspectRatio: 16/11), itemCount: streams.length, itemBuilder: (_, i) => _GridTile(state: state, device: streams[i])));
  }
}
class _GridTile extends StatefulWidget { const _GridTile({required this.state, required this.device}); final AppState state; final CameraDevice device; @override State<_GridTile> createState() => _GridTileState(); }
class _GridTileState extends State<_GridTile> {
  VlcPlayerController? controller;
  @override void initState() { super.initState(); authenticatedUrl(widget.state, widget.device).then((url) { if (mounted) setState(() => controller = VlcPlayerController.network(url, hwAcc: HwAcc.auto, autoPlay: true, options: VlcPlayerOptions())); }); }
  @override void dispose() { controller?.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Card(clipBehavior: Clip.antiAlias, child: Column(children: [Expanded(child: controller == null ? const Center(child: CircularProgressIndicator()) : VlcPlayer(controller: controller!, aspectRatio: 16/9, placeholder: const Center(child: CircularProgressIndicator()))), Padding(padding: const EdgeInsets.all(6), child: Text(widget.device.name, maxLines: 1, overflow: TextOverflow.ellipsis))]));
}
