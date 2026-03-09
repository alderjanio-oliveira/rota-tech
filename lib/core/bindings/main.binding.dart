import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/notification_state.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:get/get.dart';

class MainBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(VehicleState(), permanent: true);
    Get.put(NotificationState(), permanent: true);
    Get.lazyPut<UserSessionService>(() => UserSessionService(), fenix: true);
    Get.lazyPut<TraccarService>(() => TraccarService());
    Get.lazyPut(() => AuthController(Get.find<TraccarService>()));
  }
}
