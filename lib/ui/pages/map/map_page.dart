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
  bool _followVehicle = true;
  int? _selectedDeviceId;

  @override
  void initState() {
    super.initState();

    controller.init(deviceId: widget.deviceId);

    controller.onPositionUpdated = (position) {
      if (_followVehicle && controller.devices.length == 1) {
        mapController.move(position, mapController.camera.zoom);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          /// 🗺️ MAPA
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              onTap: (_, __) {
                setState(() {
                  _selectedDeviceId = null;
                });
              },
            ),
            children: [
              /// TILE
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/bright-v2/{z}/{x}/{y}.png?key=xvu6cMMOUoNcxzaLO3IE',
                userAgentPackageName: 'com.example.app_tracking',
              ),

              /// DARK OVERLAY
              if (isDark) Container(color: Colors.black.withOpacity(0.35)),

              /// TRILHAS
              Obx(() {
                if (controller.trails.isEmpty) return const SizedBox();

                return PolylineLayer(
                  polylines: controller.trails.entries
                      .where((e) => e.value.isNotEmpty)
                      .map(
                        (e) => Polyline(
                          points: e.value,
                          strokeWidth: 4,
                          color: Colors.blueAccent.withOpacity(0.8),
                        ),
                      )
                      .toList(),
                );
              }),

              /// MARKERS
              Obx(() {
                final validDevices = controller.devices.where((d) => d.latitude != 0 && d.longitude != 0).toList();

                if (validDevices.isEmpty) return const SizedBox();

                if (!_initialCameraSet) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _setInitialZoom(validDevices);
                  });
                  _initialCameraSet = true;
                }

                return MarkerLayer(
                  markers: validDevices.map((d) {
                    final isSelected = _selectedDeviceId == d.id;

                    return Marker(
                      width: 90,
                      height: 70,
                      point: LatLng(d.latitude, d.longitude),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDeviceId = d.id;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: d.heading * (pi / 180),
                              child: _VehicleMarker(
                                isActive: d.ignition,
                                isSelected: isSelected,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),

          /// CONTROLES
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.my_location,
                  onTap: _centerMap,
                ),
                const SizedBox(height: 10),
                _MapButton(
                  icon: _followVehicle ? Icons.gps_fixed : Icons.gps_not_fixed,
                  onTap: () {
                    setState(() => _followVehicle = !_followVehicle);
                  },
                ),
              ],
            ),
          ),

          /// CARD ANIMADO
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Obx(() {
              final device = controller.devices.firstWhereOrNull((d) => d.id == _selectedDeviceId);

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final slide = Tween(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(animation);

                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: device == null
                    ? const SizedBox()
                    : _VehicleInfoCard(
                        key: ValueKey(device.id),
                        device: device,
                      ),
              );
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

  void _setInitialZoom(List validDevices) {
    if (validDevices.isEmpty) return;

    if (validDevices.length == 1) {
      final d = validDevices.first;
      mapController.move(LatLng(d.latitude, d.longitude), 17);
    } else {
      final points = validDevices.map((d) => LatLng(d.latitude, d.longitude)).toList();

      final bounds = LatLngBounds.fromPoints(points);

      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }
}

/// MARKER
class _VehicleMarker extends StatelessWidget {
  final bool isActive;
  final bool isSelected;

  const _VehicleMarker({
    required this.isActive,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      transform: Matrix4.identity()..scale(isSelected ? 1.2 : 1.0),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
        boxShadow: [
          BoxShadow(
            blurRadius: isSelected ? 16 : 8,
            color: Colors.black.withOpacity(0.3),
          ),
        ],
      ),
      child: Icon(
        Icons.navigation_rounded,
        color: color,
        size: 20,
      ),
    );
  }
}

/// CARD
class _VehicleInfoCard extends StatelessWidget {
  final dynamic device;

  const _VehicleInfoCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final isOn = device.ignition == true;

    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isOn ? Colors.green : Colors.grey,
                  child: const Icon(Icons.directions_car, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  isOn ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: isOn ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoItem(
                  label: 'Distância',
                  value: '${(device.totalDistance / 1000).toStringAsFixed(2)} km',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// BOTÃO
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon),
        ),
      ),
    );
  }
}
