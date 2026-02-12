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
      // 🔥 Só acompanha automaticamente se for 1 device
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

          // 🔥 MARKERS REATIVOS
          Obx(() {
            if (controller.devices.isEmpty) {
              return const SizedBox();
            }

            // zoom inicial apenas quando devices chegar
            if (!_initialCameraSet) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _setInitialZoom();
              });

              _initialCameraSet = true;
            }

            return MarkerLayer(
              markers: controller.devices.map((d) {
                return Marker(
                  width: 60,
                  height: 60,
                  point: LatLng(d.latitude, d.longitude),
                  child: Icon(Icons.add_location_rounded, size: 40, color: d.ignition ? Colors.green : Colors.grey),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // ===============================
  // ZOOM INICIAL (UMA VEZ)
  // ===============================
  void _setInitialZoom() {
    final devices = controller.devices;

    if (devices.length == 1) {
      final d = devices.first;

      mapController.move(LatLng(d.latitude, d.longitude), 17);
    } else {
      final bounds = LatLngBounds.fromPoints(devices.map((d) => LatLng(d.latitude, d.longitude)).toList());

      mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    }
  }
}
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       if (controller.loading.value) {
//         return const Center(child: CircularProgressIndicator());
//       }

//       if (controller.devices.isEmpty) {
//         return const Center(child: Text("Nenhuma posição encontrada"));
//       }

//       // 🔥 ZOOM APENAS UMA VEZ
//       if (!_initialCameraSet) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _setInitialZoom();
//         });

//         _initialCameraSet = true;
//       }

//       return SizedBox(
//         height: widget.height,
//         child: FlutterMap(
//           mapController: mapController,
//           options: const MapOptions(),
//           children: [
//             TileLayer(
//               urlTemplate: 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=xvu6cMMOUoNcxzaLO3IE',
//               userAgentPackageName: 'com.example.app_tracking',
//             ),

//             MarkerLayer(
//               markers: controller.devices.map((d) {
//                 return Marker(
//                   width: 60,
//                   height: 60,
//                   point: LatLng(d.latitude, d.longitude),
//                   child: Transform.rotate(
//                     angle: d.heading * (pi / 180),
//                     child: Icon(Icons.motorcycle, size: 40, color: d.ignition ? Colors.green : Colors.grey),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   // ===============================
//   // ZOOM INICIAL (UMA VEZ)
//   // ===============================
//   void _setInitialZoom() {
//     final devices = controller.devices;

//     if (devices.length == 1) {
//       final d = devices.first;

//       mapController.move(LatLng(d.latitude, d.longitude), 17);
//     } else {
//       final bounds = LatLngBounds.fromPoints(devices.map((d) => LatLng(d.latitude, d.longitude)).toList());

//       mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
//     }
//   }
// }
