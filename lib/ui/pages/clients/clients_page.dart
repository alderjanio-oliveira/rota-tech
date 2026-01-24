// lib/features/clients/ui/clients_admin_page.dart
import 'package:app_tracking/ui/controllers/clients_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientsAdminPage extends StatelessWidget {
  const ClientsAdminPage({super.key});

  Color _statusColor(int days) {
    if (days <= 0) return Colors.red;
    if (days <= 5) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClientsAdminController(Get.find()));

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes & Mensalidades')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }

        if (controller.clients.isEmpty) {
          return const Center(child: Text('Nenhum cliente encontrado'));
        }

        return ListView.builder(
          itemCount: controller.clients.length,
          itemBuilder: (_, index) {
            final client = controller.clients[index];
            final days = client.daysToExpire;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: _statusColor(days), child: Text(days.toString())),
                title: Text(client.name),
                subtitle: Text(
                  client.expiresAt != null ? 'Vence em: ${client.expiresAt!.toLocal().toString().split(' ').first}' : 'Sem data de vencimento',
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(onPressed: () => controller.sendWhatsAppReminder(client), icon: Icon(Icons.message)),
                    IconButton(icon: const Icon(Icons.refresh), onPressed: () => controller.renewContract(client)),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
