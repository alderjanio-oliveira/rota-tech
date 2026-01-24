import 'package:flutter/material.dart';

class TripCard extends StatelessWidget {
  final String label;
  final double valueKm;
  final VoidCallback onReset;

  const TripCard({
    super.key,
    required this.label,
    required this.valueKm,
    required this.onReset,
  });

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
                Text(label, style: const TextStyle(fontSize: 16)),
                Text(
                  "${valueKm.toStringAsFixed(2)} km",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton(onPressed: onReset, child: const Text("Reset")),
          ],
        ),
      ),
    );
  }
}
