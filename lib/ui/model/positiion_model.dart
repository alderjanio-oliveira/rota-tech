class DevicePosition {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final bool ignition;
  final double totalDistance;
  final double heading; // direção do veículo (graus)

  const DevicePosition({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.ignition,
    required this.totalDistance,
    required this.heading,
  });

  DevicePosition copyWith({int? id, String? name, double? latitude, double? longitude, bool? ignition, double? totalDistance, double? heading}) {
    return DevicePosition(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ignition: ignition ?? this.ignition,
      totalDistance: totalDistance ?? this.totalDistance,
      heading: heading ?? this.heading,
    );
  }
}
