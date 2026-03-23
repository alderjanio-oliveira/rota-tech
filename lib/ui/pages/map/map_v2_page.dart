import 'package:app_tracking/ui/controllers/map_controller.dart';
import 'package:app_tracking/ui/pages/map/molecule/vehicle_card_molecule.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class MapUberPage extends StatefulWidget {
  const MapUberPage({super.key});

  @override
  State<MapUberPage> createState() => _MapUberPageState();
}

class _MapUberPageState extends State<MapUberPage> {
  final controller = Get.find<MapCustomController>();
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          /// 🗺️ MAPA
          Obx(() {
            return FlutterMap(
              mapController: mapController,
              options: const MapOptions(),
              children: [
                TileLayer(
                  urlTemplate: 'https://api.maptiler.com/maps/bright-v2/{z}/{x}/{y}.png?key=xvu6cMMOUoNcxzaLO3IE',
                  userAgentPackageName: 'com.example.app_tracking',
                ),

                /// 🌙 overlay dark PRO
                if (isDark) Container(color: Colors.black.withOpacity(0.35)),

                /// 🚗 MARKERS
                MarkerLayer(
                  markers: controller.devices.map((d) {
                    return Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(d.latitude, d.longitude),
                      child: Transform.rotate(
                        angle: d.heading * (pi / 180),
                        child: const Icon(
                          Icons.navigation,
                          size: 28,
                          color: Colors.green,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }),

          /// 📍 BOTÃO CENTRALIZAR
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton(
              heroTag: 'center',
              onPressed: _centerMap,
              child: const Icon(Icons.my_location),
            ),
          ),

          /// 🚗 CARD DO VEÍCULO
          Align(
            alignment: Alignment.bottomCenter,
            child: Obx(() {
              if (controller.devices.isEmpty) return const SizedBox();

              final d = controller.devices.first;

              return VehicleCard(device: d);
            }),
          ),
        ],
      ),
    );
  }

  void _centerMap() {
    if (controller.devices.isEmpty) return;

    final d = controller.devices.first;

    mapController.move(
      LatLng(d.latitude, d.longitude),
      17,
    );
  }
}
