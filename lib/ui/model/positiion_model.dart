class DevicePosition {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final bool ignition;
  final double totalDistance;

  DevicePosition({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.ignition,
    required this.totalDistance,
  });
}
