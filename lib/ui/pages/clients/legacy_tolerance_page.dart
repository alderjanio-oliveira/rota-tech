// Feature TEMPORÁRIA: aplica a tolerância de bloqueio aos clientes que já
// existiam antes dela existir. Depois que todos os clientes ativos forem
// migrados, esta tela/controller/rota podem ser removidos.
import 'package:app_tracking/ui/controllers/legacy_tolerance_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LegacyTolerancePage extends GetView<LegacyToleranceController> {
  const LegacyTolerancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tolerância (temporário)')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.clients.isEmpty) {
          return const Center(child: Text('Nenhum cliente encontrado'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Aplica +${controller.toleranceDays} dias no bloqueio real de cada cliente (o vencimento pra cobrança não muda). '
              'Depois que todos forem migrados, esta tela pode ser removida.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.pending.isEmpty || controller.isApplyingAll.value ? null : controller.applyToAllPending,
                icon: controller.isApplyingAll.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.playlist_add_check),
                label: Text('Aplicar a todos pendentes (${controller.pending.length})'),
              ),
            ),
            const SizedBox(height: 16),
            ...controller.clients.map((client) => _LegacyToleranceItem(client: client, controller: controller)),
          ],
        );
      }),
    );
  }
}

class _LegacyToleranceItem extends StatelessWidget {
  final dynamic client;
  final LegacyToleranceController controller;

  const _LegacyToleranceItem({required this.client, required this.controller});

  @override
  Widget build(BuildContext context) {
    final appliedAt = client.legacyToleranceAppliedAt;
    final applied = appliedAt != null;

    return Obx(() {
      final isApplying = controller.applyingIds.contains(client.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Theme.of(context).cardColor),
        child: Row(
          children: [
            Icon(
              applied ? Icons.check_circle : Icons.schedule,
              color: applied ? Colors.green : Colors.orange,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    applied ? 'Aplicado em ${_formatDate(appliedAt)}' : 'Pendente',
                    style: TextStyle(fontSize: 12, color: applied ? Colors.green : Colors.orange),
                  ),
                ],
              ),
            ),
            if (!applied)
              isApplying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: () => controller.applyToOne(client),
                      child: const Text('Aplicar'),
                    ),
          ],
        ),
      );
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
