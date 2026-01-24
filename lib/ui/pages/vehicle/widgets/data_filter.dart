import 'package:app_tracking/ui/controllers/vehicles/vehicles_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DateFilterCard extends StatelessWidget {
  final VehicleDetailsController controller;

  const DateFilterCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => TextButton(
                  onPressed: controller.pickStartDate,
                  child: Text(
                    controller.startDate.value == null
                        ? 'Data início'
                        : DateFormat(
                            'dd/MM/yyyy',
                          ).format(controller.startDate.value!),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => TextButton(
                  onPressed: controller.pickEndDate,
                  child: Text(
                    controller.endDate.value == null
                        ? 'Data fim'
                        : DateFormat(
                            'dd/MM/yyyy',
                          ).format(controller.endDate.value!),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: controller.searchKmByPeriod,
            ),
          ],
        ),
      ),
    );
  }
}
