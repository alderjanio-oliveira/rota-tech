// lib/features/clients/controller/clients_admin_controller.dart
import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/remainder_messenger_service.dart';
import 'package:app_tracking/data/client_state.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientsAdminController extends GetxController {
  final TraccarService traccarService;
  final messageServiceWhatsApp = ReminderMessageService();
  final ClientState clients = Get.find<ClientState>();
  final vehicleState = Get.find<VehicleState>();

  ClientsAdminController(this.traccarService);

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString search = ''.obs;
  final RxString filter = 'todos'.obs;

  @override
  void onInit() {
    super.onInit();
    loadClients();
  }

  Future<void> loadClients() async {
    try {
      isLoading.value = true;
      error.value = '';
      final data = await traccarService.getClients();
      clients.list.assignAll(data.map((e) => ClientModel.fromMap(e)).toList()..sort((a, b) => a.daysToExpire.compareTo(b.daysToExpire)));
      loadDevicesPerUser();
    } catch (e) {
      error.value = 'Erro ao carregar clientes';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDevicesPerUser() async {
    try {
      isLoading.value = true;
      error.value = '';
      final List<Map<String, dynamic>> data = await traccarService.getDevicesPerUser();

      final clientMap = {for (var c in clients.list) c.id: c};
      final deviceMap = {for (var d in vehicleState.list) d.id: d};
      for (var item in data) {
        final client = clientMap[item['userId']];
        final device = deviceMap[item['deviceId']];

        if (client != null && device != null) {
          client.devices ??= [];
          client.devices!.add(device);
        }
      }
      print(clients.list);

      // Processar os dados conforme necessário
    } catch (e) {
      error.value = 'Erro ao carregar dispositivos por usuário';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> renewContract(ClientModel client) async {
    if (client.expiresAt == null) return;

    final success = await traccarService.renewClientContract(client);

    if (success) {
      loadClients();
      String message = messageServiceWhatsApp.buildCongratulationMessage(client);
      sendMessage(client, message);
    }
  }

  Future<void> sendWhatsAppReminder(ClientModel client) async {
    final days = client.daysToExpire;
    late String message;

    if (days > 0) {
      message = messageServiceWhatsApp.buildMessage(client, ReminderType.before);
    } else if (days == 0) {
      message = messageServiceWhatsApp.buildMessage(client, ReminderType.dueToday);
    } else {
      message = messageServiceWhatsApp.buildMessage(client, ReminderType.overdue);
    }
    sendMessage(client, message);
  }

  sendMessage(ClientModel client, String message) async {
    final phoneClient = client.phone ?? '92991200872';

    final phone = phoneClient.replaceAll(RegExp(r'\D'), '');
    final encoded = Uri.encodeComponent(message);

    final uri = Uri.parse('https://wa.me/55$phone?text=$encoded');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Erro', 'Não foi possível abrir o WhatsApp');
    } else {
      // markClientAsNotified(client);
    }
  }
}
