#!/usr/bin/env bash
set -euo pipefail
python3 -m pip install -e '.[dev]'
pyinstaller --noconfirm --clean --windowed --name "UltraNet CCTV Scanner" src/ultranet_scanner/app.py

