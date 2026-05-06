import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/ui/controllers/clients_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientsAdminPage extends StatelessWidget {
  const ClientsAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClientsAdminController(Get.find()));

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.clients.list.isEmpty) {
          return const Center(child: Text('Nenhum cliente encontrado'));
        }

        /// 🔥 FILTROS LOCAIS (simples e eficiente)
        final search = controller.search.value.toLowerCase();

        final filtered = controller.clients.list.where((c) {
          final matchSearch = c.name.toLowerCase().contains(search);

          if (controller.filter.value == 'todos') return matchSearch;

          if (controller.filter.value == 'vencidos') {
            return matchSearch && c.daysToExpire < 0;
          }

          if (controller.filter.value == 'ativos') {
            return matchSearch && c.daysToExpire >= 0;
          }

          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// 📊 KPIs
            _KpiHeader(clients: controller.clients.list),

            const SizedBox(height: 16),

            /// 🔍 BUSCA
            TextField(
              onChanged: (v) => controller.search.value = v,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// 🎯 FILTROS
            Row(
              children: [
                _FilterChip(label: 'Todos', value: 'todos'),
                _FilterChip(label: 'Ativos', value: 'ativos'),
                _FilterChip(label: 'Vencidos', value: 'vencidos'),
              ],
            ),

            const SizedBox(height: 16),

            /// 📄 LISTA
            ...filtered.map((client) {
              return _ClientCard(
                client: client,
                onTap: () => Get.toNamed(
                  Routes.CLIENTS_DETAILS,
                  arguments: client,
                ),
                onWhats: () => controller.sendWhatsAppReminder(client),
                onRenew: () => _confirmRenew(context, controller, client),
              );
            }),
          ],
        );
      }),
    );
  }

  /// 🔒 MODAL DE CONFIRMAÇÃO
  void _confirmRenew(BuildContext context, ClientsAdminController controller, dynamic client) {
    Get.dialog(
      AlertDialog(
        title: const Text("Confirmar renovação"),
        content: Text("Deseja renovar o contrato de ${client.name}?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.renewContract(client);
            },
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }
}

class _KpiHeader extends StatelessWidget {
  final List clients;

  const _KpiHeader({required this.clients});

  @override
  Widget build(BuildContext context) {
    final total = clients.length;
    final ativos = clients.where((c) => c.daysToExpire >= 0).length;
    final vencidos = clients.where((c) => c.daysToExpire < 0).length;

    return Row(
      children: [
        Expanded(child: _KpiBox("Total", total.toString(), Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _KpiBox("Ativos", ativos.toString(), Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _KpiBox("Vencidos", vencidos.toString(), Colors.red)),
      ],
    );
  }
}

class _KpiBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;

  const _FilterChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClientsAdminController>();

    return Obx(() {
      final selected = controller.filter.value == value;

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => controller.filter.value = value,
        ),
      );
    });
  }
}

class _ClientCard extends StatelessWidget {
  final dynamic client;
  final VoidCallback onTap;
  final VoidCallback onWhats;
  final VoidCallback onRenew;

  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onWhats,
    required this.onRenew,
  });

  Color _statusColor(int days) {
    if (days < 0) return Colors.red;
    if (days <= 5) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final days = client.daysToExpire;
    final color = _statusColor(days);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          children: [
            /// STATUS
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  days == 0 ? 'Hoje' : days.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 4),

                  Text(
                    client.expiresAt != null ? 'Vence em ${client.expiresAt.toLocal().toString().split(' ').first}' : 'Sem vencimento',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            /// AÇÕES
            Column(
              children: [
                IconButton(
                  onPressed: onWhats,
                  icon: const Icon(Icons.message),
                ),
                IconButton(
                  onPressed: onRenew,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
