class NotificationConfigModel {
  bool isEnabled;
  bool ignitionAlert;
  bool lockAlert;
  bool chargeAlert;
  bool tripAlert;

  NotificationConfigModel({
    this.isEnabled = false,
    this.ignitionAlert = false,
    this.lockAlert = false,
    this.chargeAlert = false,
    this.tripAlert = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'ignitionAlert': ignitionAlert,
      'lockAlert': lockAlert,
      'chargeAlert': chargeAlert,
      'tripAlert': tripAlert,
    };
  }

  factory NotificationConfigModel.fromJson(Map<String, dynamic> json) {
    return NotificationConfigModel(
      isEnabled: json['isEnabled'] ?? false,
      ignitionAlert: json['ignitionAlert'] ?? false,
      lockAlert: json['lockAlert'] ?? false,
      chargeAlert: json['chargeAlert'] ?? false,
      tripAlert: json['tripAlert'] ?? false,
    );
  }
}
