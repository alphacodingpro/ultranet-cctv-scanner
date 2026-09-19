import ipaddress

import pytest

from ultranet_scanner.scanner import classify, default_subnet, scan_subnet


def test_default_subnet():
    assert default_subnet("192.168.10.45") == ipaddress.ip_network("192.168.10.0/24")


@pytest.mark.parametrize(
    ("ports", "vendor"),
    [([80, 8000], "Hikvision-family"), ([554, 37777], "Dahua-family"), ([554], "RTSP device")],
)
def test_classify(ports, vendor):
    assert classify(ports)[1] == vendor


def test_rejects_broad_scan():
    with pytest.raises(ValueError):
        scan_subnet(ipaddress.ip_network("10.0.0.0/16"))

