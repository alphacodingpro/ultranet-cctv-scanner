# UltraNet CCTV Scanner

One-click desktop CCTV discovery MVP for authorized local networks. The app automatically proposes the laptop's current `/24`, probes common HTTP/RTSP/vendor ports, and progressively lists likely cameras and recorders.

## Current MVP

- Native desktop UI; no manually started server
- Automatic local IPv4/subnet suggestion
- Safe `/24` scan limit
- Common CCTV port discovery
- Hikvision-family, Dahua-family, and RTSP hints
- Windows and macOS PyInstaller builds through GitHub Actions
- Flutter mobile MVP source for Android and iPhone (`mobile/`)

This first milestone does **not** yet authenticate to cameras or display live video. Those are the next phase after discovery is tested on real Hikvision, Dahua, and Uniview networks.

The mobile app runs scanning directly on the phone and does not require the desktop app or a server. See `mobile/README.md` for native Android/iOS bootstrap and permission steps.

## Run for development

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
ultranet-scanner
```

Windows activation: `.venv\\Scripts\\activate`.

## Build one-click app

- macOS/Linux: `bash scripts/build.sh`
- Windows PowerShell: `scripts\\build.ps1`

Output is created in `dist/`. GitHub Actions builds on its own operating system; it does not cross-compile.

## Authorized use only

Use only on networks and devices you own or have explicit permission to test. The scanner does not bypass passwords or camera authentication.
