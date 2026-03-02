import 'package:app_tracking/core/bindings/auth_bindings.dart';
import 'package:app_tracking/core/bindings/billing_config_binding.dart';
import 'package:app_tracking/core/bindings/home_binding.dart';
import 'package:app_tracking/core/bindings/map_bindings.dart';
import 'package:app_tracking/core/bindings/vehicle/vehicle_details_bindings.dart';
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/ui/pages/billing/billing_config_page.dart';
import 'package:app_tracking/ui/pages/clients/clients_page.dart';
import 'package:app_tracking/ui/pages/home/home_page.dart';
import 'package:app_tracking/ui/pages/infos/trip_details_page.dart';
import 'package:app_tracking/ui/pages/login/login_page.dart';
import 'package:app_tracking/ui/pages/map/map_page.dart';
import 'package:app_tracking/ui/pages/vehicle/vehicle_details_page.dart';
import 'package:get/get.dart';

List<GetPage<dynamic>> mainRouters = <GetPage<dynamic>>[
  GetPage(name: Routes.LOGIN, page: () => LoginPage(), binding: AuthBindings()),
  GetPage(name: Routes.HOME, page: () => HomePage(), binding: HomeBinding()),
  GetPage(name: Routes.MAP, page: () => MapWidget(), binding: MapBinding()),
  GetPage(
    name: Routes.VEHICLE_DETAILS,
    page: () => VehicleDetailsPage(device: Get.arguments ?? ''),
    binding: VehicleDetailsBindings(),
  ),
  GetPage(name: Routes.CLIENTS, page: () => const ClientsAdminPage()),
  GetPage(name: Routes.BILLING_CONFIG, page: () => const BillingConfigPage(), binding: BillingConfigBinding()),
  GetPage(name: Routes.TRIP_DETAILS, page: () => TripDetailsPage()),
];
