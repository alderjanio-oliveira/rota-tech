import 'package:app_tracking/app/services/reverse_geocode_service.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/notification_service.dart';
import 'package:app_tracking/core/services/position_event_handler.dart';
import 'package:app_tracking/core/services/traccar_socket_service.dart';
import 'package:app_tracking/ui/controllers/home_controller.dart';
import 'package:get/get.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationService>(() => NotificationService());
    Get.lazyPut<TraccarWebSocketService>(() => TraccarWebSocketService());
    Get.lazyPut<PositionEventHandler>(() => PositionEventHandler(Get.find<NotificationService>()));
    Get.lazyPut<TraccarService>(() => TraccarService());
    Get.lazyPut<ReverseGeocodeService>(() => ReverseGeocodeService());
    Get.lazyPut<HomeController>(() => HomeController(traccarService: Get.find<TraccarService>(), geocodeService: Get.find<ReverseGeocodeService>()));
  }
}
