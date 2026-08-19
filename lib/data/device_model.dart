import 'package:get/get.dart';

class DeviceModel {
  final int id;
  final String name;
  final String status;
  final DeviceAttributes attributes;
  final int? lastPositionId;
  final RxBool loading = false.obs;

  /// IMEI (identificador que o rastreador usa pra se conectar no Traccar).
  final String? uniqueId;

  /// Número do chip/SIM instalado no rastreador — usado pra mandar os
  /// comandos de configuração por SMS.
  final String? phone;

  /// Indica se já sabemos a posição/última leitura do device (usado para
  /// trocar o skeleton pelo card real na listagem), independente do device
  /// ter ou não uma posição de fato disponível no servidor.
  final bool positionLoaded;

  DeviceModel({
    required this.id,
    required this.name,
    required this.status,
    required this.attributes,
    this.lastPositionId,
    this.uniqueId,
    this.phone,
    this.positionLoaded = false,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      attributes: DeviceAttributes.fromJson(json['attributes'] ?? {}),
      lastPositionId: json['lastPositionId'],
      uniqueId: json['uniqueId'],
      phone: json['phone'],
    );
  }

  DeviceModel copyWith({DeviceAttributes? attributes, int? lastPositionId, bool? positionLoaded}) {
    return DeviceModel(
      id: id,
      name: name,
      status: status,
      attributes: attributes ?? this.attributes,
      lastPositionId: lastPositionId ?? this.lastPositionId,
      uniqueId: uniqueId,
      phone: phone,
      positionLoaded: positionLoaded ?? this.positionLoaded,
    );
  }

  /// 🚗 Odometro em KM
  double? get odometerKm {
    if (attributes.totalDistance == null) return null;
    return attributes.totalDistance! / 1000;
  }
}

class DeviceAttributes {
  final bool? ignition;
  RxnBool lockState;
  final bool? charge;
  final double? totalDistance;
  final String? address;

  DeviceAttributes({required this.ignition, required this.lockState, this.charge, this.totalDistance, this.address});

  factory DeviceAttributes.fromJson(Map<String, dynamic> json) {
    return DeviceAttributes(
      ignition: json['ignition'] ?? false,
      lockState: RxnBool(json['lockState']),
      charge: json['charge'],
      totalDistance: json['totalDistance']?.toDouble(),
      address: json['address'],
    );
  }

  DeviceAttributes copyWith({bool? ignition, RxnBool? lockState, bool? charge, double? totalDistance, String? address}) {
    return DeviceAttributes(
      ignition: ignition ?? this.ignition,
      lockState: lockState ?? this.lockState,
      charge: charge ?? this.charge,
      totalDistance: totalDistance ?? this.totalDistance,
      address: address ?? this.address,
    );
  }
}
