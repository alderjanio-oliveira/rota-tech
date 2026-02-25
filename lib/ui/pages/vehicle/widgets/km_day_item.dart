import 'package:app_tracking/ui/models/daily_distance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KmDayItem extends StatelessWidget {
  final DailyDistance item;

  const KmDayItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(DateFormat('dd/MM/yyyy').format(item.day)),
        trailing: Text(
          '${item.km.toStringAsFixed(2)} km',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
