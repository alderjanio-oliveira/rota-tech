import 'package:app_tracking/data/device_model.dart';

class ClientModel {
  final int id;
  final String name;
  final String? phone;
  final DateTime? contractStart;
  final DateTime? expiresAt;
  final bool notified;
  final String? email;
  List<DeviceModel>? devices;

  ClientModel({
    required this.id,
    required this.name,
    this.phone,
    this.contractStart,
    this.expiresAt,
    required this.notified,
    this.email,
    this.devices,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      contractStart: _parseBillingDate(map['contractStart']),
      expiresAt: _parseBillingDate(map['expiresAt']),
      notified: map['notified'] ?? false,
    );
  }

  ClientModel copyWith({
    String? name,
    String? phone,
    DateTime? contractStart,
    DateTime? expiresAt,
    bool? notified,
    String? email,
    List<DeviceModel>? devices,
  }) {
    return ClientModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      contractStart: contractStart ?? this.contractStart,
      expiresAt: expiresAt ?? this.expiresAt,
      notified: notified ?? this.notified,
      email: email ?? this.email,
      devices: devices ?? this.devices,
    );
  }

  static DateTime? _parseBillingDate(dynamic value) {
    if (value == null) return null;

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;

    final date = parsed.isUtc ? parsed.toUtc() : parsed;
    return DateTime(date.year, date.month, date.day);
  }

  int get daysToExpire {
    if (expiresAt == null) return 9999;

    final expiration = expiresAt!.toLocal();
    final expirationDate = DateTime(expiration.year, expiration.month, expiration.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return expirationDate.difference(today).inDays;
  }
}

enum PaymentStatus { ok, nearDue, overdue }

enum ReminderType { before, dueToday, overdue }
