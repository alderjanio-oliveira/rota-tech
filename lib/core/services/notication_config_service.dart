import 'package:app_tracking/utils/constants.dart';
import 'package:get_storage/get_storage.dart';

class NoticationConfigService {
  final _box = GetStorage();

  Map<String, dynamic>? getNotificationConfig() {
    final res = _box.read(Constants.notificationKey);
    return res;
  }

  void saveNotificationConfig(config) {
    _box.write(Constants.notificationKey, config);
  }
}
