# UltraNet CCTV Scanner Mobile

Flutter MVP for Android and iPhone. It runs the scanner directly on the phone—no laptop, cloud server, or manually started backend is required.

## Bootstrap native projects

Install Flutter, open this directory, then run:

```bash
flutter create --platforms=android,ios --org com.ultranetsecurity .
flutter pub get
flutter run
```

After `flutter create`, add this key inside `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>UltraNet scans authorized local networks for CCTV cameras and recorders.</string>
```

Android needs `android.permission.INTERNET`, which the Flutter template supplies. Local-network behavior must be tested on physical Android and iPhone devices; simulators are not a valid CCTV discovery test.

## MVP limitations

- Scans the phone's current Wi-Fi `/24` only.
- Detects common HTTP, RTSP, Hikvision-family, and Dahua-family ports.
- Does not bypass authentication.
- ONVIF multicast, credentials, RTSP playback, saved sites, and PDF reports are next milestones.

