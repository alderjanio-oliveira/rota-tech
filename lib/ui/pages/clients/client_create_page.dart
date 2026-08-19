import 'package:app_tracking/ui/controllers/client_create_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientCreatePage extends GetView<ClientCreateController> {
  const ClientCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar cliente')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.alternate_email)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha de acesso', prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => controller.pickContractStart(context),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Cliente desde', prefixIcon: Icon(Icons.event_available_outlined)),
                child: Text(controller.formatDate(controller.contractStart.value)),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => controller.pickExpiresAt(context),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Primeiro vencimento', prefixIcon: Icon(Icons.event_outlined)),
                child: Text(controller.formatDate(controller.expiresAt.value)),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calculado como "cliente desde" + 1 mês — pode ajustar se precisar.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isSaving.value ? null : controller.save,
                icon: controller.isSaving.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Cadastrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
