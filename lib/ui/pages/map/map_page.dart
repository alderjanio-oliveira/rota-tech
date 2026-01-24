import 'package:app_tracking/ui/controllers/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends GetView<MapCustomController> {
  final int? deviceId;

  const MapPage({super.key, this.deviceId});

  @override
  Widget build(BuildContext context) {
    // final controller = Get.put(MapController(Get.find()));

    // Carrega devices
    controller.loadDevices(deviceId: deviceId);

    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.devices.isEmpty) {
        return const Center(child: Text("Nenhuma posição encontrada"));
      }

      return SizedBox(
        height: 300,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              controller.devices.first.latitude,
              controller.devices.first.longitude,
            ),
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),

            // MARKERS
            MarkerLayer(
              markers: controller.devices.map((d) {
                return Marker(
                  width: 50,
                  height: 50,
                  point: LatLng(d.latitude, d.longitude),
                  child: GestureDetector(
                    onTap: () {
                      Get.snackbar("Veículo", d.name);
                    },
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: d.ignition ? Colors.green : Colors.red,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}
