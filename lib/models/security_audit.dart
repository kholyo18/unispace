class SecurityAudit {
  const SecurityAudit({
    required this.timestampUtc,
    required this.timezoneOffsetMinutes,
    required this.deviceManufacturer,
    required this.deviceModel,
    required this.deviceName,
    required this.osName,
    required this.osVersion,
    required this.appVersion,
    required this.buildNumber,
    required this.ipAddress,
    required this.networkType,
    required this.locationApprox,
  });

  final DateTime timestampUtc;
  final int timezoneOffsetMinutes;
  final String? deviceManufacturer;
  final String? deviceModel;
  final String? deviceName;
  final String? osName;
  final String? osVersion;
  final String? appVersion;
  final String? buildNumber;
  final String? ipAddress;
  final String networkType;
  final String? locationApprox;

  Map<String, dynamic> toJson() => {
        'timestamp': timestampUtc.toIso8601String(),
        'timezoneOffsetMinutes': timezoneOffsetMinutes,
        'deviceManufacturer': deviceManufacturer,
        'deviceModel': deviceModel,
        'deviceName': deviceName,
        'osName': osName,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'buildNumber': buildNumber,
        'ipAddress': ipAddress,
        'networkType': networkType,
        'locationApprox': locationApprox,
      };

  factory SecurityAudit.fromJson(Map<String, dynamic> json) {
    return SecurityAudit(
      timestampUtc: DateTime.tryParse(json['timestamp'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      timezoneOffsetMinutes: (json['timezoneOffsetMinutes'] as num?)?.toInt() ?? 0,
      deviceManufacturer: json['deviceManufacturer'] as String?,
      deviceModel: json['deviceModel'] as String?,
      deviceName: json['deviceName'] as String?,
      osName: json['osName'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      buildNumber: json['buildNumber'] as String?,
      ipAddress: json['ipAddress'] as String?,
      networkType: json['networkType'] as String? ?? 'unknown',
      locationApprox: json['locationApprox'] as String?,
    );
  }

  String get maskedIp {
    final value = ipAddress?.trim();
    if (value == null || value.isEmpty) return 'غير متوفر';

    if (value.contains('.')) {
      final parts = value.split('.');
      if (parts.length == 4) {
        return '${parts[0]}.***.***.${parts[3]}';
      }
    }

    if (value.contains(':')) {
      final parts = value.split(':').where((part) => part.isNotEmpty).toList();
      if (parts.length >= 2) {
        return '${parts.first}:****:${parts.last}';
      }
    }

    return '***';
  }
}
