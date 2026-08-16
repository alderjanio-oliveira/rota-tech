import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Rota rodoviária entre dois pontos via Mapbox Directions API — reaproveita
/// o mesmo MAP_BOX_TOKEN já usado pros tiles do mapa.
class DirectionsService {
  Future<List<LatLng>?> getRoute({required LatLng from, required LatLng to}) async {
    final token = dotenv.env['MAP_BOX_TOKEN'];

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?geometries=geojson&overview=full&access_token=$token',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) return null;

    final coordinates = routes.first['geometry']['coordinates'] as List;

    return coordinates.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
  }
}
