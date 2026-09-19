$ErrorActionPreference = "Stop"
py -m pip install -e ".[dev]"
pyinstaller --noconfirm --clean --windowed --name "UltraNet CCTV Scanner" src/ultranet_scanner/app.py

