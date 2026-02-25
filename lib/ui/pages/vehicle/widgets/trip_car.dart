import 'package:flutter/material.dart';

class TripCard extends StatelessWidget {
  final String label;
  final String? valueKm;
  final VoidCallback onReset;
  final TextEditingController target;

  const TripCard({
    super.key,
    required this.label,
    required this.valueKm,
    required this.onReset,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${valueKm ?? ' - '} km",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: onReset,
                  child: const Text("Zerar"),
                ),
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.all(0),
              horizontalTitleGap: 0,
              leading: Icon(Icons.warning_sharp, color: Colors.orange),
              title: Text('você será notificado em ${target.text} kms'),
            ),
          ],
        ),
      ),
    );
  }
}
