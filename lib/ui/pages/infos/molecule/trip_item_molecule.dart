import 'package:app_tracking/ui/pages/infos/trip_details_page.dart';
import 'package:flutter/material.dart';

class TripItemMolecule extends StatelessWidget {
  final DeviceReminder item;
  final VoidCallback onCancel;

  const TripItemMolecule({super.key, required this.item, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final traveledKm = item.reminder.traveledFor(item.totalDistance) / 1000;
    final targetKm = item.reminder.thresholdDistance / 1000;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.device.name, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(item.reminder.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('${traveledKm.toStringAsFixed(2)} / ${targetKm.toStringAsFixed(0)} km'),
                ],
              ),
            ),
            IconButton(tooltip: 'Cancelar lembrete', onPressed: onCancel, icon: const Icon(Icons.delete_outlined, size: 20)),
          ],
        ),
      ),
    );
  }
}
