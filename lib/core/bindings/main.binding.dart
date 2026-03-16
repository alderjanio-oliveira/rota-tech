import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/api_helper.dart';
import 'package:app_tracking/core/services/auth_service.dart';
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
    Get.put(UserSessionService(), permanent: true);
    Get.put(ApiHelper(), permanent: true);
    Get.lazyPut(() => AuthService(session: Get.find<UserSessionService>(), apiHelper: Get.find<ApiHelper>()), fenix: true);

    Get.lazyPut<TraccarService>(() => TraccarService());
    Get.lazyPut(() => AuthController(traccarService: Get.find<TraccarService>(), authService: Get.find<AuthService>()), fenix: true);
  }
}
