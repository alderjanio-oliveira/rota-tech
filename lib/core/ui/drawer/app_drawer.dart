import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_tracking/core/services/user_session_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = UserSessionService.to;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _drawerItem(icon: Icons.motorcycle, title: 'Dispositivos', onTap: () => Get.offAllNamed(Routes.HOME)),

            // 🔒 SOMENTE ADMIN
            Obx(() {
              if (!session.isAdmin.value) return const SizedBox.shrink();

              return _drawerItem(
                icon: Icons.people_alt_rounded,
                title: 'Clientes / Mensalidades',
                onTap: () => Get.toNamed(Routes.CLIENTS),
              );
            }),

            Obx(() {
              if (!UserSessionService.to.isAdmin.value) return const SizedBox();

              return ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'),
                onTap: () => Get.toNamed(Routes.BILLING_CONFIG),
              );
            }),

            const Spacer(),

            _drawerItem(
              icon: Icons.logout,
              title: 'Sair',
              onTap: () {
                // logout
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.black87),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.admin_panel_settings, color: Colors.white, size: 36),
          SizedBox(height: 12),
          Text('Painel Administrativo', style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
