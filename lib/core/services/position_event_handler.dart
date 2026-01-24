import 'package:app_tracking/core/services/notification_service.dart';

class PositionEventHandler {
  final NotificationService notificationService;

  PositionEventHandler(this.notificationService);

  final Map<int, bool> _lastIgnition = {};
  final Map<int, bool> _lastPower = {};

  void handle(int deviceId, Map<String, dynamic> attributes) {
    _handleIgnition(deviceId, attributes);
    _handlePower(deviceId, attributes);
  }

  void _handleIgnition(int deviceId, Map<String, dynamic> attr) {
    final ignition = attr['ignition'];
    if (ignition == null) return;

    final last = _lastIgnition[deviceId];

    if (last != null && last != ignition) {
      notificationService.show(id: deviceId * 10, title: 'Ignição', body: ignition ? 'Ignição ligada' : 'Ignição desligada');
    }

    _lastIgnition[deviceId] = ignition;
  }

  void _handlePower(int deviceId, Map<String, dynamic> attr) {
    final power = attr['power'];
    if (power == null) return;

    final last = _lastPower[deviceId];

    if (last != null && last != power) {
      notificationService.show(id: deviceId * 10 + 1, title: 'Bateria', body: power ? 'Bateria reconectada' : '⚠️ Bateria desconectada');
    }

    _lastPower[deviceId] = power;
  }
}
