class AppNotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final int? deviceId;
  final String? deviceName;
  final double? totalKm;
  final double? tripKm;
  final double? targetKm;
  final double? remainingKm;

  AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.deviceId,
    this.deviceName,
    this.totalKm,
    this.tripKm,
    this.targetKm,
    this.remainingKm,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'totalKm': totalKm,
      'tripKm': tripKm,
      'targetKm': targetKm,
      'remainingKm': remainingKm,
    };
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      read: json['read'] ?? false,
      deviceId: _toInt(json['deviceId']),
      deviceName: json['deviceName'],
      totalKm: _toDouble(json['totalKm']),
      tripKm: _toDouble(json['tripKm']),
      targetKm: _toDouble(json['targetKm']),
      remainingKm: _toDouble(json['remainingKm']),
    );
  }

  AppNotificationModel copyWith({bool? read}) {
    return AppNotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read ?? this.read,
      deviceId: deviceId,
      deviceName: deviceName,
      totalKm: totalKm,
      tripKm: tripKm,
      targetKm: targetKm,
      remainingKm: remainingKm,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
