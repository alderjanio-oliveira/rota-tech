import 'package:app_tracking/app/services/traccar_service.dart';

class UserService {
  final TraccarService traccar;
  int? _userId; // cache

  UserService(this.traccar);

  // Ajuste de acordo com sua autenticação
  Future<int?> getUserId() async {
    if (_userId != null) return _userId;
    // implementar login e pegar userId via /api/session (ou receber do backend)
    return _userId;
  }

  // Future<List<dynamic>> getDevicesForCurrentUser() async {
  //   final id = await getUserId();
  //   if (id == null) return [];
  //   return traccar.getUserDevices(id);
  // }
}
