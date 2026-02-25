import 'dart:math';
import 'package:latlong2/latlong.dart';

class GeoUtils {
  static const double _earthRadius = 6371000; // metros

  static double distanceInMeters(LatLng start, LatLng end) {
    final Distance distance = const Distance();
    return distance.as(LengthUnit.Meter, start, end);
  }

  static LatLng projectPosition({required LatLng start, required double distanceMeters, required double headingDegrees}) {
    final double headingRad = headingDegrees * pi / 180;

    final double lat1 = start.latitude * pi / 180;
    final double lon1 = start.longitude * pi / 180;

    final double lat2 = asin(sin(lat1) * cos(distanceMeters / _earthRadius) + cos(lat1) * sin(distanceMeters / _earthRadius) * cos(headingRad));

    final double lon2 =
        lon1 + atan2(sin(headingRad) * sin(distanceMeters / _earthRadius) * cos(lat1), cos(distanceMeters / _earthRadius) - sin(lat1) * sin(lat2));

    return LatLng(lat2 * 180 / pi, lon2 * 180 / pi);
  }
}
