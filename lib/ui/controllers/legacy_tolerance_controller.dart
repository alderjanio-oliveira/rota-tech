// Feature TEMPORÁRIA: aplica a tolerância de bloqueio aos clientes que já
// existiam antes dela existir. Depois que todos os clientes ativos forem
// migrados, esta tela/controller/rota podem ser removidos.
import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/app/services/client_admin_service.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/local_billing_config_service.dart';
import 'package:get/get.dart';

class LegacyToleranceController extends GetxController {
  final TraccarService traccarService;
  final ClientAdminService clientAdminService;
  final BillingConfigService billingConfigService;

  LegacyToleranceController({
    required this.traccarService,
    required this.clientAdminService,
    required this.billingConfigService,
  });

  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<int> applyingIds = <int>{}.obs;
  final RxBool isApplyingAll = false.obs;

  int get toleranceDays => billingConfigService.loadBillingConfig()?.toleranceDays ?? 10;

  List<ClientModel> get pending => clients.where((c) => c.legacyToleranceAppliedAt == null).toList();

  @override
  void onInit() {
    super.onInit();
    loadClients();
  }

  Future<void> loadClients() async {
    try {
      isLoading.value = true;
      final data = await traccarService.getClients();
      clients.assignAll(data.map((e) => ClientModel.fromMap(e)).toList()..sort((a, b) => a.name.compareTo(b.name)));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> applyToOne(ClientModel client) async {
    if (client.legacyToleranceAppliedAt != null) return;

    try {
      applyingIds.add(client.id);
      final success = await clientAdminService.applyLegacyTolerance(client, toleranceDays);
      if (success) {
        final index = clients.indexWhere((c) => c.id == client.id);
        if (index != -1) {
          clients[index] = client.copyWith(legacyToleranceAppliedAt: DateTime.now());
        }
      } else {
        Get.snackbar('Erro', 'Não foi possível aplicar a tolerância para ${client.name}.');
      }
    } finally {
      applyingIds.remove(client.id);
    }
  }

  Future<void> applyToAllPending() async {
    final targets = pending;
    if (targets.isEmpty) return;

    try {
      isApplyingAll.value = true;
      for (final client in targets) {
        await applyToOne(client);
      }
      Get.snackbar('Concluído', 'Tolerância aplicada a ${targets.length} cliente(s).');
    } finally {
      isApplyingAll.value = false;
    }
  }
}
