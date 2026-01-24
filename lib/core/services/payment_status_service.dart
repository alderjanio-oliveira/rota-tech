import 'package:app_tracking/app/models/client_model.dart';
import 'package:flutter/material.dart';

class PaymentStatusService {
  PaymentStatus getStatus(ClientModel client, DateTime now) {
    final dueDate = DateTime(now.year, now.month, client.expiresAt?.day ?? now.day);
    final diff = dueDate.difference(now).inDays;

    if (diff >= 5) return PaymentStatus.ok;
    if (diff >= 0) return PaymentStatus.nearDue;
    return PaymentStatus.overdue;
  }

  Color statusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.ok:
        return Colors.green;
      case PaymentStatus.nearDue:
        return Colors.orange;
      case PaymentStatus.overdue:
        return Colors.red;
    }
  }
}
