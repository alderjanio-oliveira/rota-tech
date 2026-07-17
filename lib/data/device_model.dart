import 'package:get/get.dart';

class DeviceModel {
  final int id;
  final String name;
  final String status;
  final DeviceAttributes attributes;
  final int? lastPositionId;
  final RxBool loading = false.obs;

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
    this.positionLoaded = false,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      attributes: DeviceAttributes.fromJson(json['attributes'] ?? {}),
      lastPositionId: json['lastPositionId'],
    );
  }

  DeviceModel copyWith({DeviceAttributes? attributes, int? lastPositionId, bool? positionLoaded}) {
    return DeviceModel(
      id: id,
      name: name,
      status: status,
      attributes: attributes ?? this.attributes,
      lastPositionId: lastPositionId ?? this.lastPositionId,
      positionLoaded: positionLoaded ?? this.positionLoaded,
    );
  }

  /// 🚗 Odometro em KM
  double? get odometerKm {
    if (attributes.totalDistance == null) return null;
    return attributes.totalDistance! / 1000;
  }

  /// 🅰️ Trip atual baseado no offset
  double? get tripKm {
    if (attributes.trip == null || attributes.totalDistance == null) return null;

    return (attributes.totalDistance! - attributes.trip!.offset) / 1000;
  }

  /// 🎯 Verifica se atingiu meta
  bool get tripReachedTarget {
    final km = tripKm;
    final target = attributes.trip?.target;

    if (km == null || target == null) return false;

    return km >= (target - (target * 0.05)); // Considera atingido se estiver dentro de 5% da meta
  }
}

class DeviceAttributes {
  final bool? ignition;
  RxnBool lockState;
  final bool? charge;
  final double? totalDistance;
  final String? address;
  final Trip? trip;

  DeviceAttributes({required this.ignition, required this.lockState, this.charge, this.totalDistance, this.address, this.trip});

  factory DeviceAttributes.fromJson(Map<String, dynamic> json) {
    return DeviceAttributes(
      ignition: json['ignition'] ?? false,
      lockState: RxnBool(json['lockState']),
      charge: json['charge'],
      totalDistance: json['totalDistance']?.toDouble(),
      address: json['address'],
      trip: _parseTrip(json['trip']),
    );
  }

  /// O servidor às vezes retorna `trip` como um único objeto e às vezes como
  /// uma lista de trips (histórico de resets); nesse caso usamos o ativo.
  static Trip? _parseTrip(dynamic raw) {
    if (raw is Map<String, dynamic>) return Trip.fromJson(raw);
    if (raw is List) {
      final trips = raw.whereType<Map<String, dynamic>>();
      if (trips.isEmpty) return null;
      final active = trips.firstWhere((t) => t['active'] == true, orElse: () => trips.first);
      return Trip.fromJson(active);
    }
    return null;
  }

  DeviceAttributes copyWith({bool? ignition, RxnBool? lockState, bool? charge, double? totalDistance, String? address, Trip? trip}) {
    return DeviceAttributes(
      ignition: ignition ?? this.ignition,
      lockState: lockState ?? this.lockState,
      charge: charge ?? this.charge,
      totalDistance: totalDistance ?? this.totalDistance,
      address: address ?? this.address,
      trip: trip ?? this.trip,
    );
  }
}

class Trip {
  final String name;
  final double offset;
  final double? target;
  final bool active;

  Trip({required this.name, required this.offset, this.target, this.active = true});

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      name: json['name'],
      offset: json['offset']?.toDouble() ?? 0.0,
      target: json['target']?.toDouble() ?? 0.0,
      active: json['active'] ?? true,
    );
  }

  Trip copyWith({String? name, double? offset, double? target, bool? active}) {
    return Trip(name: name ?? this.name, offset: offset ?? this.offset, target: target ?? this.target, active: active ?? this.active);
  }
}
