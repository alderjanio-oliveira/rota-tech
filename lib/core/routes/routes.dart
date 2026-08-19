import 'package:app_tracking/core/bindings/auth_bindings.dart';
import 'package:app_tracking/core/bindings/billing_config_binding.dart';
import 'package:app_tracking/core/bindings/clients/client_create.dart';
import 'package:app_tracking/core/bindings/clients/clients_details.dart';
import 'package:app_tracking/core/bindings/clients/legacy_tolerance.dart';
import 'package:app_tracking/core/bindings/device_create_binding.dart';
import 'package:app_tracking/core/bindings/home_binding.dart';
import 'package:app_tracking/core/bindings/map_bindings.dart';
import 'package:app_tracking/core/bindings/notification_bindings.dart';
import 'package:app_tracking/core/bindings/vehicle/vehicle_details_bindings.dart';
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/ui/pages/billing/billing_config_page.dart';
import 'package:app_tracking/ui/pages/clients/client_create_page.dart';
import 'package:app_tracking/ui/pages/clients/clients_datails_page.dart';
import 'package:app_tracking/ui/pages/clients/clients_page.dart';
import 'package:app_tracking/ui/pages/clients/legacy_tolerance_page.dart';
import 'package:app_tracking/ui/pages/devices/device_create_page.dart';
import 'package:app_tracking/ui/pages/home/home_page.dart';
import 'package:app_tracking/ui/pages/infos/trip_details_page.dart';
import 'package:app_tracking/ui/pages/login/login_page.dart';
import 'package:app_tracking/ui/pages/map/client_map_page.dart';
import 'package:app_tracking/ui/pages/notification/notifications_page.dart';
import 'package:app_tracking/ui/pages/notification/notificatio_config.dart';
import 'package:app_tracking/ui/pages/vehicle/vehicle_details_page.dart';
import 'package:get/get.dart';

List<GetPage<dynamic>> mainRouters = <GetPage<dynamic>>[
  GetPage(name: Routes.LOGIN, page: () => LoginPage(), binding: AuthBindings()),
  GetPage(name: Routes.HOME, page: () => HomePage(), binding: HomeBinding()),
  GetPage(name: Routes.MAP, page: () => const ClientMapPage(), binding: MapBinding()),
  GetPage(
    name: Routes.VEHICLE_DETAILS,
    page: () => VehicleDetailsPage(device: Get.arguments ?? ''),
    binding: VehicleDetailsBindings(),
  ),
  GetPage(name: Routes.CLIENTS, page: () => const ClientsAdminPage()),
  GetPage(name: Routes.BILLING_CONFIG, page: () => const BillingConfigPage(), binding: BillingConfigBinding()),
  GetPage(name: Routes.TRIP_DETAILS, page: () => TripDetailsPage()),
  GetPage(name: Routes.NOTIFICATIONS, page: () => const NotificationsPage()),
  GetPage(name: Routes.NOTIFICATION_CONFIG, page: () => NotificationConfigPage(), binding: NotificationConfigBindings()),
  GetPage(name: Routes.CLIENTS_DETAILS, page: () => const ClientsDatailsPage(), binding: ClientsDetailsBinding()),
  GetPage(name: Routes.LEGACY_TOLERANCE, page: () => const LegacyTolerancePage(), binding: LegacyToleranceBinding()),
  GetPage(name: Routes.CLIENTS_CREATE, page: () => const ClientCreatePage(), binding: ClientCreateBinding()),
  GetPage(name: Routes.DEVICE_CREATE, page: () => const DeviceCreatePage(), binding: DeviceCreateBinding()),
];
