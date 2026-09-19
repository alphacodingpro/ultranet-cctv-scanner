from __future__ import annotations

import ipaddress
import sys

from PySide6.QtCore import QThread, Signal
from PySide6.QtWidgets import (
    QApplication, QLabel, QLineEdit, QMainWindow, QMessageBox, QPushButton,
    QTableWidget, QTableWidgetItem, QVBoxLayout, QWidget,
)

from .scanner import default_subnet, detect_local_ipv4, scan_subnet


class ScanWorker(QThread):
    found = Signal(object)
    failed = Signal(str)

    def __init__(self, subnet: str):
        super().__init__()
        self.subnet = subnet

    def run(self) -> None:
        try:
            scan_subnet(ipaddress.ip_network(self.subnet, strict=False), self.found.emit)
        except Exception as exc:
            self.failed.emit(str(exc))


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("UltraNet CCTV Scanner")
        self.resize(940, 600)
        try:
            subnet = str(default_subnet(detect_local_ipv4()))
        except OSError:
            subnet = "192.168.1.0/24"

        self.status = QLabel("Connect to the authorized client network, then scan.")
        self.subnet = QLineEdit(subnet)
        self.scan_button = QPushButton("Scan Network")
        self.scan_button.clicked.connect(self.start_scan)
        self.table = QTableWidget(0, 4)
        self.table.setHorizontalHeaderLabels(["IP address", "Type", "Vendor hint", "Open ports"])
        self.table.horizontalHeader().setStretchLastSection(True)

        layout = QVBoxLayout()
        layout.addWidget(QLabel("Current subnet (MVP limit: /24):"))
        layout.addWidget(self.subnet)
        layout.addWidget(self.scan_button)
        layout.addWidget(self.status)
        layout.addWidget(self.table)
        root = QWidget()
        root.setLayout(layout)
        self.setCentralWidget(root)
        self.worker = None

    def start_scan(self) -> None:
        try:
            network = ipaddress.ip_network(self.subnet.text().strip(), strict=False)
            if network.version != 4 or network.prefixlen < 24:
                raise ValueError("Only an IPv4 /24 or smaller subnet is allowed in this MVP.")
        except ValueError as exc:
            QMessageBox.warning(self, "Invalid subnet", str(exc))
            return
        self.table.setRowCount(0)
        self.scan_button.setEnabled(False)
        self.status.setText(f"Scanning {network}…")
        self.worker = ScanWorker(str(network))
        self.worker.found.connect(self.add_device)
        self.worker.failed.connect(self.scan_failed)
        self.worker.finished.connect(self.scan_finished)
        self.worker.start()

    def add_device(self, device) -> None:
        row = self.table.rowCount()
        self.table.insertRow(row)
        values = (device.ip, device.kind, device.vendor_hint, ", ".join(map(str, device.open_ports)))
        for col, value in enumerate(values):
            self.table.setItem(row, col, QTableWidgetItem(value))

    def scan_failed(self, message: str) -> None:
        QMessageBox.critical(self, "Scan failed", message)

    def scan_finished(self) -> None:
        self.scan_button.setEnabled(True)
        self.status.setText(f"Scan complete — {self.table.rowCount()} responsive device(s) found.")


def main() -> None:
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = MainWindow()
    window.show()
    raise SystemExit(app.exec())


if __name__ == "__main__":
    main()

