import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeviceCard extends StatelessWidget {
  final String deviceName;
  final String status;
  final VoidCallback? onTap;
  final bool? ignitionStatus;
  final double totalDistance;
  final String? address;
  final RxBool loading;

  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.status,
    this.onTap,
    required this.ignitionStatus,
    required this.totalDistance,
    this.address,
    required this.loading,
  });

  Color _statusColor(BuildContext context) {
    return status.toLowerCase() == 'online' ? const Color(0xFF22C55E) : Theme.of(context).colorScheme.error;
  }

  IconData _ignitionIcon() {
    return ignitionStatus == true ? Icons.flash_on_rounded : Icons.flash_off_rounded;
  }

  String _ignitionLabel() {
    return ignitionStatus == true ? 'Ligado' : 'Desligado';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(
      () => AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: loading.value ? 0.6 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading.value ? null : onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    /// STATUS DOT
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),

                    /// NAME
                    Expanded(
                      child: Text(
                        deviceName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    /// LOADING OU ARROW
                    loading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            color: theme.iconTheme.color?.withOpacity(0.6),
                          ),
                  ],
                ),

                const SizedBox(height: 6),

                /// ADDRESS
                Text(
                  address ?? 'Carregando endereço...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: 12),

                /// INFO ROW
                Row(
                  children: [
                    Icon(
                      _ignitionIcon(),
                      size: 18,
                      color: ignitionStatus == true ? theme.colorScheme.primary : theme.iconTheme.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),

                    Text(
                      _ignitionLabel(),
                      style: theme.textTheme.bodySmall,
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Text(
                      '${(totalDistance / 1000).toStringAsFixed(1)} km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
