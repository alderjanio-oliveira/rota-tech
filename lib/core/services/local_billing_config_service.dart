import 'package:app_tracking/ui/model/billing_config_model.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class BillingConfigService extends GetxService {
  static const _key = 'billing_config';

  final _box = GetStorage();

  BillingConfig? loadBillingConfig() {
    final json = _box.read(_key);
    if (json == null) return null;
    return BillingConfig.fromJson(Map<String, dynamic>.from(json));
  }

  void saveBillingConfig(BillingConfig config) {
    _box.write(_key, config.toJson());
  }
}
