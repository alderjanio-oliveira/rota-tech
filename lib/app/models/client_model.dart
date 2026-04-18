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
      contractStart: map['contractStart'] != null ? DateTime.tryParse(map['contractStart']) : null,
      expiresAt: map['expiresAt'] != null ? DateTime.tryParse(map['expiresAt']) : null,
      notified: map['notified'] ?? false,
    );
  }

  int get daysToExpire {
    if (expiresAt == null) return 9999;

    final diff = expiresAt!.difference(DateTime.now());
    return (diff.inHours / 24).ceil();
  }
}

enum PaymentStatus { ok, nearDue, overdue }

enum ReminderType { before, dueToday, overdue }
