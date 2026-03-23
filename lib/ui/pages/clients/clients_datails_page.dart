import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/ui/controllers/clients_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientsDatailsPage extends GetView<ClientsDetailsController> {
  const ClientsDatailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text('ClientsDatailsPage')),

      body: Column(
        children: [
          Text('Cliente: ${controller.client.name}'),
          Text('Vence em: ${controller.client.expiresAt}'),
          Text('Dias para vencer: ${controller.client.daysToExpire}'),
          Expanded(
            child: ListView.builder(
              itemCount: controller.vehicle.list.length,
              itemBuilder: (_, index) {
                final vehicle = controller.vehicle.list[index];
                return ListTile(
                  title: Text(vehicle.name),
                  subtitle: Text('Status: ${vehicle.status}'),
                  trailing: IconButton(
                    onPressed: () => controller.link(vehicle),
                    icon: Icon(Icons.link),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
