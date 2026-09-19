import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/camera_device.dart';

class ReportService {
  Future<File> createPdf(List<CameraDevice> devices) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (_) => [
      pw.Header(level: 0, child: pw.Text('UltraNet CCTV Network Report')),
      pw.Text('Generated: ${DateTime.now().toLocal()}'), pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(headers: const ['IP', 'Name', 'Vendor', 'Ports', 'Latency', 'ONVIF', 'RTSP'], data: devices.map((d) => [d.ip, d.name, d.vendor, d.ports.join(', '), d.latencyMs == null ? '-' : '${d.latencyMs} ms', d.onvifUrl == null ? 'No' : 'Yes', d.hasStream ? 'Configured' : 'No']).toList()),
      pw.SizedBox(height: 12), pw.Text('Authorized-use report. Passwords and RTSP credentials are excluded.'),
    ]));
    final file = File('${(await getTemporaryDirectory()).path}/ultranet-cctv-report-${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }
  Future<void> sharePdf(List<CameraDevice> devices) async => SharePlus.instance.share(ShareParams(files: [XFile((await createPdf(devices)).path)], subject: 'UltraNet CCTV Report'));
  Future<void> shareCsv(List<CameraDevice> devices) async {
    String q(String value) => '"${value.replaceAll('"', '""')}"';
    final rows = <String>['IP,Name,Vendor,Ports,LatencyMs,ONVIF,RTSPConfigured', ...devices.map((d) => [d.ip, d.name, d.vendor, d.ports.join('|'), '${d.latencyMs ?? ''}', '${d.onvifUrl != null}', '${d.hasStream}'].map(q).join(','))];
    final file = File('${(await getTemporaryDirectory()).path}/ultranet-cctv-report-${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(rows.join('\n'), flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'UltraNet CCTV CSV'));
  }
}
