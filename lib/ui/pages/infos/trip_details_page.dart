import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/pages/infos/molecule/trip_item_molecule.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TripDetailsPage extends StatelessWidget {
  final VehicleState devices = Get.find<VehicleState>();
  TripDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text("Detalhes do Trip")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: (devices.list).where((device) => device.tripKm != null).map((e) => TripItemMolecule(device: e)).toList(),
        ),
      ),
    );
  }
}
