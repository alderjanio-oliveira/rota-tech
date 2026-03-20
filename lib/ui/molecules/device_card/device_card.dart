// lib/ui/molecules/device_card/device_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DeviceCard extends StatelessWidget {
  final int id;
  final String deviceName;
  final String status;
  final int? lastUpdate;
  final VoidCallback? onTap;
  final List<Widget> actions;
  final bool? ignitionStatus;
  final double totalDistance;
  final VoidCallback? resetTrip;
  final String? address;
  final bool? charge;
  final RxBool loading;

  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.status,
    this.lastUpdate,
    this.onTap,
    this.actions = const [],
    required this.ignitionStatus,
    required this.totalDistance,
    required this.id,
    this.resetTrip,
    this.address,
    this.charge = true,
    required this.loading,
  });

  _choiceKeyColor(bool? status) {
    if (status == null) return Colors.grey;
    return status ? Colors.green : Colors.red;
  }

  _ignitionStatus(bool? status) {
    if (status == null) return Icons.key_rounded;
    return status ? Icons.key_rounded : Icons.key_off_rounded;
  }

  @override
  Widget build(BuildContext context) {
    GetStorage box = GetStorage();
    return ExpansionTile(
      collapsedBackgroundColor: status.toLowerCase() == 'online' ? Colors.green[50] : Colors.red[50],
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (charge == false) const Icon(Icons.battery_alert, color: Colors.red),
          const SizedBox(width: 8),
          IconButton(onPressed: onTap, icon: Icon(Icons.remove_red_eye_sharp)),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Text(
                  deviceName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('${(totalDistance / 1000).toStringAsFixed(2)} km'),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: actions.expand((action) => [action, const SizedBox(width: 8)]).toList()..removeLast()),
          ],
          Expanded(child: Icon(_ignitionStatus(ignitionStatus), color: _choiceKeyColor(ignitionStatus))),
          const SizedBox(width: 8),
        ],
      ),

      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(onTap: onTap, child: Text(address ?? 'loading...')),
            Row(
              children: [
                Chip(label: Text('${(totalDistance / 1000).toStringAsFixed(2)} km')),
                GestureDetector(
                  child: Chip(
                    label: GestureDetector(
                      child: Text(
                        box.read('OffSetTripA$id') != null
                            ? 'TripA: ${((totalDistance - box.read('OffSetTripA$id')) / 1000).toStringAsFixed(2)} km'
                            : 'TipA: ${(totalDistance / 1000).toStringAsFixed(2)} km',
                      ),
                      onLongPress: () => {resetTrip != null ? resetTrip!() : null},
                    ),
                  ),
                ),
              ],
            ),
            if (lastUpdate != null) ...[
              const SizedBox(height: 8),
              Text('Última atualização: $lastUpdate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
      ],
    );
  }
}
