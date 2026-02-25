import 'package:app_tracking/ui/controllers/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  final int? deviceId;
  final double height;

  const MapWidget({super.key, this.deviceId, this.height = 300});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final controller = Get.find<MapCustomController>();
  final MapController mapController = MapController();

  bool _initialCameraSet = false;

  @override
  void initState() {
    super.initState();

    controller.init(deviceId: widget.deviceId);

    controller.onPositionUpdated = (position) {
      if (controller.devices.length == 1) {
        mapController.move(position, mapController.camera.zoom);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: FlutterMap(
        mapController: mapController,
        options: const MapOptions(),
        children: [
          TileLayer(
            urlTemplate: 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=xvu6cMMOUoNcxzaLO3IE',
            userAgentPackageName: 'com.example.app_tracking',
          ),

          // =========================
          // 🔵 TRILHAS
          // =========================
          Obx(() {
            if (controller.trails.isEmpty) {
              return const SizedBox();
            }

            return PolylineLayer(
              polylines: controller.trails.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
                return Polyline(points: entry.value, strokeWidth: 4, color: Colors.blueAccent);
              }).toList(),
            );
          }),

          // =========================
          // 🚗 MARKERS
          // =========================
          Obx(() {
            final validDevices = controller.devices.where((d) => d.latitude != 0 && d.longitude != 0).toList();

            if (validDevices.isEmpty) {
              return const SizedBox();
            }

            // 🔥 ZOOM APENAS UMA VEZ
            if (!_initialCameraSet) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _setInitialZoom(validDevices);
              });
              _initialCameraSet = true;
            }

            return MarkerLayer(
              markers: validDevices.map((d) {
                return Marker(
                  width: 60,
                  height: 60,
                  point: LatLng(d.latitude, d.longitude),
                  child: Transform.rotate(
                    angle: d.heading * (pi / 180),
                    child: Icon(Icons.motorcycle, size: 40, color: d.ignition ? Colors.green : Colors.grey),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // ===============================
  // 🎯 ZOOM INICIAL SEGURO
  // ===============================
  void _setInitialZoom(List validDevices) {
    if (validDevices.isEmpty) return;

    if (validDevices.length == 1) {
      final d = validDevices.first;

      mapController.move(LatLng(d.latitude, d.longitude), 17);
    } else {
      final points = validDevices.map((d) => LatLng(d.latitude, d.longitude)).toList();

      if (points.isEmpty) return;

      final bounds = LatLngBounds.fromPoints(points);

      mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    }
  }
}
