import 'package:latlong2/latlong.dart';

class MotionState {
  LatLng? lastRealPosition;
  LatLng? currentPosition;

  double speed = 0; // m/s
  double heading = 0;

  DateTime? lastUpdate;
}
