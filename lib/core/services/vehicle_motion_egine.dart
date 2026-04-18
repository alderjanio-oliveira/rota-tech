import 'dart:async';
import 'package:app_tracking/core/config/motion_config.dart';
import 'package:app_tracking/ui/model/motion_state.dart';
import 'package:app_tracking/utils/geo_utils.dart';
import 'package:latlong2/latlong.dart';

class VehicleMotionEngine {
  final _controller = StreamController<LatLng>.broadcast();
  Stream<LatLng> get stream => _controller.stream;

  final MotionState _state = MotionState();

  Timer? _timer;

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  void updateRealPosition({required LatLng newPosition, required double heading, double? speedKmh}) {
    final now = DateTime.now();

    if (_state.lastRealPosition != null && speedKmh == null) {
      final distance = GeoUtils.distanceInMeters(_state.lastRealPosition!, newPosition);

      final seconds = now.difference(_state.lastUpdate!).inSeconds;

      if (seconds > 0) {
        _state.speed = distance / seconds;
      }
    } else if (speedKmh != null) {
      _state.speed = speedKmh / 3.6;
    }

    _state.heading = heading;
    _state.lastRealPosition = newPosition;
    _state.currentPosition = newPosition;
    _state.lastUpdate = now;

    _startPrediction();
  }

  void _startPrediction() {
    _timer?.cancel();

    final interval = Duration(milliseconds: (1000 / MotionConfig.fps).round());

    _timer = Timer.periodic(interval, (_) {
      if (_state.currentPosition == null) return;

      final distancePerFrame = _state.speed / MotionConfig.fps;

      final projected = GeoUtils.projectPosition(
        start: _state.currentPosition!,
        distanceMeters: distancePerFrame,
        headingDegrees: _state.heading,
      );

      _state.currentPosition = projected;

      _controller.add(projected);
    });
  }
}
