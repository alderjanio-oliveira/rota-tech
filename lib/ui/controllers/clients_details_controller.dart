import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/core/services/api_helper.dart';
import 'package:app_tracking/core/utils/api.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:get/get.dart';

class ClientsDetailsController extends GetxController {
  VehicleState vehicle;
  ApiHelper apiHelper;
  ClientsDetailsController({
    required this.vehicle,
    required this.apiHelper,
  });
  ClientModel client = Get.arguments;

  void link(DeviceModel device) {
    Map<String, dynamic> attrs = {
      'userId': client.id,
      'deviceId': device.id,
    };
    apiHelper
        .postJson(attrs, Api().permissions)
        .then((response) {
          if (response.statusCode >= 200 && response.statusCode < 300) {
            Get.snackbar('Sucesso', 'Dispositivo vinculado ao cliente');
          } else {
            Get.snackbar('Erro', 'Falha ao vincular dispositivo');
          }
        })
        .catchError((error) {
          Get.snackbar('Erro', 'Falha ao vincular dispositivo');
        });
  }
}
