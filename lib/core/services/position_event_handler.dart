import 'package:app_tracking/core/services/notification_service.dart';
import 'package:app_tracking/data/device_model.dart';

class PositionEventHandler {
  final NotificationService notificationService;

  PositionEventHandler(this.notificationService);

  final Map<int, bool> _lastIgnition = {};
  final Map<int, bool> _lastPower = {};

  void handle(int deviceId, Map<String, dynamic> attributes, DeviceModel device) {
    _handleIgnition(deviceId, attributes, device);
    _handlePower(deviceId, attributes);
  }

  void _handleIgnition(int deviceId, Map<String, dynamic> attr, DeviceModel device) {
    final ignition = attr['ignition'];
    if (ignition == null) return;

    final last = _lastIgnition[deviceId];

    if (last != null && last != ignition) {
      notificationService.show(id: deviceId * 10, title: device.name, body: ignition ? 'Ignição ligada' : 'Ignição desligada');
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
