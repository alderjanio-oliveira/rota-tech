import 'package:app_tracking/ui/controllers/notification/notificationConfig_controller.dart';
import 'package:get/get.dart';

class NotificationConfigBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationConfigController>(() => NotificationConfigController());
  }
}
