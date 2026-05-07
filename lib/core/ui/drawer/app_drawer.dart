import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<UserSessionService>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _drawerItem(icon: Icons.motorcycle, title: 'Dispositivos', onTap: () => Get.offAllNamed(Routes.HOME)),
            Obx(() {
              if (!session.isAdmin.value) return const SizedBox.shrink();

              return _drawerItem(
                icon: Icons.people_alt_rounded,
                title: 'Clientes / Mensalidades',
                onTap: () => Get.toNamed(Routes.CLIENTS),
              );
            }),
            Obx(() {
              if (!session.isAdmin.value) return const SizedBox();

              return _drawerItem(
                icon: Icons.settings,
                title: 'Configurações',
                onTap: () => Get.toNamed(Routes.BILLING_CONFIG),
              );
            }),
            _drawerItem(icon: Icons.trip_origin, title: 'Kms rodados', onTap: () => Get.toNamed(Routes.TRIP_DETAILS)),
            _drawerItem(icon: Icons.notifications_outlined, title: 'Notificações', onTap: () => Get.toNamed(Routes.NOTIFICATIONS)),
            _drawerItem(icon: Icons.settings, title: 'Config. notificações', onTap: () => Get.toNamed(Routes.NOTIFICATION_CONFIG)),
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
    return const DrawerHeader(
      decoration: BoxDecoration(color: Colors.black87),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
