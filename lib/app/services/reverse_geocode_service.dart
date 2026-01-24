import 'dart:convert';
import 'package:http/http.dart' as http;

class ReverseGeocodeService {
  Future<String?> getAddress(double lat, double lon) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json",
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'MyFlutterApp/1.0', // obrigatório para Nominatim
      },
    );

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);

    return simplifyAddress(data["display_name"]);
  }

  String simplifyAddress(String fullAddress) {
    final parts = fullAddress.split(',').map((e) => e.trim()).toList();

    // Queremos apenas 3 níveis:
    // Rua, Bairro, Cidade
    if (parts.length >= 3) {
      return "${parts[0]}, ${parts[1]}, ${parts[2]}";
    }

    // Se vier incompleto, retorna tudo mesmo
    return fullAddress;
  }
}
