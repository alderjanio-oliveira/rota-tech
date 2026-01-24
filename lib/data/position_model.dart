class PositionModel {
  final int deviceId;
  final Map<String, dynamic> attributes;

  PositionModel({required this.deviceId, required this.attributes});

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(deviceId: json['deviceId'], attributes: json['attributes'] ?? {});
  }
}
