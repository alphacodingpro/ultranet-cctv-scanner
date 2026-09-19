import 'dart:io';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync()) {
    var text = manifest.readAsStringSync();
    const permissions = '''
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />''';
    if (!text.contains('CHANGE_WIFI_MULTICAST_STATE')) text = text.replaceFirst('<manifest xmlns:android="http://schemas.android.com/apk/res/android">', '<manifest xmlns:android="http://schemas.android.com/apk/res/android">$permissions');
    if (!text.contains('android:usesCleartextTraffic=')) text = text.replaceFirst('<application', '<application android:usesCleartextTraffic="true" android:allowBackup="false"');
    manifest.writeAsStringSync(text);
  }

  final plist = File('ios/Runner/Info.plist');
  if (plist.existsSync()) {
    var text = plist.readAsStringSync();
    const keys = '''
\t<key>NSLocalNetworkUsageDescription</key>
\t<string>UltraNet scans authorized local networks for CCTV cameras and recorders.</string>
\t<key>NSAppTransportSecurity</key>
\t<dict><key>NSAllowsArbitraryLoads</key><true/></dict>
''';
    if (!text.contains('NSLocalNetworkUsageDescription')) text = text.replaceFirst('</dict>', '$keys</dict>');
    plist.writeAsStringSync(text);
  }
}
