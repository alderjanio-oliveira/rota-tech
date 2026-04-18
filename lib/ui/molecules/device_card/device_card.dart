import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String deviceName;
  final String? address;
  final double totalDistance;
  final bool? ignitionStatus;
  final String? status;
  final bool loading;
  final VoidCallback onTap;
  final List<Widget>? actions;

  const DeviceCard({
    super.key,
    required this.deviceName,
    this.address,
    required this.totalDistance,
    this.ignitionStatus,
    this.status,
    required this.loading,
    required this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = ignitionStatus == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            /// 🚗 ICON
            CircleAvatar(
              radius: 24,
              backgroundColor: isOn ? Colors.green : Colors.grey,
              child: const Icon(Icons.directions_car, color: Colors.white),
            ),

            const SizedBox(width: 12),

            /// 📄 INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    isOn ? "Ligado" : "Desligado",
                    style: TextStyle(
                      color: isOn ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  if (address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],

                  const SizedBox(height: 6),

                  Text(
                    "${(totalDistance / 1000).toStringAsFixed(1)} km",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            /// ⚡ ACTIONS
            Column(
              children: actions ?? [],
            ),
          ],
        ),
      ),
    );
  }
}
