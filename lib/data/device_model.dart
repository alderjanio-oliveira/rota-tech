class DeviceModel {
  final int id;
  final String name;
  final String status;
  final DeviceAttributes attributes;
  final int? lastPositionId;

  DeviceModel({required this.id, required this.name, required this.status, required this.attributes, this.lastPositionId});

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      attributes: DeviceAttributes.fromJson(json['attributes'] ?? {}),
      lastPositionId: json['lastPositionId'],
    );
  }

  DeviceModel copyWith({DeviceAttributes? attributes, int? lastPositionId}) {
    return DeviceModel(
      id: id,
      name: name,
      status: status,
      attributes: attributes ?? this.attributes,
      lastPositionId: lastPositionId ?? this.lastPositionId,
    );
  }
}

class DeviceAttributes {
  final bool? ignition;
  final bool? lockState;
  final bool? charge;
  final double? totalDistance;
  final String? address;

  DeviceAttributes({required this.ignition, this.lockState, this.charge, this.totalDistance, this.address});

  factory DeviceAttributes.fromJson(Map<String, dynamic> json) {
    return DeviceAttributes(
      ignition: json['ignition'] ?? false,
      lockState: json['lockState'],
      charge: json['charge'],
      totalDistance: json['totalDistance']?.toDouble(),
      address: json['address'],
    );
  }

  DeviceAttributes copyWith({bool? ignition, bool? lockState, bool? charge, double? totalDistance, String? address}) {
    return DeviceAttributes(
      ignition: ignition ?? this.ignition,
      lockState: lockState ?? this.lockState,
      charge: charge ?? this.charge,
      totalDistance: totalDistance ?? this.totalDistance,
      address: address ?? this.address,
    );
  }
}
