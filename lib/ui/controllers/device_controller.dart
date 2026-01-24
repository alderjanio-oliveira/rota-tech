// lib/ui/controllers/device_controller.dart
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:get/get.dart';

class DeviceController extends GetxController {
  final TraccarService traccarService;

  final RxList<dynamic> devices = <dynamic>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = RxString('');

  DeviceController(this.traccarService);

  @override
  void onInit() {
    super.onInit();
    loadDevices();
  }

  Future<void> loadDevices() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final devicesList = await traccarService.getDevices();
      devices.assignAll(devicesList);
    } catch (e) {
      errorMessage.value = 'Erro ao carregar dispositivos: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendCommand(int deviceId, String command) async {
    try {
      return await traccarService.sendCommand(deviceId, command);
    } catch (e) {
      errorMessage.value = 'Erro ao enviar comando: $e';
      return false;
    }
  }
}
