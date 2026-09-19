# UltraNet CCTV Scanner Mobile

Flutter Android/iPhone application. Scanning and live view run directly on the phone—no laptop, cloud server, or manually started backend is required.

## Implemented

- Current Wi-Fi `/24` scan with progressive results and cancellation
- ONVIF WS-Discovery plus CCTV TCP-port discovery
- Hikvision, Dahua and Uniview family hints
- Manual camera add/edit and vendor RTSP presets
- Passwords stored in Android Keystore / iOS Keychain
- Single-camera VLC RTSP live view with audio controls
- Multi-camera live grid
- Saved inventory and diagnostics (ports, latency, ONVIF, RTSP status)
- PDF and CSV report export without passwords

## Bootstrap native projects

Install Flutter, open this directory, then run:

```bash
flutter create --platforms=android,ios --org com.ultranetsecurity .
dart run tool/configure_native.dart
flutter pub get
flutter run
```

The native configuration script adds Android multicast/network permissions, cleartext RTSP support, iOS local-network permission and iOS transport settings. Run it once after every `flutter create` regeneration.

## Real-world limitations

- Scans the phone's current Wi-Fi `/24` only; guest isolation/VLAN routing still applies.
- Does not bypass authentication. Valid camera credentials are required.
- RTSP paths differ across models, so presets may need manual correction.
- H.265 support and 9/16-grid performance depend on the phone and camera sub-stream settings.
- Signed iPhone installation requires an Apple Developer account and Xcode signing.
