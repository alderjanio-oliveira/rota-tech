import 'package:flutter/material.dart';

/// Placeholder do [DeviceCard] enquanto posição/endereço ainda não chegaram.
class DeviceCardSkeleton extends StatefulWidget {
  const DeviceCardSkeleton({super.key});

  @override
  State<DeviceCardSkeleton> createState() => _DeviceCardSkeletonState();
}

class _DeviceCardSkeletonState extends State<DeviceCardSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final base = Theme.of(context).colorScheme.onSurface.withOpacity(0.06 + _controller.value * 0.06);

        Widget bar(double width, double height) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4)),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: base),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(120, 14),
                    const SizedBox(height: 8),
                    bar(70, 10),
                    const SizedBox(height: 8),
                    bar(160, 10),
                    const SizedBox(height: 8),
                    bar(60, 12),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              bar(20, 20),
            ],
          ),
        );
      },
    );
  }
}
