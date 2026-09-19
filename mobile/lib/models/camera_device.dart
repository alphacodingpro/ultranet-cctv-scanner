class CameraDevice {
  const CameraDevice({required this.id, required this.ip, required this.name, this.vendor = 'Unknown', this.model = '', this.ports = const [], this.onvifUrl, this.rtspUrl, this.username = '', this.lastSeen, this.latencyMs});
  final String id, ip, name, vendor, model, username;
  final List<int> ports;
  final String? onvifUrl, rtspUrl;
  final DateTime? lastSeen;
  final int? latencyMs;
  bool get isLikelyCamera => ports.any({554, 8000, 37777, 8899}.contains) || onvifUrl != null;
  bool get hasStream => rtspUrl != null && rtspUrl!.trim().isNotEmpty;
  CameraDevice copyWith({String? id, String? ip, String? name, String? vendor, String? model, List<int>? ports, String? onvifUrl, String? rtspUrl, String? username, DateTime? lastSeen, int? latencyMs}) => CameraDevice(id: id ?? this.id, ip: ip ?? this.ip, name: name ?? this.name, vendor: vendor ?? this.vendor, model: model ?? this.model, ports: ports ?? this.ports, onvifUrl: onvifUrl ?? this.onvifUrl, rtspUrl: rtspUrl ?? this.rtspUrl, username: username ?? this.username, lastSeen: lastSeen ?? this.lastSeen, latencyMs: latencyMs ?? this.latencyMs);
  Map<String, Object?> toJson() => {'id': id, 'ip': ip, 'name': name, 'vendor': vendor, 'model': model, 'ports': ports, 'onvifUrl': onvifUrl, 'rtspUrl': rtspUrl, 'username': username, 'lastSeen': lastSeen?.toIso8601String(), 'latencyMs': latencyMs};
  factory CameraDevice.fromJson(Map<String, Object?> json) => CameraDevice(id: json['id']! as String, ip: json['ip']! as String, name: (json['name'] as String?) ?? json['ip']! as String, vendor: (json['vendor'] as String?) ?? 'Unknown', model: (json['model'] as String?) ?? '', ports: ((json['ports'] as List?) ?? const []).map((e) => e as int).toList(), onvifUrl: json['onvifUrl'] as String?, rtspUrl: json['rtspUrl'] as String?, username: (json['username'] as String?) ?? '', lastSeen: json['lastSeen'] == null ? null : DateTime.tryParse(json['lastSeen']! as String), latencyMs: json['latencyMs'] as int?);
}
