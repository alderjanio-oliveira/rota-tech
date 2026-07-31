import 'package:app_tracking/ui/models/daily_distance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KmDayItem extends StatelessWidget {
  final DailyDistance item;

  const KmDayItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.04))],
      ),
      child: Row(
        children: [
          Icon(Icons.event_outlined, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(DateFormat('dd/MM/yyyy').format(item.day), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Text('${item.km.toStringAsFixed(2)} km', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
