import 'package:flutter/material.dart';
import 'app_state.dart';
import 'models/camera_device.dart';
import 'screens/camera_form_page.dart';
import 'screens/live_view_page.dart';
import 'services/report_service.dart';

Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); final state = AppState(); await state.initialize(); runApp(UltraNetScannerApp(state: state)); }

class UltraNetScannerApp extends StatelessWidget {
  const UltraNetScannerApp({super.key, required this.state}); final AppState state;
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, title: 'UltraNet CCTV Scanner', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff16a34a), brightness: Brightness.dark), useMaterial3: true, inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12))), home: HomePage(state: state));
}

class HomePage extends StatefulWidget { const HomePage({super.key, required this.state}); final AppState state; @override State<HomePage> createState() => _HomePageState(); }
class _HomePageState extends State<HomePage> {
  int tab = 0; final report = ReportService();
  @override void initState() { super.initState(); widget.state.addListener(refresh); }
  void refresh() { if (mounted) setState(() {}); }
  @override void dispose() { widget.state.removeListener(refresh); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('UltraNet CCTV Scanner'), actions: [IconButton(tooltip: 'Add camera', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CameraFormPage(state: widget.state))), icon: const Icon(Icons.add_circle_outline))]), body: IndexedStack(index: tab, children: [_devices(), _dashboard(), _reports()]), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.radar), label: 'Devices'), NavigationDestination(icon: Icon(Icons.grid_view), label: 'Live'), NavigationDestination(icon: Icon(Icons.description), label: 'Reports')]));

  Widget _devices() => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(widget.state.status), const SizedBox(height: 10), FilledButton.icon(onPressed: widget.state.scanning ? widget.state.cancelScan : widget.state.scan, icon: Icon(widget.state.scanning ? Icons.stop : Icons.radar), label: Text(widget.state.scanning ? 'Stop Scan' : 'Scan Current Wi-Fi')), if (widget.state.scanning) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator())])),
    Expanded(child: widget.state.devices.isEmpty ? const Center(child: Text('Koi device saved/discovered nahi.')) : ListView.builder(itemCount: widget.state.devices.length, itemBuilder: (_, i) => _deviceCard(widget.state.devices[i]))),
  ]);

  Widget _deviceCard(CameraDevice d) => Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ExpansionTile(leading: Icon(d.isLikelyCamera ? Icons.videocam : Icons.devices_other, color: d.isLikelyCamera ? Colors.greenAccent : null), title: Text(d.name), subtitle: Text('${d.ip} · ${d.vendor}'), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: [
    _row('Ports', d.ports.isEmpty ? 'ONVIF only' : d.ports.join(', ')), _row('Latency', d.latencyMs == null ? '-' : '${d.latencyMs} ms'), _row('ONVIF', d.onvifUrl ?? 'Not detected'), _row('RTSP', d.hasStream ? 'Configured' : 'Setup required'),
    Wrap(spacing: 8, children: [FilledButton.tonalIcon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CameraFormPage(state: widget.state, device: d))), icon: const Icon(Icons.settings), label: const Text('Setup')), FilledButton.tonalIcon(onPressed: d.hasStream ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveViewPage(state: widget.state, device: d))) : null, icon: const Icon(Icons.play_arrow), label: const Text('Live')), IconButton(tooltip: 'Delete', onPressed: () => _confirmDelete(d), icon: const Icon(Icons.delete_outline))]),
  ]));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 76, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text(value))]));
  Future<void> _confirmDelete(CameraDevice d) async { final yes = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete camera?'), content: Text('${d.name} aur saved password remove hoga.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))])); if (yes == true) await widget.state.remove(d); }

  Widget _dashboard() { final cameras = widget.state.devices.where((d) => d.isLikelyCamera).length; final streams = widget.state.devices.where((d) => d.hasStream).length; return ListView(padding: const EdgeInsets.all(16), children: [Wrap(spacing: 10, runSpacing: 10, children: [_metric('Devices', widget.state.devices.length, Icons.devices), _metric('Cameras', cameras, Icons.videocam), _metric('Live ready', streams, Icons.play_circle)]), const SizedBox(height: 20), FilledButton.icon(onPressed: streams == 0 ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveGridPage(state: widget.state))), icon: const Icon(Icons.grid_view), label: const Text('Open Multi-camera Grid')), const SizedBox(height: 12), const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('9/16 RTSP streams ke liye powerful phone aur camera sub-stream URLs use karein. Main streams low-end phone ko overheat ya crash kar sakti hain.')))]); }
  Widget _metric(String title, int value, IconData icon) => SizedBox(width: 105, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Icon(icon), Text('$value', style: Theme.of(context).textTheme.headlineMedium), Text(title)]))));
  Widget _reports() => ListView(padding: const EdgeInsets.all(16), children: [Text('Network Report', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), const Text('Passwords report mein kabhi include nahi hote.'), const SizedBox(height: 20), FilledButton.icon(onPressed: widget.state.devices.isEmpty ? null : () => report.sharePdf(widget.state.devices), icon: const Icon(Icons.picture_as_pdf), label: const Text('Export & Share PDF')), const SizedBox(height: 10), OutlinedButton.icon(onPressed: widget.state.devices.isEmpty ? null : () => report.shareCsv(widget.state.devices), icon: const Icon(Icons.table_view), label: const Text('Export & Share CSV'))]);
}
