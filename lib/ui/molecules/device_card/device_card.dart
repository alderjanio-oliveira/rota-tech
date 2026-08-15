import 'package:app_tracking/ui/atoms/status_badge.dart';
import 'package:app_tracking/ui/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String deviceName;
  final String? address;
  final double totalDistance;
  final bool? ignitionStatus;
  final String? status;
  final bool loading;
  final VoidCallback onTap;
  final List<Widget>? actions;

  /// true = carregando (verde), false = desconectado (vermelho), null = sem info (cinza).
  final bool? charge;

  /// Mostra um sino enquanto o veículo estiver com a meta de km batida —
  /// some sozinho quando a trip for zerada/refeita.
  final bool reachedTarget;

  const DeviceCard({
    super.key,
    required this.deviceName,
    this.address,
    required this.totalDistance,
    this.ignitionStatus,
    this.status,
    required this.loading,
    required this.onTap,
    this.actions,
    this.charge,
    this.reachedTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = ignitionStatus == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🚗 ICON — fundo suave em vez de preenchimento sólido, visual
            /// mais leve e alinhado ao padrão de "chip" do StatusBadge.
            CircleAvatar(
              radius: 24,
              backgroundColor: (isOn ? AppColors.success : AppColors.gray).withOpacity(0.15),
              child: Icon(Icons.directions_car_rounded, color: isOn ? AppColors.success : AppColors.gray, size: 22),
            ),

            const SizedBox(width: 12),

            /// 📄 INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          deviceName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      if (reachedTarget) ...[
                        const StatusBadge(icon: Icons.notifications_active, color: AppColors.warning),
                        const SizedBox(width: 6),
                      ],
                      StatusBadge(
                        icon: Icons.battery_charging_full,
                        color: charge == null ? null : (charge! ? AppColors.success : AppColors.error),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    isOn ? "Ligado" : "Desligado",
                    style: TextStyle(color: isOn ? AppColors.success : AppColors.gray, fontSize: 12, fontWeight: FontWeight.w600),
                  ),

                  if (address != null) ...[
                    const SizedBox(height: 4),
                    Text(address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],

                  const SizedBox(height: 6),

                  Text("${(totalDistance / 1000).toStringAsFixed(1)} km", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            /// ⚡ ACTIONS
            Column(children: actions ?? []),
          ],
        ),
      ),
    );
  }
}
