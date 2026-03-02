import 'package:app_tracking/data/device_model.dart';
import 'package:flutter/material.dart';

class TripItemMolecule extends StatelessWidget {
  final DeviceModel device;
  const TripItemMolecule({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text("Distância: ${device.tripKm!.toStringAsFixed(2)} km"),
              ],
            ),
            IconButton(onPressed: () {}, icon: Icon(Icons.delete_outlined, size: 16)),
          ],
        ),
      ),
    );
  }
}
