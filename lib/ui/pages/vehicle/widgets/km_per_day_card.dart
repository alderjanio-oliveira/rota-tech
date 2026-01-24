import 'package:flutter/material.dart';

class KmPerDayCard extends StatelessWidget {
  final double km;

  const KmPerDayCard({super.key, required this.km});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quilometragem Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("${km.toStringAsFixed(2)} km", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
