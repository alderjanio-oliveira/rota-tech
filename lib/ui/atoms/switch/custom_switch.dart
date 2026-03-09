import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabelSwitchTile extends StatelessWidget {
  final String label;
  final RxBool value;
  final ValueChanged<bool>? onChanged;

  const LabelSwitchTile({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SwitchListTile(
        title: Text(label),
        value: value.value,
        onChanged: (v) {
          value.value = v;
          if (onChanged != null) onChanged!(v);
        },
      ),
    );
  }
}
