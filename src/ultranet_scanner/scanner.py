from __future__ import annotations

import concurrent.futures
import ipaddress
import socket
from dataclasses import dataclass, field
from typing import Callable, Iterable

CAMERA_PORTS = (80, 443, 554, 8000, 8080, 8899, 37777)


@dataclass(slots=True)
class Device:
    ip: str
    open_ports: list[int] = field(default_factory=list)
    kind: str = "Network device"
    vendor_hint: str = "Unknown"

    @property
    def has_rtsp(self) -> bool:
        return 554 in self.open_ports


def classify(ports: Iterable[int]) -> tuple[str, str]:
    found = set(ports)
    if 37777 in found:
        return "Camera / recorder", "Dahua-family"
    if 8000 in found:
        return "Camera / recorder", "Hikvision-family"
    if 554 in found:
        return "Possible camera / recorder", "RTSP device"
    return "Network device", "Unknown"


def detect_local_ipv4() -> str:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect(("192.0.2.1", 80))
        return sock.getsockname()[0]
    finally:
        sock.close()


def default_subnet(ip: str) -> ipaddress.IPv4Network:
    # MVP intentionally limits automatic scans to one /24 to avoid accidental broad scans.
    return ipaddress.ip_network(f"{ip}/24", strict=False)


def probe(ip: str, ports: Iterable[int] = CAMERA_PORTS, timeout: float = 0.18) -> Device | None:
    opened: list[int] = []
    for port in ports:
        try:
            with socket.create_connection((ip, port), timeout=timeout):
                opened.append(port)
        except (TimeoutError, OSError):
            pass
    if not opened:
        return None
    kind, vendor = classify(opened)
    return Device(ip=ip, open_ports=opened, kind=kind, vendor_hint=vendor)


def scan_subnet(
    network: ipaddress.IPv4Network,
    on_result: Callable[[Device], None] | None = None,
    workers: int = 64,
) -> list[Device]:
    if network.prefixlen < 24:
        raise ValueError("MVP safety limit: scan must be /24 or smaller")
    results: list[Device] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(probe, str(host)): host for host in network.hosts()}
        for future in concurrent.futures.as_completed(futures):
            device = future.result()
            if device:
                results.append(device)
                if on_result:
                    on_result(device)
    return sorted(results, key=lambda d: ipaddress.ip_address(d.ip))

